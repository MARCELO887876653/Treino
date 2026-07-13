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
import 'ai_chat_page.dart';
import 'settings_page.dart';

const Color kPrimaryColor = Color(0xFFFF6B35);
const Color kAccentColor = Color(0xFFE63946);
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kSurfaceElevated = Color(0xFF262626);
const Color kTextPrimary = Color(0xFFF5F5F5);
const Color kTextSecondary = Color(0xFFB8B8B8);

ThemeData buildFitLogTheme() {
  final baseTheme = ThemeData.dark(useMaterial3: true);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    brightness: Brightness.dark,
    secondary: kAccentColor,
  );

  return baseTheme.copyWith(
    colorScheme: colorScheme.copyWith(
      primary: kPrimaryColor,
      secondary: kAccentColor,
      surface: kSurfaceColor,
      surfaceContainerHighest: kSurfaceElevated,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kTextPrimary,
    ),
    scaffoldBackgroundColor: kBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: kBackgroundColor,
      foregroundColor: kTextPrimary,
      elevation: 0,
      titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
        fontSize: 22,
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurfaceColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3A3A3A))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3A3A3A))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor)),
      labelStyle: const TextStyle(color: kTextSecondary),
      hintStyle: const TextStyle(color: kTextSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    textTheme: baseTheme.textTheme.copyWith(
      headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: kTextPrimary),
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: kTextPrimary),
      titleMedium: baseTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: kTextPrimary),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(color: kTextSecondary),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(color: kTextSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: kSurfaceColor,
      contentTextStyle: const TextStyle(color: kTextPrimary),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    }),
  );
}

SnackBar buildStyledSnackBar(String message, {Color? color}) {
  return SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    backgroundColor: color ?? kSurfaceColor,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

void showFitLogSnackBar(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(buildStyledSnackBar(message, color: color));
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

PageRouteBuilder<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
  );
}

PageRouteBuilder<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();
  runApp(const FitLogApp());
}

class FitLogApp extends StatelessWidget {
  const FitLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLog',
      debugShowCheckedModeBanner: false,
      theme: buildFitLogTheme(),
      home: const CategoryHomePage(),
    );
  }
}

