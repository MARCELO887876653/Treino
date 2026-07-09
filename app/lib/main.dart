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

  Future<bool> _confirmDelete(BuildContext context, String workoutName) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Excluir treino'),
              content: Text('Deseja realmente excluir "$workoutName"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deleteWorkout(int workoutId) async {
    await DatabaseHelper.instance.deleteWorkout(workoutId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Treino excluído com sucesso.')),
    );
    _refreshWorkouts();
  }

  Future<void> _editWorkout(Workout workout) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutFormPage(workout: workout)),
    );
    if (updated == true) {
      _refreshWorkouts();
    }
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
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final workout = workouts[index];
                final exerciseCount = workout.exercises.length;
                return Dismissible(
                  key: Key('workout-${workout.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 24),
                    alignment: Alignment.centerRight,
                    color: Colors.red.shade600,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await _confirmDelete(context, workout.name);
                  },
                  onDismissed: (_) async {
                    await _deleteWorkout(workout.id!);
                  },
                  child: Card(
                    elevation: 3,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(workout.name, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text('${_formatDate(workout.date)} · $exerciseCount exercício(s)'),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _editWorkout(workout);
                          } else if (value == 'delete') {
                            final confirmed = await _confirmDelete(context, workout.name);
                            if (confirmed) {
                              await _deleteWorkout(workout.id!);
                            }
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                            const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                          ];
                        },
                      ),
                      onTap: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => WorkoutDetailPage(workout: workout)),
                        );
                        _refreshWorkouts();
                      },
                    ),
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
            MaterialPageRoute(builder: (_) => const WorkoutFormPage()),
          );
          _refreshWorkouts();
        },
        tooltip: 'Adicionar novo treino',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({super.key, required this.workout});

  final Workout workout;

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late Workout _workout;
  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
  }

  Future<void> _refreshWorkout() async {
    if (_workout.id == null) return;
    final updated = await DatabaseHelper.instance.getWorkoutById(_workout.id!);
    if (!mounted || updated == null) return;
    setState(() {
      _workout = updated;
    });
  }

  Future<bool> _confirmDelete(BuildContext context, String workoutName) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Excluir treino'),
              content: Text('Deseja realmente excluir "$workoutName"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _deleteWorkout() async {
    if (_workout.id == null) return;
    final confirmed = await _confirmDelete(context, _workout.name);
    if (!confirmed) return;
    await DatabaseHelper.instance.deleteWorkout(_workout.id!);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _editWorkout() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutFormPage(workout: _workout)),
    );
    if (updated == true) {
      await _refreshWorkout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar treino',
            onPressed: _editWorkout,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Excluir treino',
            onPressed: _deleteWorkout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_workout.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(_formatDate(_workout.date), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          for (final exercise in _workout.exercises) ...[
            Card(
              elevation: 3,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1),
                    for (final set in exercise.sets) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Série ${set.order}', style: Theme.of(context).textTheme.bodyLarge),
                            Text('${set.reps} rep', style: Theme.of(context).textTheme.bodyLarge),
                            Text('${set.weight.toStringAsFixed(1)} kg', style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WorkoutFormPage extends StatefulWidget {
  const WorkoutFormPage({super.key, this.workout});

  final Workout? workout;

  @override
  State<WorkoutFormPage> createState() => _WorkoutFormPageState();
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

class _WorkoutFormPageState extends State<WorkoutFormPage> {
  final _nameController = TextEditingController();
  final _exercises = <ExerciseFormData>[];
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditing;
  DateTime _date = DateTime.now();
  int? _workoutId;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.workout != null;
    if (_isEditing && widget.workout != null) {
      _workoutId = widget.workout!.id;
      _date = widget.workout!.date;
      _nameController.text = widget.workout!.name;
      if (widget.workout!.exercises.isNotEmpty) {
        for (final exercise in widget.workout!.exercises) {
          final exerciseForm = ExerciseFormData();
          exerciseForm.nameController.text = exercise.name;
          exerciseForm.sets.clear();
          for (final set in exercise.sets) {
            final setForm = WorkoutSetFormData();
            setForm.repsController.text = set.reps.toString();
            setForm.weightController.text = set.weight.toString();
            exerciseForm.sets.add(setForm);
          }
          _exercises.add(exerciseForm);
        }
      } else {
        _addExercise();
      }
    } else {
      _addExercise();
    }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final workoutName = _nameController.text.trim();
    final exercises = <Exercise>[];
    for (final exerciseForm in _exercises) {
      final exerciseName = exerciseForm.nameController.text.trim();
      if (exerciseName.isEmpty) continue;
      final sets = <WorkoutSet>[];
      for (var index = 0; index < exerciseForm.sets.length; index++) {
        final setForm = exerciseForm.sets[index];
        final reps = int.tryParse(setForm.repsController.text.trim());
        final weight = double.tryParse(setForm.weightController.text.trim().replaceAll(',', '.'));
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
      id: _workoutId,
      name: workoutName,
      date: _date,
      exercises: exercises,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateWorkout(workout);
    } else {
      await DatabaseHelper.instance.insertWorkout(workout);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Treino' : 'Novo Treino')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do treino',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do treino.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                for (final entry in _exercises.asMap().entries)
                  Card(
                    elevation: 3,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: entry.value.nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Exercício ${entry.key + 1}',
                                  ),
                                ),
                              ),
                              if (_exercises.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Remover exercício',
                                  onPressed: () => _removeExercise(entry.key),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              for (final setEntry in entry.value.sets.asMap().entries)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: setEntry.value.repsController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Repetições #${setEntry.key + 1}',
                                            border: const OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: setEntry.value.weightController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Carga (kg)',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      if (entry.value.sets.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          tooltip: 'Remover série',
                                          onPressed: () => _removeSet(entry.key, setEntry.key),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar série'),
                              onPressed: () => _addSet(entry.key),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_box),
                  label: const Text('Adicionar exercício'),
                  onPressed: _addExercise,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveWorkout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_isEditing ? 'Salvar alterações' : 'Salvar treino'),
                  ),
                ),
              ],
            ),
          ),
        ),
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
