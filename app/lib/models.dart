class Category {
  final int? id;
  final String name;

  Category({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Exercise {
  final int? id;
  final int? categoryId;
  final String name;

  Exercise({this.id, this.categoryId, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
    };
  }
}

class TrainingRecord {
  final int? id;
  final int? exerciseId;
  final DateTime date;
  final String notes;
  final List<SeriesEntry> series;

  TrainingRecord({
    this.id,
    this.exerciseId,
    required this.date,
    this.notes = '',
    required this.series,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory TrainingRecord.fromMap(Map<String, dynamic> map, {List<SeriesEntry>? series}) {
    return TrainingRecord(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int?,
      date: DateTime.parse(map['date'] as String),
      notes: (map['notes'] ?? '') as String,
      series: series ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'date': date.toIso8601String(),
      'notes': notes,
      'series': series.map((entry) => entry.toJson()).toList(),
    };
  }
}

class SeriesEntry {
  final int? id;
  final int? recordId;
  final int reps;
  final double weight;
  final int order;

  const SeriesEntry({
    this.id,
    this.recordId,
    required this.reps,
    required this.weight,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'reps': reps,
      'weight': weight,
      'series_order': order,
    };
  }

  factory SeriesEntry.fromMap(Map<String, dynamic> map) {
    return SeriesEntry(
      id: map['id'] as int?,
      recordId: map['record_id'] as int?,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
      order: map['series_order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_id': recordId,
      'reps': reps,
      'weight': weight,
      'series_order': order,
    };
  }
}
