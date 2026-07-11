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
      version: 3,
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
      CREATE TABLE exercises(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE series(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        series_order INTEGER NOT NULL,
        FOREIGN KEY(record_id) REFERENCES records(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Versões antigas (workouts/exercises/sets) são descartadas.
    // O usuário deve reimportar seus dados via backup JSON após esta atualização.
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS sets');
      await db.execute('DROP TABLE IF EXISTS exercises');
      await db.execute('DROP TABLE IF EXISTS workouts');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS records');
      await db.execute('DROP TABLE IF EXISTS series');
      await _onCreate(db, newVersion);
    }
  }

  // ---------- CATEGORIAS ----------

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
    return db.insert('categories', category.toMap()..remove('id'));
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    if (category.id == null) return insertCategory(category);
    return db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int categoryId) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  // ---------- EXERCÍCIOS ----------

  Future<List<Exercise>> getExercisesByCategory(int categoryId) async {
    final db = await database;
    final rows = await db.query(
      'exercises',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return rows.map((row) => Exercise.fromMap(row)).toList();
  }

  Future<Exercise?> getExerciseById(int id) async {
    final db = await database;
    final rows = await db.query('exercises', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    return db.insert('exercises', exercise.toMap()..remove('id'));
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await database;
    if (exercise.id == null) return insertExercise(exercise);
    return db.update('exercises', exercise.toMap(), where: 'id = ?', whereArgs: [exercise.id]);
  }

  Future<int> deleteExercise(int exerciseId) async {
    final db = await database;
    return db.delete('exercises', where: 'id = ?', whereArgs: [exerciseId]);
  }

  Future<List<String>> getDistinctExerciseNames() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT DISTINCT name FROM exercises ORDER BY name ASC');
    return rows.map((row) => row['name'] as String).toList();
  }

  // ---------- REGISTROS (por data) ----------

  Future<int> insertRecord(TrainingRecord record) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final recordId = await txn.insert('records', {
        'exercise_id': record.exerciseId,
        'date': record.date.toIso8601String(),
        'notes': record.notes,
      });
      for (final entry in record.series) {
        await txn.insert('series', {
          'record_id': recordId,
          'reps': entry.reps,
          'weight': entry.weight,
          'series_order': entry.order,
        });
      }
      return recordId;
    });
  }

  Future<int> updateRecord(TrainingRecord record) async {
    final db = await database;
    if (record.id == null) return insertRecord(record);
    return db.transaction<int>((txn) async {
      await txn.update(
        'records',
        {
          'exercise_id': record.exerciseId,
          'date': record.date.toIso8601String(),
          'notes': record.notes,
        },
        where: 'id = ?',
        whereArgs: [record.id],
      );
      await txn.delete('series', where: 'record_id = ?', whereArgs: [record.id]);
      for (final entry in record.series) {
        await txn.insert('series', {
          'record_id': record.id,
          'reps': entry.reps,
          'weight': entry.weight,
          'series_order': entry.order,
        });
      }
      return record.id!;
    });
  }

  Future<int> deleteRecord(int recordId) async {
    final db = await database;
    return db.delete('records', where: 'id = ?', whereArgs: [recordId]);
  }

  Future<TrainingRecord?> getRecordById(int id) async {
    final db = await database;
    final rows = await db.query('records', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final series = await getSeriesByRecord(id);
    return TrainingRecord.fromMap(rows.first, series: series);
  }

  Future<List<TrainingRecord>> getRecordsByExercise(int exerciseId) async {
    final db = await database;
    final rows = await db.query(
      'records',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date DESC',
    );
    final records = <TrainingRecord>[];
    for (final row in rows) {
      final series = await getSeriesByRecord(row['id'] as int);
      records.add(TrainingRecord.fromMap(row, series: series));
    }
    return records;
  }

  Future<TrainingRecord?> getLastRecordForExercise(int exerciseId) async {
    final db = await database;
    final rows = await db.query(
      'records',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final series = await getSeriesByRecord(rows.first['id'] as int);
    return TrainingRecord.fromMap(rows.first, series: series);
  }

  Future<List<SeriesEntry>> getSeriesByRecord(int recordId) async {
    final db = await database;
    final rows = await db.query(
      'series',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'series_order ASC',
    );
    return rows.map((row) => SeriesEntry.fromMap(row)).toList();
  }

  // ---------- PROGRESSÃO / GRÁFICOS ----------

  Future<List<Map<String, dynamic>>> getProgressionForExercise(int exerciseId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        r.date AS date,
        MAX(s.weight) AS max_weight,
        SUM(s.reps * s.weight) AS volume
      FROM records r
      JOIN series s ON s.record_id = r.id
      WHERE r.exercise_id = ?
      GROUP BY r.id
      ORDER BY r.date ASC
    ''', [exerciseId]);

    return rows.map((row) {
      return {
        'date': row['date'] as String,
        'weight': (row['max_weight'] as num).toDouble(),
        'volume': (row['volume'] as num).toDouble(),
      };
    }).toList();
  }

  Future<double?> getMaxWeightForExercise(int exerciseId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT MAX(s.weight) AS max_weight
      FROM series s
      JOIN records r ON r.id = s.record_id
      WHERE r.exercise_id = ?
    ''', [exerciseId]);
    if (rows.isEmpty) return null;
    final value = rows.first['max_weight'];
    if (value == null) return null;
    return (value as num).toDouble();
  }

  /// Retorna true se [weight] é um novo recorde pessoal (PR) para o exercício,
  /// ou seja, maior que qualquer carga já registrada antes deste registro.
  Future<bool> isPersonalRecord(int exerciseId, double weight, {int? excludeRecordId}) async {
    final currentMax = await getMaxWeightForExercise(exerciseId);
    if (currentMax == null) return true;
    return weight > currentMax;
  }

  // ---------- BACKUP (exportar / importar) ----------

  Future<String> exportBackupJson() async {
    final db = await database;
    final categories = await getCategories();
    final exerciseRows = await db.query('exercises');

    final payload = {
      'version': 3,
      'categories': categories.map((c) => c.toJson()).toList(),
      'exercises': <Map<String, dynamic>>[],
    };

    for (final exRow in exerciseRows) {
      final exercise = Exercise.fromMap(exRow);
      final records = await getRecordsByExercise(exercise.id!);
      (payload['exercises'] as List).add({
        ...exercise.toJson(),
        'records': records.map((r) => r.toJson()).toList(),
      });
    }

    return jsonEncode(payload);
  }

  Future<void> restoreFromBackup(String jsonString) async {
    final payload = jsonDecode(jsonString) as Map<String, dynamic>;
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('series');
      await txn.delete('records');
      await txn.delete('exercises');
      await txn.delete('categories');

      final categoriesJson = (payload['categories'] as List<dynamic>?) ?? [];
      for (final catJson in categoriesJson) {
        final map = catJson as Map<String, dynamic>;
        await txn.insert('categories', {
          'id': map['id'],
          'name': map['name'],
        });
      }

      final exercisesJson = (payload['exercises'] as List<dynamic>?) ?? [];
      for (final exJson in exercisesJson) {
        final exMap = exJson as Map<String, dynamic>;
        final exerciseId = await txn.insert('exercises', {
          'id': exMap['id'],
          'category_id': exMap['category_id'],
          'name': exMap['name'],
        });

        final recordsJson = (exMap['records'] as List<dynamic>?) ?? [];
        for (final recJson in recordsJson) {
          final recMap = recJson as Map<String, dynamic>;
          final recordId = await txn.insert('records', {
            'exercise_id': exerciseId,
            'date': recMap['date'],
            'notes': recMap['notes'] ?? '',
          });

          final seriesJson = (recMap['series'] as List<dynamic>?) ?? [];
          for (final serJson in seriesJson) {
            final serMap = serJson as Map<String, dynamic>;
            await txn.insert('series', {
              'record_id': recordId,
              'reps': serMap['reps'],
              'weight': serMap['weight'],
              'series_order': serMap['series_order'] ?? serMap['order'] ?? 1,
            });
          }
        }
      }
    });
  }

  Future<File> createBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(join(directory.path, 'fitlog_backup.json'));
    final jsonString = await exportBackupJson();
    await file.writeAsString(jsonString);
    return file;
  }
}