class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Center(
        key: ValueKey(title),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                child: Icon(icon, size: 46, color: color),
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tela inicial: categorias no topo (chips), lista de exercícios da categoria selecionada.
class CategoryHomePage extends StatefulWidget {
  const CategoryHomePage({super.key});

  @override
  State<CategoryHomePage> createState() => _CategoryHomePageState();
}

class _CategoryHomePageState extends State<CategoryHomePage> {
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Exercise>> _exercisesFuture;
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
        final stillExists = categories.any((c) => c.id == _selectedCategoryId);
        if (!stillExists) {
          _selectedCategoryId = categories.first.id;
        }
      } else {
        _selectedCategoryId = null;
      }
    });
    _loadExercises();
  }

  void _loadExercises() {
    setState(() {
      _exercisesFuture = _selectedCategoryId == null
          ? Future.value(<Exercise>[])
          : DatabaseHelper.instance.getExercisesByCategory(_selectedCategoryId!);
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<bool> _confirmDelete(BuildContext context, String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Excluir')),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteExercise(int exerciseId) async {
    await DatabaseHelper.instance.deleteExercise(exerciseId);
    if (!mounted) return;
    showFitLogSnackBar(context, 'Exercício excluído com sucesso.', color: kAccentColor);
    _loadExercises();
  }

  Future<void> _addExercise() async {
    if (_selectedCategoryId == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Novo exercício'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome do exercício'),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    await DatabaseHelper.instance.insertExercise(Exercise(categoryId: _selectedCategoryId, name: name));
    if (!mounted) return;
    showFitLogSnackBar(context, 'Exercício criado.', color: kPrimaryColor);
    _loadExercises();
  }

  Future<void> _renameExercise(Exercise exercise) async {
    final controller = TextEditingController(text: exercise.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar exercício'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome do exercício'),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    await DatabaseHelper.instance.updateExercise(Exercise(id: exercise.id, categoryId: exercise.categoryId, name: name));
    if (!mounted) return;
    _loadExercises();
  }

  Future<void> _manageCategories() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryManagerPage()));
    _refresh();
  }

  Future<void> _exportBackup() async {
    final file = await DatabaseHelper.instance.createBackupFile();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Backup FitLog'),
    );
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    final path = result?.files.single.path;
    if (path == null) return;
    final file = File(path);
    final jsonString = await file.readAsString();
    await DatabaseHelper.instance.restoreFromBackup(jsonString);
    if (!mounted) return;
    showFitLogSnackBar(context, 'Backup importado com sucesso.', color: kPrimaryColor);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.of(context).push(fadeRoute(const AiChatPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(fadeRoute(const SettingsPage()));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'categories') {
                await _manageCategories();
              } else if (value == 'export') {
                await _exportBackup();
              } else if (value == 'import') {
                await _importBackup();
              } else if (value == 'progress') {
                await Navigator.of(context).push(fadeRoute(const ProgressPage()));
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
            return IllustratedEmptyState(
              icon: Icons.category_outlined,
              title: 'Crie sua primeira categoria',
              subtitle: 'Organize seus treinos por foco (ex: Leg day, Push, Pull).',
              accentColor: Theme.of(context).colorScheme.primary,
            );
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
                        _loadExercises();
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
                child: FutureBuilder<List<Exercise>>(
                  future: _exercisesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }
                    final exercises = snapshot.data ?? [];
                    if (exercises.isEmpty) {
                      return IllustratedEmptyState(
                        icon: Icons.fitness_center,
                        title: 'Nenhum exercício ainda',
                        subtitle: 'Adicione o primeiro exercício desta categoria.',
                        accentColor: Theme.of(context).colorScheme.primary,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: exercises.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return Dismissible(
                            key: Key('exercise-${exercise.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              padding: const EdgeInsets.only(right: 24),
                              alignment: Alignment.centerRight,
                              color: Colors.red.shade600,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) => _confirmDelete(context, 'Excluir exercício', 'Deseja excluir "${exercise.name}" e todo o histórico dele?'),
                            onDismissed: (_) => _deleteExercise(exercise.id!),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                leading: const CircleAvatar(
                                  backgroundColor: kSurfaceElevated,
                                  child: Icon(Icons.fitness_center, color: kPrimaryColor, size: 20),
                                ),
                                title: Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) async {
                                    if (value == 'rename') {
                                      await _renameExercise(exercise);
                                    } else if (value == 'delete') {
                                      final confirmed = await _confirmDelete(context, 'Excluir exercício', 'Deseja excluir "${exercise.name}" e todo o histórico dele?');
                                      if (confirmed) await _deleteExercise(exercise.id!);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'rename', child: Text('Renomear')),
                                    const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(fadeRoute(ExerciseDetailPage(exercise: exercise)));
                                  _loadExercises();
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
      floatingActionButton: _selectedCategoryId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Novo exercício'),
            ),
    );
  }
}
/// Tela de detalhes do exercício: mostra o histórico de registros (um por data),
/// permite adicionar novo registro, duplicar o último, iniciar timer de descanso.
class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late Future<List<TrainingRecord>> _recordsFuture;
  double? _maxWeight;
  Timer? _restTimer;
  int _remainingSeconds = 60;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _loadRecords() {
    setState(() {
      _recordsFuture = DatabaseHelper.instance.getRecordsByExercise(widget.exercise.id!);
    });
    _loadMaxWeight();
  }

  Future<void> _loadMaxWeight() async {
    final maxWeight = await DatabaseHelper.instance.getMaxWeightForExercise(widget.exercise.id!);
    if (!mounted) return;
    setState(() {
      _maxWeight = maxWeight;
    });
  }

  Future<bool> _confirmDelete(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir registro'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Excluir')),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteRecord(int recordId) async {
    await DatabaseHelper.instance.deleteRecord(recordId);
    if (!mounted) return;
    showFitLogSnackBar(context, 'Registro excluído.', color: kAccentColor);
    _loadRecords();
  }

  Future<void> _addRecord() async {
    final saved = await Navigator.of(context).push<bool>(
      slideUpRoute(RecordFormPage(exerciseId: widget.exercise.id!)),
    );
    if (saved == true) _loadRecords();
  }

  Future<void> _editRecord(TrainingRecord record) async {
    final saved = await Navigator.of(context).push<bool>(
      slideUpRoute(RecordFormPage(exerciseId: widget.exercise.id!, record: record)),
    );
    if (saved == true) _loadRecords();
  }

  Future<void> _duplicateLastRecord() async {
    final last = await DatabaseHelper.instance.getLastRecordForExercise(widget.exercise.id!);
    if (last == null) {
      showFitLogSnackBar(context, 'Ainda não há nenhum registro para duplicar.', color: kAccentColor);
      return;
    }
    final duplicate = TrainingRecord(
      exerciseId: widget.exercise.id,
      date: DateTime.now(),
      notes: last.notes,
      series: last.series
          .map((entry) => SeriesEntry(reps: entry.reps, weight: entry.weight, order: entry.order))
          .toList(),
    );
    final saved = await Navigator.of(context).push<bool>(
      slideUpRoute(RecordFormPage(exerciseId: widget.exercise.id!, prefill: duplicate)),
    );
    if (saved == true) _loadRecords();
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
          showFitLogSnackBar(context, 'Descanso encerrado!', color: kAccentColor);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        actions: [
          IconButton(icon: const Icon(Icons.copy), tooltip: 'Duplicar último registro', onPressed: _duplicateLastRecord),
          IconButton(icon: const Icon(Icons.timer), tooltip: 'Iniciar descanso', onPressed: _showRestTimer),
        ],
      ),
      body: Column(
        children: [
          if (_isResting)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                child: Card(
                  color: kAccentColor.withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [Icon(Icons.timer_outlined, color: kAccentColor), SizedBox(width: 8), Text('Descanso')]),
                        Text('$_remainingSeconds s', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kAccentColor, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<TrainingRecord>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return IllustratedEmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'Nenhum registro ainda',
                    subtitle: 'Adicione o primeiro registro deste exercício com data, reps e carga.',
                    accentColor: Theme.of(context).colorScheme.primary,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _editRecord(record),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                                    child: Text(formatDate(record.date), style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w700)),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () async {
                                      final confirmed = await _confirmDelete(context, 'Excluir registro de ${formatDate(record.date)}?');
                                      if (confirmed) await _deleteRecord(record.id!);
                                    },
                                  ),
                                ],
                              ),
                              if (record.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(record.notes, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                              const SizedBox(height: 10),
                              const Divider(thickness: 1, color: Color(0xFF353535)),
                              for (final entry in record.series)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Série ${entry.order}', style: Theme.of(context).textTheme.bodyLarge),
                                      Text('${entry.reps} rep', style: Theme.of(context).textTheme.bodyLarge),
                                      Row(
                                        children: [
                                          Text('${entry.weight.toStringAsFixed(1)} kg', style: Theme.of(context).textTheme.bodyLarge),
                                          if (_maxWeight != null && entry.weight >= _maxWeight!) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.emoji_events, color: kAccentColor, size: 20),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
    );
  }
}

