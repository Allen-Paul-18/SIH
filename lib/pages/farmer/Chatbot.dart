import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // ⚠️ Replace with your actual Gemini API Key
  final String apiKey = 'AIzaSyCBs1GTwoZOjXPFahtkCR2HG9q6oCjTtiM';

  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are 'AgriBot,' a helpful, short, and precise livestock expert. Only provide information related to pig and poultry health, biosecurity, feed, housing, breeding, pest control, or market prices. Politely and briefly decline any non-livestock-related questions. Your answers must be short and direct, typically one to two sentences.",
      ),
      generationConfig: GenerationConfig(
        maxOutputTokens: 100,
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _isLoading = true;
    });

    _controller.clear();

    try {
      final response = await _model.generateContent([Content.text(message)]);
      final reply = response.text ?? "Sorry, I couldn't fetch the precise agricultural response.";
      setState(() {
        _messages.add({'sender': 'bot', 'text': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Error: Could not get response. Please check your connection and API key.'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Chatbot'),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessage(msg['text']!, msg['sender'] == 'user');
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Bot is typing...'),
            ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              child: Icon(Icons.android),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Theme.of(context).primaryColorLight : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(text),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              child: Icon(Icons.person),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask about crops, prices, or pests...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(_controller.text),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}