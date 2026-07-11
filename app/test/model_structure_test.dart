import 'package:app/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new data model supports category -> exercise -> record -> series hierarchy', () {
    final category = Category(id: 1, name: 'Leg day');
    final exercise = Exercise(id: 1, categoryId: category.id, name: 'Mesa flexora');
    final record = TrainingRecord(
      id: 1,
      exerciseId: exercise.id,
      date: DateTime(2026, 7, 10),
      notes: 'Bom treino',
      series: const [
        SeriesEntry(reps: 8, weight: 40, order: 1),
        SeriesEntry(reps: 8, weight: 45, order: 2),
      ],
    );

    expect(category.name, 'Leg day');
    expect(exercise.categoryId, category.id);
    expect(record.exerciseId, exercise.id);
    expect(record.series.length, 2);
    expect(record.series.first.reps, 8);
  });
}
