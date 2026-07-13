import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';
import 'settings_page.dart';
import 'ui_helpers.dart';

enum ChatSender { user, assistant }

class ChatMessage {
  final ChatSender sender;
  final String text;

  ChatMessage({required this.sender, required this.text});
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final AiService _aiService = AiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _hasValidKey = true;

  @override
  void initState() {
    super.initState();
    _validateApiKey();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _validateApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('active_ai_provider')?.toLowerCase() ?? 'gemini';
    final apiKey = provider == 'groq'
        ? prefs.getString('groq_api_key') ?? ''
        : prefs.getString('gemini_api_key') ?? '';

    if (!mounted) return;
    setState(() {
      _hasValidKey = apiKey.trim().isNotEmpty;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(fadeRoute(const SettingsPage()));
    await _validateApiKey();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (!_hasValidKey) {
      showFitLogSnackBar(context, 'Configure a chave de API antes de usar o chat de IA.');
      return;
    }

    setState(() {
      _messages.add(ChatMessage(sender: ChatSender.user, text: text));
      _isLoading = true;
      _messageController.clear();
    });

    final trainingContext = await _aiService.buildTrainingContext();
    final reply = await _aiService.sendMessage('$trainingContext\n\n$text');

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(sender: ChatSender.assistant, text: reply));
      _isLoading = false;
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == ChatSender.user;
    final backgroundColor = isUser ? kPrimaryColor : kSurfaceElevated;
    final textColor = isUser ? Colors.white : kTextPrimary;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Text(
            message.text,
            style: TextStyle(color: textColor, height: 1.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente de treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 72, color: kPrimaryColor.withOpacity(0.9)),
                          const SizedBox(height: 20),
                          Text(
                            'Pergunte ao seu assistente de treino sobre progressão, exercícios e seus últimos registros.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 16),
                      reverse: false,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                    ),
            ),
            if (!_hasValidKey)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Chave de IA não configurada',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Abra as configurações de IA para adicionar sua chave Gemini ou Groq.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _openSettings,
                      child: const Text('Configurações de IA'),
                    ),
                  ],
                ),
              ),
            Container(
              color: kBackgroundColor,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        hintText: 'Escreva sua pergunta sobre treino...',
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _isLoading
                      ? const SizedBox(width: 44, height: 44, child: Center(child: CircularProgressIndicator()))
                      : Material(
                          color: kPrimaryColor,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
