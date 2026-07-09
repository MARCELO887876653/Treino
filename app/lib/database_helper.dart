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
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL
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
  }

  Future<int> insertWorkout(Workout workout) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
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

  Future<List<Workout>> getWorkouts() async {
    final db = await database;
    final workoutRows = await db.query(
      'workouts',
      orderBy: 'date DESC',
    );

    final workouts = <Workout>[];
    for (final row in workoutRows) {
      final exercises = await getExercisesByWorkout(row['id'] as int);
      workouts.add(Workout.fromMap(row, exercises: exercises));
    }
    return workouts;
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
}
