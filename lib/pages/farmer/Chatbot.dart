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
    // 🔑 MODEL INITIALIZATION WITH PERSONA, BREVITY, AND TOOLS
    _model = GenerativeModel(
      // 1. MODEL: Use a model that supports function calling, like gemini-1.5-flash
      model: 'gemini-2.0-flash', // Corrected model name
      apiKey: apiKey,
      // 2. PERSONA & SCOPE: Force the model to act as an agri-expert.
      systemInstruction: Content.system(
        "You are 'AgriBot,' a helpful, short, and precise livestock expert. Only provide information related to pig and poultry health, biosecurity, feed, housing, breeding, pest control, or market prices. Politely and briefly decline any non-livestock-related questions. Your answers must be short and direct, typically one to two sentences.",
      ),
      // 3. BREVITY & TOOLS: Configure token limits and enable Google Search.
      generationConfig: GenerationConfig(
        maxOutputTokens: 100, // For short responses
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
      // Generate content using the pre-configured model.
      // No need to pass config here as it's part of the model.
      final response = await _model.generateContent([Content.text(message)]);

      final reply = response.text ?? "Sorry, I couldn't fetch the precise agricultural response.";

      setState(() {
        _messages.add({'sender': 'bot', 'text': reply});
        _isLoading = false;
      });

    } catch (e) {
      // Provide a more user-friendly error message
      setState(() {
        _messages.add({'sender': 'bot', 'text': 'Error: Could not get response. Please check your connection and API key.'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Chatbot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask about crops, prices, or pests...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}