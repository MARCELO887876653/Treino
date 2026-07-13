import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'database_helper.dart';

class AiService {
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _groqApiKeyKey = 'groq_api_key';
  static const String _activeProviderKey = 'active_ai_provider';

  final http.Client _client;

  AiService([http.Client? client]) : _client = client ?? http.Client();

  static const String _systemPrompt =
      'Você é um assistente de treino do app FitLog. Responda apenas sobre treinos, exercícios, progressão de carga e saúde/fitness relacionados aos dados do usuário. ' 
      'Se perguntarem algo fora desse escopo, educadamente redirecione a conversa para o assunto de treinos.';

  Future<String> sendMessage(String userMessage) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(_activeProviderKey)?.toLowerCase() ?? 'gemini';
    final apiKey = provider == 'groq'
        ? prefs.getString(_groqApiKeyKey) ?? ''
        : prefs.getString(_geminiApiKeyKey) ?? '';

    if (apiKey.isEmpty) {
      return 'A chave de API não está configurada. Abra as configurações de IA e insira sua chave Gemini ou Groq.';
    }

    try {
      if (provider == 'groq') {
        return await _sendGroqMessage(apiKey, userMessage);
      }
      return await _sendGeminiMessage(apiKey, userMessage);
    } catch (error) {
      return _formatError(error);
    }
  }

  Future<String> _sendGeminiMessage(String apiKey, String userMessage) async {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1/models/gemini-2.0-flash:generateContent',
      {'key': apiKey},
    );

    final body = jsonEncode({
      'prompt': {
        'text': '$_systemPrompt\n\n$userMessage',
      },
      'temperature': 0.7,
      'candidateCount': 1,
    });

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      return _extractApiError(response.body, 'Gemini');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final output = data['candidates'] is List
        ? (data['candidates'] as List).cast<Map<String, dynamic>>().firstWhere(
              (candidate) => candidate.containsKey('output'),
              orElse: () => <String, dynamic>{},
            )['output']
        : data['outputText'];

    if (output is String && output.isNotEmpty) {
      return output.trim();
    }

    return 'Resposta da Gemini recebida, mas não foi possível extrair o texto. Tente novamente.';
  }

  Future<String> _sendGroqMessage(String apiKey, String userMessage) async {
    final uri = Uri.https('api.groq.com', '/openai/v1/chat/completions');

    final body = jsonEncode({
      'model': 'groq-1',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.7,
    });

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      return _extractApiError(response.body, 'Groq');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      return 'A resposta da Groq não retornou mensagens. Tente novamente.';
    }

    final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    final content = message?['content'];
    if (content is String && content.isNotEmpty) {
      return content.trim();
    }

    if (content is Map<String, dynamic> && content['parts'] is List) {
      final parts = (content['parts'] as List).cast<String>();
      return parts.join('').trim();
    }

    return 'Não foi possível extrair a resposta da Groq. Tente novamente.';
  }

  String _extractApiError(String body, String providerName) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] ?? json['message'] ?? json['detail'];
      if (error is String && error.isNotEmpty) {
        return '$providerName retornou erro: $error';
      }
      if (error is Map<String, dynamic> && error['message'] is String) {
        return '$providerName retornou erro: ${error['message']}';
      }
    } catch (_) {
      // ignore parse errors
    }
    return 'Erro na API $providerName. Verifique a chave e a conexão de rede.';
  }

  String _formatError(Object error) {
    if (error is http.ClientException) {
      return 'Falha de conexão com o serviço de IA. Verifique sua internet e tente novamente.';
    }
    return 'Erro ao se comunicar com o serviço de IA: ${error.toString()}';
  }

  Future<String> buildTrainingContext() async {
    final categories = await DatabaseHelper.instance.getCategories();
    if (categories.isEmpty) {
      return 'O usuário ainda não registrou categorias ou exercícios no app.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Resumo dos treinos do usuário:');

    for (final category in categories) {
      buffer.writeln('\nCategoria: ${category.name}');
      final exercises = await DatabaseHelper.instance.getExercisesByCategory(category.id!);
      if (exercises.isEmpty) {
        buffer.writeln('  Nenhum exercício registrado nesta categoria.');
        continue;
      }

      for (final exercise in exercises) {
        buffer.writeln('  Exercício: ${exercise.name}');
        final records = await DatabaseHelper.instance.getRecordsByExercise(exercise.id!);
        if (records.isEmpty) {
          buffer.writeln('    Nenhum registro encontrado para este exercício.');
          continue;
        }

        final recentRecords = records.take(5).toList();
        for (final record in recentRecords) {
          final dateString = record.date.toIso8601String().split('T').first;
          buffer.writeln('    Data: $dateString');
          if (record.series.isEmpty) {
            buffer.writeln('      Sem séries registradas.');
          } else {
            for (final entry in record.series) {
              buffer.writeln('      Série ${entry.order}: ${entry.reps} reps x ${entry.weight} kg');
            }
          }
          if (record.notes.isNotEmpty) {
            buffer.writeln('      Observações: ${record.notes}');
          }
        }
      }
    }

    return buffer.toString().trim();
  }
}
