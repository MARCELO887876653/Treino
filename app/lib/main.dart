import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();
  runApp(const TrainProgressApp());
}

class TrainProgressApp extends StatelessWidget {
  const TrainProgressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progressão de Treino',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const WorkoutListPage(),
    );
  }
}

class WorkoutListPage extends StatefulWidget {
  const WorkoutListPage({super.key});

  @override
  State<WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends State<WorkoutListPage> {
  late Future<List<Workout>> _workoutsFuture;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  void _loadWorkouts() {
    _workoutsFuture = DatabaseHelper.instance.getWorkouts();
  }

  Future<void> _refreshWorkouts() async {
    setState(() {
      _loadWorkouts();
    });
    await _workoutsFuture;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progressão de Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Ver progresso',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProgressPage()),
              );
              _refreshWorkouts();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Workout>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final workouts = snapshot.data ?? [];
          if (workouts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Nenhum treino salvo ainda. Use o botão + para adicionar um novo treino.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refreshWorkouts,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final workout = workouts[index];
                final exerciseCount = workout.exercises.length;
                return Card(
                  child: ListTile(
                    title: Text(workout.name),
                    subtitle: Text('${_formatDate(workout.date)} · $exerciseCount exercício(s)'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => WorkoutDetailPage(workout: workout)),
                      );
                      _refreshWorkouts();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewWorkoutPage()),
          );
          _refreshWorkouts();
        },
        tooltip: 'Adicionar novo treino',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WorkoutDetailPage extends StatelessWidget {
  const WorkoutDetailPage({super.key, required this.workout});

  final Workout workout;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Treino')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(workout.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(_formatDate(workout.date), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          ...workout.exercises.map((exercise) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...exercise.sets.map(
                      (set) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('Série ${set.order}: ${set.reps} rep / ${set.weight.toStringAsFixed(1)} kg'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class NewWorkoutPage extends StatefulWidget {
  const NewWorkoutPage({super.key});

  @override
  State<NewWorkoutPage> createState() => _NewWorkoutPageState();
}

class WorkoutSetFormData {
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

class ExerciseFormData {
  final TextEditingController nameController = TextEditingController();
  final List<WorkoutSetFormData> sets;

  ExerciseFormData() : sets = [WorkoutSetFormData()];

  void dispose() {
    nameController.dispose();
    for (final setData in sets) {
      setData.dispose();
    }
  }
}

class _NewWorkoutPageState extends State<NewWorkoutPage> {
  final _nameController = TextEditingController();
  final _exercises = <ExerciseFormData>[];

  @override
  void initState() {
    super.initState();
    _addExercise();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exercises.add(ExerciseFormData());
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      _exercises[exerciseIndex].sets.add(WorkoutSetFormData());
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises[index].dispose();
      _exercises.removeAt(index);
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      _exercises[exerciseIndex].sets[setIndex].dispose();
      _exercises[exerciseIndex].sets.removeAt(setIndex);
    });
  }

  Future<void> _saveWorkout() async {
    final workoutName = _nameController.text.trim();
    if (workoutName.isEmpty) {
      _showMessage('Informe o nome do treino.');
      return;
    }

    final exercises = <Exercise>[];
    for (final exerciseForm in _exercises) {
      final exerciseName = exerciseForm.nameController.text.trim();
      if (exerciseName.isEmpty) continue;
      final sets = <WorkoutSet>[];
      for (var index = 0; index < exerciseForm.sets.length; index++) {
        final setForm = exerciseForm.sets[index];
        final repsText = setForm.repsController.text.trim();
        final weightText = setForm.weightController.text.trim();
        if (repsText.isEmpty || weightText.isEmpty) continue;
        final reps = int.tryParse(repsText);
        final weight = double.tryParse(weightText.replaceAll(',', '.'));
        if (reps == null || weight == null) continue;
        sets.add(WorkoutSet(reps: reps, weight: weight, order: index + 1));
      }
      if (sets.isNotEmpty) {
        exercises.add(Exercise(name: exerciseName, sets: sets));
      }
    }

    if (exercises.isEmpty) {
      _showMessage('Adicione pelo menos um exercício com ao menos uma série.');
      return;
    }

    final workout = Workout(
      name: workoutName,
      date: DateTime.now(),
      exercises: exercises,
    );

    await DatabaseHelper.instance.insertWorkout(workout);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Treino')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do treino',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ..._exercises.asMap().entries.map((entry) {
            final exerciseIndex = entry.key;
            final exerciseForm = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: exerciseForm.nameController,
                            decoration: InputDecoration(
                              labelText: 'Exercício ${exerciseIndex + 1}',
                            ),
                          ),
                        ),
                        if (_exercises.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remover exercício',
                            onPressed: () => _removeExercise(exerciseIndex),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: exerciseForm.sets.asMap().entries.map((setEntry) {
                        final setIndex = setEntry.key;
                        final setForm = setEntry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: setForm.repsController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Repetições #${setIndex + 1}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: setForm.weightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Carga (kg)',
                                  ),
                                ),
                              ),
                              if (exerciseForm.sets.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  tooltip: 'Remover série',
                                  onPressed: () => _removeSet(exerciseIndex, setIndex),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar série'),
                      onPressed: () => _addSet(exerciseIndex),
                    ),
                  ],
                ),
              ),
            );
          }),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_box),
            label: const Text('Adicionar exercício'),
            onPressed: _addExercise,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveWorkout,
            child: const Text('Salvar treino'),
          ),
        ],
      ),
    );
  }
}

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  List<String> _exerciseNames = [];
  String? _selectedExercise;
  List<Map<String, dynamic>> _progression = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExerciseNames();
  }

  Future<void> _loadExerciseNames() async {
    final names = await DatabaseHelper.instance.getDistinctExerciseNames();
    if (!mounted) return;

    setState(() {
      _exerciseNames = names;
      _selectedExercise = names.isNotEmpty ? names.first : null;
    });

    if (_selectedExercise != null) {
      await _loadProgression();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProgression() async {
    if (_selectedExercise == null) return;
    final progression = await DatabaseHelper.instance.getProgressionForExercise(_selectedExercise!);
    if (!mounted) return;
    setState(() {
      _progression = progression;
      _isLoading = false;
    });
  }

  List<FlSpot> get _spots {
    return _progression.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['weight'] as double));
    }).toList();
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _exerciseNames.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum exercício salvo ainda. Crie um treino para ver a progressão.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedExercise,
                        decoration: const InputDecoration(
                          labelText: 'Exercício',
                          border: OutlineInputBorder(),
                        ),
                        items: _exerciseNames
                            .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedExercise = value;
                            _isLoading = true;
                          });
                          _loadProgression();
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _progression.isEmpty
                                ? Center(
                                    child: Text(
                                      'Selecione um exercício para visualizar o gráfico de carga.',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Progresso de ${_selectedExercise!}',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: LineChart(
                                          LineChartData(
                                            minX: 0,
                                            maxX: (_spots.length - 1).toDouble().clamp(0, double.infinity),
                                            minY: 0,
                                            maxY: _spots
                                                    .map((point) => point.y)
                                                    .fold<double>(0, (prev, value) => value > prev ? value : prev) +
                                                5,
                                            gridData: FlGridData(show: true),
                                            titlesData: FlTitlesData(
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 42,
                                                  interval: 1,
                                                  getTitlesWidget: (value, meta) {
                                                    final index = value.toInt();
                                                    if (index < 0 || index >= _progression.length) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    return SideTitleWidget(
                                                      meta: meta,
                                                      child: Text(_formatDate(_progression[index]['date'] as String)),
                                                    );
                                                  },
                                                ),
                                              ),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: 10),
                                              ),
                                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            ),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: _spots,
                                                isCurved: true,
                                                barWidth: 3,
                                                dotData: FlDotData(show: true),
                                                belowBarData: BarAreaData(show: true, color: Colors.deepPurple.withAlpha(51)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Último registro: ${_progression.last['weight'].toStringAsFixed(1)} kg',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
