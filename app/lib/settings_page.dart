import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_helpers.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _geminiController = TextEditingController();
  final TextEditingController _groqController = TextEditingController();
  String _activeProvider = 'Gemini';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _groqController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final geminiKey = prefs.getString('gemini_api_key') ?? '';
    final groqKey = prefs.getString('groq_api_key') ?? '';
    final activeProvider = prefs.getString('active_ai_provider') ?? 'gemini';

    if (!mounted) return;
    setState(() {
      _geminiController.text = geminiKey;
      _groqController.text = groqKey;
      _activeProvider = activeProvider.toLowerCase() == 'groq' ? 'Groq' : 'Gemini';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _geminiController.text.trim());
    await prefs.setString('groq_api_key', _groqController.text.trim());
    await prefs.setString('active_ai_provider', _activeProvider.toLowerCase());

    if (!mounted) return;
    showFitLogSnackBar(context, 'Configurações de IA salvas com sucesso.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de IA'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chaves de API',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _geminiController,
                    decoration: const InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'Cole a chave de API da Gemini aqui',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _groqController,
                    decoration: const InputDecoration(
                      labelText: 'Groq API Key',
                      hintText: 'Cole a chave de API da Groq aqui',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Fornecedor ativo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonFormField<String>(
                        value: _activeProvider,
                        items: const [
                          DropdownMenuItem(value: 'Gemini', child: Text('Gemini')),
                          DropdownMenuItem(value: 'Groq', child: Text('Groq')),
                        ],
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _activeProvider = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ),
    );
  }
}
