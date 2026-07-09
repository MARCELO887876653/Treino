import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase('treino_progressao.db');
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, fileName);
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        category_id INTEGER,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY(workout_id) REFERENCES workouts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        set_order INTEGER NOT NULL,
        FOREIGN KEY(exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');

    await db.insert('categories', {'name': 'Geral'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      await db.insert('categories', {'name': 'Geral'}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.execute('ALTER TABLE workouts ADD COLUMN notes TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE workouts ADD COLUMN category_id INTEGER');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercises(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          FOREIGN KEY(workout_id) REFERENCES workouts(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_id INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          weight REAL NOT NULL,
          set_order INTEGER NOT NULL,
          FOREIGN KEY(exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
        )
      ''');
      await db.update('workouts', {'category_id': 1}, where: 'category_id IS NULL');
    }
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((row) => Category.fromMap(row)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    if (category.id == null) return insertCategory(category);
    return db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int categoryId) async {
    final db = await database;
    await db.update('workouts', {'category_id': null}, where: 'category_id = ?', whereArgs: [categoryId]);
    return db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  Future<int> insertWorkout(Workout workout) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final workoutId = await txn.insert('workouts', workout.toMap());
      for (final exercise in workout.exercises) {
        final exerciseId = await txn.insert('exercises', {
          'workout_id': workoutId,
          'name': exercise.name,
        });
        for (final set in exercise.sets) {
          await txn.insert('sets', {
            'exercise_id': exerciseId,
            'reps': set.reps,
            'weight': set.weight,
            'set_order': set.order,
          });
        }
      }
      return workoutId;
    });
  }

  Future<int> updateWorkout(Workout workout) async {
    final db = await database;
    if (workout.id == null) return insertWorkout(workout);
    return db.transaction<int>((txn) async {
      await txn.update(
        'workouts',
        workout.toMap(),
        where: 'id = ?',
        whereArgs: [workout.id],
      );
      await txn.delete('sets', where: 'exercise_id IN (SELECT id FROM exercises WHERE workout_id = ?)', whereArgs: [workout.id]);
      await txn.delete('exercises', where: 'workout_id = ?', whereArgs: [workout.id]);
      for (final exercise in workout.exercises) {
        final exerciseId = await txn.insert('exercises', {
          'workout_id': workout.id,
          'name': exercise.name,
        });
        for (final set in exercise.sets) {
          await txn.insert('sets', {
            'exercise_id': exerciseId,
            'reps': set.reps,
            'weight': set.weight,
            'set_order': set.order,
          });
        }
      }
      return workout.id!;
    });
  }

  Future<int> deleteWorkout(int workoutId) async {
    final db = await database;
    return db.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
  }

  Future<Workout?> getWorkoutById(int id) async {
    final db = await database;
    final workoutRows = await db.query('workouts', where: 'id = ?', whereArgs: [id]);
    if (workoutRows.isEmpty) return null;
    final exercises = await getExercisesByWorkout(id);
    return Workout.fromMap(workoutRows.first, exercises: exercises);
  }

  Future<List<Workout>> getWorkouts({int? categoryId}) async {
    final db = await database;
    final workoutRows = await db.query(
      'workouts',
      where: categoryId == null ? null : 'category_id = ?',
      whereArgs: categoryId == null ? null : [categoryId],
      orderBy: 'date DESC',
    );

    final workouts = <Workout>[];
    for (final row in workoutRows) {
      final exercises = await getExercisesByWorkout(row['id'] as int);
      workouts.add(Workout.fromMap(row, exercises: exercises));
    }
    return workouts;
  }

  Future<List<Workout>> getWorkoutsByCategory(int categoryId) async {
    return getWorkouts(categoryId: categoryId);
  }

  Future<List<Exercise>> getExercisesByWorkout(int workoutId) async {
    final db = await database;
    final exerciseRows = await db.query(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );

    final exercises = <Exercise>[];
    for (final row in exerciseRows) {
      final sets = await getSetsByExercise(row['id'] as int);
      exercises.add(Exercise.fromMap(row, sets: sets));
    }
    return exercises;
  }

  Future<List<WorkoutSet>> getSetsByExercise(int exerciseId) async {
    final db = await database;
    final setRows = await db.query(
      'sets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'set_order ASC',
    );
    return setRows.map((row) => WorkoutSet.fromMap(row)).toList();
  }

  Future<List<String>> getDistinctExerciseNames() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT DISTINCT name FROM exercises ORDER BY name ASC');
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getProgressionForExercise(String name) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        w.date AS date,
        MAX(s.weight) AS max_weight,
        w.name AS workout_name
      FROM workouts w
      JOIN exercises e ON e.workout_id = w.id
      JOIN sets s ON s.exercise_id = e.id
      WHERE e.name = ?
      GROUP BY w.id
      ORDER BY w.date ASC
    ''', [name]);

    return rows.map((row) {
      return {
        'date': row['date'] as String,
        'weight': (row['max_weight'] as num).toDouble(),
        'workout_name': row['workout_name'] as String,
      };
    }).toList();
  }

  Future<double?> getMaxWeightForExercise(String name) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT MAX(s.weight) AS max_weight
      FROM exercises e
      JOIN sets s ON s.exercise_id = e.id
      WHERE e.name = ?
    ''', [name]);
    if (rows.isEmpty) return null;
    final value = rows.first['max_weight'];
    if (value == null) return null;
    return (value as num).toDouble();
  }

  Future<String> exportBackupJson() async {
    final categories = await getCategories();
    final workouts = await getWorkouts();
    final payload = {
      'version': 2,
      'categories': categories.map((category) => category.toMap()).toList(),
      'workouts': workouts.map((workout) => workout.toJson()).toList(),
    };
    return jsonEncode(payload);
  }

  Future<void> restoreFromBackup(String jsonString) async {
    final payload = jsonDecode(jsonString) as Map<String, dynamic>;
    final categories = (payload['categories'] as List<dynamic>?)
            ?.map((value) => Category.fromMap(value as Map<String, dynamic>))
            .toList() ??
        <Category>[];
    final workouts = (payload['workouts'] as List<dynamic>?)
            ?.map((value) => Workout.fromJson(value as Map<String, dynamic>))
            .toList() ??
        <Workout>[];

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sets');
      await txn.delete('exercises');
      await txn.delete('workouts');
      await txn.delete('categories');

      for (final category in categories) {
        await txn.insert('categories', category.toMap());
      }
      if (categories.isEmpty) {
        await txn.insert('categories', {'name': 'Geral'});
      }

      for (final workout in workouts) {
        final workoutId = await txn.insert('workouts', {
          'name': workout.name,
          'date': workout.date.toIso8601String(),
          'notes': workout.notes,
          'category_id': workout.categoryId,
        });

        for (final exercise in workout.exercises) {
          final exerciseId = await txn.insert('exercises', {
            'workout_id': workoutId,
            'name': exercise.name,
          });
          for (final set in exercise.sets) {
            await txn.insert('sets', {
              'exercise_id': exerciseId,
              'reps': set.reps,
              'weight': set.weight,
              'set_order': set.order,
            });
          }
        }
      }
    });
  }

  Future<File> createBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(join(directory.path, 'treino_backup.json'));
    final jsonString = await exportBackupJson();
    await file.writeAsString(jsonString);
    return file;
  }
}