class SeriesFormData {
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

/// Formulário simples: só data, observações e séries (reps + carga).
/// Não pede nome, pois o exercício já existe.
class RecordFormPage extends StatefulWidget {
  const RecordFormPage({super.key, required this.exerciseId, this.record, this.prefill});

  final int exerciseId;
  final TrainingRecord? record;
  final TrainingRecord? prefill;

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _notesController = TextEditingController();
  final _series = <SeriesFormData>[];
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditing;
  DateTime _date = DateTime.now();
  int? _recordId;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.record != null;
    final source = widget.record ?? widget.prefill;
    if (source != null) {
      _recordId = widget.record?.id;
      _date = source.date;
      _notesController.text = source.notes;
      for (final entry in source.series) {
        final form = SeriesFormData();
        form.repsController.text = entry.reps.toString();
        form.weightController.text = entry.weight.toString();
        _series.add(form);
      }
    }
    if (_series.isEmpty) {
      _series.add(SeriesFormData());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final series in _series) {
      series.dispose();
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

  void _addSeries() {
    setState(() {
      _series.add(SeriesFormData());
    });
  }

  void _removeSeries(int index) {
    setState(() {
      _series[index].dispose();
      _series.removeAt(index);
    });
  }

  void _showMessage(String message) {
    showFitLogSnackBar(context, message, color: kAccentColor);
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final seriesEntries = <SeriesEntry>[];
    for (var index = 0; index < _series.length; index++) {
      final form = _series[index];
      final reps = int.tryParse(form.repsController.text.trim());
      final weight = double.tryParse(form.weightController.text.trim().replaceAll(',', '.'));
      if (reps == null || weight == null) continue;
      seriesEntries.add(SeriesEntry(reps: reps, weight: weight, order: index + 1));
    }

    if (seriesEntries.isEmpty) {
      _showMessage('Adicione ao menos uma série com repetições e carga.');
      return;
    }

    final record = TrainingRecord(
      id: _recordId,
      exerciseId: widget.exerciseId,
      date: _date,
      notes: _notesController.text.trim(),
      series: seriesEntries,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateRecord(record);
    } else {
      await DatabaseHelper.instance.insertRecord(record);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar registro' : 'Novo registro')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observações (opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                Text('Séries', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final entry in _series.asMap().entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: entry.value.repsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Repetições #${entry.key + 1}', border: const OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: entry.value.weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Carga (kg)', border: OutlineInputBorder()),
                          ),
                        ),
                        if (_series.length > 1)
                          IconButton(icon: const Icon(Icons.remove_circle_outline), tooltip: 'Remover série', onPressed: () => _removeSeries(entry.key)),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text('Adicionar série'), onPressed: _addSeries),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveRecord,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_isEditing ? 'Salvar alterações' : 'Salvar registro'),
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
        content: Text('Excluir "${category.name}"? Os exercícios e registros dela também serão apagados.'),
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
      appBar: AppBar(title: const Text('Categorias')),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return IllustratedEmptyState(
              icon: Icons.category_outlined,
              title: 'Nenhuma categoria ainda',
              subtitle: 'Crie a primeira categoria para organizar seus treinos.',
              accentColor: Theme.of(context).colorScheme.primary,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
  List<Exercise> _allExercises = [];
  Exercise? _selectedExercise;
  List<Map<String, dynamic>> _progression = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    final categories = await DatabaseHelper.instance.getCategories();
    final allExercises = <Exercise>[];
    for (final category in categories) {
      final exercises = await DatabaseHelper.instance.getExercisesByCategory(category.id!);
      allExercises.addAll(exercises);
    }
    if (!mounted) return;
    setState(() {
      _allExercises = allExercises;
      _selectedExercise = allExercises.isNotEmpty ? allExercises.first : null;
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
    if (_selectedExercise?.id == null) return;
    final progression = await DatabaseHelper.instance.getProgressionForExercise(_selectedExercise!.id!);
    if (!mounted) return;
    setState(() {
      _progression = progression;
      _isLoading = false;
    });
  }

  List<FlSpot> get _weightSpots {
    return _progression.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value['weight'] as double)).toList();
  }

