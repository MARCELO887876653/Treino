import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

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
  late Future<List<Category>> _categoriesFuture;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _categoriesFuture = DatabaseHelper.instance.getCategories();
    final categories = await _categoriesFuture;
    if (!mounted) return;
    setState(() {
      if (categories.isNotEmpty) {
        _selectedCategoryId ??= categories.first.id;
      }
    });
    _loadWorkouts();
  }

  void _loadWorkouts() {
    _workoutsFuture = DatabaseHelper.instance.getWorkoutsByCategory(_selectedCategoryId ?? 0);
  }

  Future<void> _refreshWorkouts() async {
    setState(() {
      _loadData();
    });
    await _workoutsFuture;
  }

  Future<bool> _confirmDelete(BuildContext context, String workoutName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir treino'),
          content: Text('Deseja realmente excluir "$workoutName"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Excluir')),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteWorkout(int workoutId) async {
    await DatabaseHelper.instance.deleteWorkout(workoutId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treino excluído com sucesso.')));
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

  Future<void> _manageCategories() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryManagerPage()));
    _refreshWorkouts();
  }

  Future<void> _exportBackup() async {
    final file = await DatabaseHelper.instance.createBackupFile();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Backup de treinos',
      ),
    );
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
    final path = result?.path;
    if (path == null) return;
    final file = File(path);
    final jsonString = await file.readAsString();
    await DatabaseHelper.instance.restoreFromBackup(jsonString);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup importado com sucesso.')));
    _refreshWorkouts();
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'categories') {
                await _manageCategories();
              } else if (value == 'export') {
                await _exportBackup();
              } else if (value == 'import') {
                await _importBackup();
              } else if (value == 'progress') {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressPage()));
                _refreshWorkouts();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'categories', child: Text('Gerenciar categorias')),
              const PopupMenuItem(value: 'export', child: Text('Exportar backup')),
              const PopupMenuItem(value: 'import', child: Text('Importar backup')),
              const PopupMenuItem(value: 'progress', child: Text('Ver progresso')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, categorySnapshot) {
          if (categorySnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = categorySnapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('Nenhuma categoria cadastrada.'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: categories.map((category) {
                    final isSelected = category.id == _selectedCategoryId;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                        _loadWorkouts();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(category.name, style: Theme.of(context).textTheme.titleMedium),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Workout>>(
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
                      return const Center(child: Text('Nenhum treino encontrado nesta categoria.'));
                    }
                    return RefreshIndicator(
                      onRefresh: _refreshWorkouts,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: workouts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                            confirmDismiss: (_) async => _confirmDelete(context, workout.name),
                            onDismissed: (_) async => _deleteWorkout(workout.id!),
                            child: Card(
                              elevation: 3,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                title: Text(workout.name, style: Theme.of(context).textTheme.titleMedium),
                                subtitle: Text('${_formatDate(workout.date)} · $exerciseCount exercício(s)${workout.notes.isEmpty ? '' : ' · ${workout.notes}'}'),
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
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                    const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                                  ],
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
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkoutFormPage()));
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
  Map<String, double> _prWeights = {};
  Timer? _restTimer;
  int _remainingSeconds = 60;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    _loadPrWeights();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrWeights() async {
    final exercises = _workout.exercises;
    final entries = <String, double>{};
    for (final exercise in exercises) {
      final maxWeight = await DatabaseHelper.instance.getMaxWeightForExercise(exercise.name);
      entries[exercise.name] = maxWeight ?? -1;
    }
    if (!mounted) return;
    setState(() {
      _prWeights = entries;
    });
  }

  Future<void> _refreshWorkout() async {
    if (_workout.id == null) return;
    final updated = await DatabaseHelper.instance.getWorkoutById(_workout.id!);
    if (!mounted || updated == null) return;
    setState(() {
      _workout = updated;
    });
    await _loadPrWeights();
  }

  Future<bool> _confirmDelete(BuildContext context, String workoutName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir treino'),
          content: Text('Deseja realmente excluir "$workoutName"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Excluir')),
          ],
        );
      },
    );
    return result ?? false;
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

  Future<void> _duplicateWorkout() async {
    final duplicate = Workout(
      name: '${_workout.name} (cópia)',
      date: DateTime.now(),
      notes: _workout.notes,
      categoryId: _workout.categoryId,
      exercises: _workout.exercises.map((exercise) => Exercise(
            name: exercise.name,
            sets: exercise.sets.map((set) => WorkoutSet(reps: set.reps, weight: set.weight, order: set.order)).toList(),
          )).toList(),
    );
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutFormPage(workout: duplicate)),
    );
    if (updated == true) {
      await _refreshWorkout();
    }
  }

  Future<void> _showRestTimer() async {
    final selectedSeconds = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        final customController = TextEditingController();
        return AlertDialog(
          title: const Text('Tempo de descanso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('60s'), onTap: () => Navigator.of(dialogContext).pop(60)),
              ListTile(title: const Text('90s'), onTap: () => Navigator.of(dialogContext).pop(90)),
              ListTile(title: const Text('120s'), onTap: () => Navigator.of(dialogContext).pop(120)),
              TextField(
                controller: customController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Personalizado (segundos)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final value = int.tryParse(customController.text);
                Navigator.of(dialogContext).pop(value != null && value > 0 ? value : null);
              },
              child: const Text('Iniciar'),
            ),
          ],
        );
      },
    );
    if (selectedSeconds == null || selectedSeconds <= 0) return;

    _restTimer?.cancel();
    setState(() {
      _remainingSeconds = selectedSeconds;
      _isResting = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds -= 1;
        } else {
          timer.cancel();
          _isResting = false;
          Vibration.vibrate(duration: 500);
          SystemSound.play(SystemSoundType.alert);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descanso encerrado!')));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Treino'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), tooltip: 'Duplicar treino', onPressed: _duplicateWorkout),
          IconButton(icon: const Icon(Icons.timer), tooltip: 'Iniciar descanso', onPressed: _showRestTimer),
          IconButton(icon: const Icon(Icons.edit), tooltip: 'Editar treino', onPressed: _editWorkout),
          IconButton(icon: const Icon(Icons.delete), tooltip: 'Excluir treino', onPressed: _deleteWorkout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_workout.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(_formatDate(_workout.date), style: Theme.of(context).textTheme.bodyLarge),
          if (_workout.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Observações', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_workout.notes),
          ],
          if (_isResting) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Descanso'),
                    Text('$_remainingSeconds s', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          for (final exercise in _workout.exercises) ...[
            Card(
              elevation: 3,
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
                            Row(
                              children: [
                                Text('${set.weight.toStringAsFixed(1)} kg', style: Theme.of(context).textTheme.bodyLarge),
                                if ((_prWeights[exercise.name] ?? -1) >= set.weight) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                                ],
                              ],
                            ),
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
  final _notesController = TextEditingController();
  final _exercises = <ExerciseFormData>[];
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditing;
  DateTime _date = DateTime.now();
  int? _workoutId;
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _isEditing = widget.workout != null;
    if (_isEditing && widget.workout != null) {
      _workoutId = widget.workout!.id;
      _date = widget.workout!.date;
      _nameController.text = widget.workout!.name;
      _notesController.text = widget.workout!.notes;
      _selectedCategoryId = widget.workout!.categoryId;
      if (widget.workout!.exercises.isNotEmpty) {
        for (final exercise in widget.workout!.exercises) {
          final exerciseForm = ExerciseFormData();
          exerciseForm.nameController.text = exercise.name;
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

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _isLoadingCategories = false;
      if (_selectedCategoryId == null && categories.isNotEmpty) {
        _selectedCategoryId = categories.first.id;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
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

    final workoutName = _nameController.text.trim().isEmpty ? (_categories.isNotEmpty && _selectedCategoryId != null ? _categories.firstWhere((category) => category.id == _selectedCategoryId, orElse: () => _categories.first).name : 'Treino') : _nameController.text.trim();
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
      notes: _notesController.text.trim(),
      categoryId: _selectedCategoryId,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCategories) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
                  items: _categories.map((category) => DropdownMenuItem(value: category.id, child: Text(category.name))).toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome do treino (opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data do treino'),
                  subtitle: Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                for (final entry in _exercises.asMap().entries)
                  Card(
                    elevation: 3,
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
                                  decoration: InputDecoration(labelText: 'Exercício ${entry.key + 1}'),
                                ),
                              ),
                              if (_exercises.length > 1)
                                IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Remover exercício', onPressed: () => _removeExercise(entry.key)),
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
                                          decoration: InputDecoration(labelText: 'Repetições #${setEntry.key + 1}', border: const OutlineInputBorder()),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: setEntry.value.weightController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(labelText: 'Carga (kg)', border: OutlineInputBorder()),
                                        ),
                                      ),
                                      if (entry.value.sets.length > 1)
                                        IconButton(icon: const Icon(Icons.remove_circle_outline), tooltip: 'Remover série', onPressed: () => _removeSet(entry.key, setEntry.key)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text('Adicionar série'), onPressed: () => _addSet(entry.key)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ElevatedButton.icon(icon: const Icon(Icons.add_box), label: const Text('Adicionar exercício'), onPressed: _addExercise),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _saveWorkout, child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_isEditing ? 'Salvar alterações' : 'Salvar treino'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryManagerPage extends StatefulWidget {
  const CategoryManagerPage({super.key});

  @override
  State<CategoryManagerPage> createState() => _CategoryManagerPageState();
}

class _CategoryManagerPageState extends State<CategoryManagerPage> {
  late Future<List<Category>> _categoriesFuture;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadCategories() {
    _categoriesFuture = DatabaseHelper.instance.getCategories();
  }

  Future<void> _addOrEditCategory([Category? category]) async {
    _controller.text = category?.name ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(category == null ? 'Nova categoria' : 'Editar categoria'),
          content: TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Nome da categoria')),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(_controller.text.trim()), child: const Text('Salvar')),
          ],
        );
      },
    );
    if (result == null || result.isEmpty) return;
    if (category == null) {
      await DatabaseHelper.instance.insertCategory(Category(name: result));
    } else {
      await DatabaseHelper.instance.updateCategory(Category(id: category.id, name: result));
    }
    if (!mounted) return;
    setState(() {
      _loadCategories();
    });
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text('Excluir "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper.instance.deleteCategory(category.id!);
    if (!mounted) return;
    setState(() {
      _loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar categorias')),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  title: Text(category.name),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _addOrEditCategory(category);
                      } else if (value == 'delete') {
                        await _deleteCategory(category);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCategory(),
        child: const Icon(Icons.add),
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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExerciseNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return _progression.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value['weight'] as double)).toList();
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _exerciseNames.where((name) => name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _exerciseNames.isEmpty
                ? Center(child: Text('Nenhum exercício salvo ainda. Crie um treino para ver a progressão.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(labelText: 'Buscar exercício', border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: filteredExercises.contains(_selectedExercise) ? _selectedExercise : null,
                        decoration: const InputDecoration(labelText: 'Exercício', border: OutlineInputBorder()),
                        items: filteredExercises.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
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
                                ? Center(child: Text('Selecione um exercício para visualizar o gráfico de carga.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Progresso de ${_selectedExercise!}', style: Theme.of(context).textTheme.titleLarge),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: LineChart(
                                          LineChartData(
                                            minX: 0,
                                            maxX: (_spots.length - 1).toDouble(),
                                            minY: 0,
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: _spots,
                                                isCurved: true,
                                                color: Colors.deepPurpleAccent,
                                                barWidth: 3,
                                                dotData: const FlDotData(show: true),
                                              ),
                                            ],
                                            titlesData: FlTitlesData(
                                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index < 0 || index >= _progression.length) return const SizedBox.shrink();
                                                return Text(_formatDate(_progression[index]['date'] as String));
                                              })),
                                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                                            ),
                                          ),
                                        ),
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
