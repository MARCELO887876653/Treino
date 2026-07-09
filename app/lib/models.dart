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
}

class Workout {
  final int? id;
  final String name;
  final DateTime date;
  final String notes;
  final int? categoryId;
  final List<Exercise> exercises;

  Workout({
    this.id,
    required this.name,
    required this.date,
    this.notes = '',
    this.categoryId,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'notes': notes,
      'category_id': categoryId,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map, {List<Exercise>? exercises}) {
    return Workout(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: (map['notes'] ?? '') as String,
      categoryId: map['category_id'] as int?,
      exercises: exercises ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'notes': notes,
      'category_id': categoryId,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  factory Workout.fromJson(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: (map['notes'] ?? '') as String,
      categoryId: map['category_id'] as int?,
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((value) => Exercise.fromJson(value as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Exercise {
  final int? id;
  final int? workoutId;
  final String name;
  final List<WorkoutSet> sets;

  Exercise({
    this.id,
    this.workoutId,
    required this.name,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'name': name,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map, {List<WorkoutSet>? sets}) {
    return Exercise(
      id: map['id'] as int?,
      workoutId: map['workout_id'] as int?,
      name: map['name'] as String,
      sets: sets ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_id': workoutId,
      'name': name,
      'sets': sets.map((set) => set.toJson()).toList(),
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      workoutId: map['workout_id'] as int?,
      name: map['name'] as String,
      sets: (map['sets'] as List<dynamic>?)
              ?.map((value) => WorkoutSet.fromJson(value as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WorkoutSet {
  final int? id;
  final int? exerciseId;
  final int reps;
  final double weight;
  final int order;

  WorkoutSet({
    this.id,
    this.exerciseId,
    required this.reps,
    required this.weight,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'reps': reps,
      'weight': weight,
      'set_order': order,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int?,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
      order: map['set_order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'reps': reps,
      'weight': weight,
      'set_order': order,
    };
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int?,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
      order: map['set_order'] as int,
    );
  }
}