  String _formatIsoDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredExercises = _allExercises.where((e) => e.name.toLowerCase().contains(query)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allExercises.isEmpty
                ? IllustratedEmptyState(
                    icon: Icons.insights_outlined,
                    title: 'Nenhum exercício salvo ainda',
                    subtitle: 'Crie um exercício e registre séries para acompanhar sua progressão.',
                    accentColor: Theme.of(context).colorScheme.primary,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(labelText: 'Buscar exercício', border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: filteredExercises.any((e) => e.id == _selectedExercise?.id) ? _selectedExercise?.id : null,
                        decoration: const InputDecoration(labelText: 'Exercício', border: OutlineInputBorder()),
                        items: filteredExercises.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                        onChanged: (value) {
                          final exercise = _allExercises.firstWhere((e) => e.id == value);
                          setState(() {
                            _selectedExercise = exercise;
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
                                ? IllustratedEmptyState(
                                    icon: Icons.show_chart,
                                    title: 'Sem registros para este exercício',
                                    subtitle: 'Adicione registros para visualizar o gráfico de evolução.',
                                    accentColor: Theme.of(context).colorScheme.primary,
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Progresso de ${_selectedExercise?.name ?? ''}', style: Theme.of(context).textTheme.titleLarge),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: LineChart(
                                          LineChartData(
                                            minX: 0,
                                            maxX: (_weightSpots.length - 1).toDouble().clamp(0, double.infinity),
                                            minY: 0,
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: _weightSpots,
                                                isCurved: true,
                                                color: kPrimaryColor,
                                                barWidth: 3,
                                                dotData: const FlDotData(show: true),
                                              ),
                                            ],
                                            titlesData: FlTitlesData(
                                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index < 0 || index >= _progression.length) return const SizedBox.shrink();
                                                return Text(_formatIsoDate(_progression[index]['date'] as String));
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
