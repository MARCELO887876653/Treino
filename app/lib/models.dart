class Workout {
  final int? id;
  final String name;
  final DateTime date;
  final List<Exercise> exercises;

  Workout({
    this.id,
    required this.name,
    required this.date,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map, {List<Exercise>? exercises}) {
    return Workout(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      exercises: exercises ?? [],
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
}
