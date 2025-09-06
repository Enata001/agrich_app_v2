import 'package:agrich_app_v2/core/config/app_config.dart';
import 'package:dio/dio.dart';

class ChatbotService {
  final Dio _dio = Dio();
  static const String _openAiApiUrl = AppConfig.openAiApiUrl;
  static  final String _openAiApiKey = AppConfig.openAiApiKey;

  ChatbotService() {
    _dio.options.headers = {
      'Authorization': 'Bearer $_openAiApiKey',
      'Content-Type': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);


    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('Chatbot API: $obj'),
      ),
    );
  }

  // Send message to AI chatbot and get response
  Future<String> sendMessage(
    String message,
    List<Map<String, String>> conversationHistory,
  ) async {
    try {
      // Prepare the messages for the API call
      final messages = _prepareMessages(message, conversationHistory);

      final response = await _dio.post(
        _openAiApiUrl,
        data: {
          'model': 'gpt-3.5-turbo',
          // You can change to gpt-4 if you have access
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
          'presence_penalty': 0.1,
          'frequency_penalty': 0.1,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final choices = data['choices'] as List;

        if (choices.isNotEmpty) {
          final choice = choices[0];
          final message = choice['message'];
          final content = message['content'] as String;
          return content.trim();
        } else {
          return 'I apologize, but I couldn\'t generate a response. Please try again.';
        }
      } else {
        throw Exception(
          'Failed to get response from AI: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      print('Error in chatbot service: $e');
      return 'I\'m having trouble connecting right now. Please check your internet connection and try again.';
    }
  }

  // Prepare messages with system prompt and conversation history
  List<Map<String, String>> _prepareMessages(
    String userMessage,
    List<Map<String, String>> history,
  ) {
    final messages = <Map<String, String>>[];

    // System prompt to set the AI's behavior
    messages.add({
      'role': 'system',
      'content':
          '''You are AgriBot, an AI assistant specialized in agriculture and farming. 
You help farmers with:
- Crop management and cultivation advice
- Pest and disease identification and treatment
- Soil health and fertilization guidance
- Weather-related farming decisions
- Sustainable farming practices
- Equipment and technology recommendations
- Market insights and crop planning

Always provide practical, actionable advice. Be friendly, knowledgeable, and supportive. 
If asked about non-agricultural topics, politely redirect the conversation back to farming.
Keep responses concise but informative, and ask follow-up questions when helpful.''',
    });

    // Add conversation history (limit to last 10 exchanges to manage token usage)
    final recentHistory = history.length > 20
        ? history.sublist(history.length - 20)
        : history;
    messages.addAll(recentHistory);

    // Add the current user message
    messages.add({'role': 'user', 'content': userMessage});

    return messages;
  }

  // Handle API errors gracefully
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      switch (statusCode) {
        case 401:
          return 'Authentication failed. Please check the API configuration.';
        case 429:
          return 'I\'m receiving too many requests right now. Please wait a moment and try again.';
        case 500:
        case 502:
        case 503:
          return 'The AI service is temporarily unavailable. Please try again in a few moments.';
        default:
          return 'I encountered an error (${statusCode}). Please try again.';
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please check your internet connection and try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'I can\'t connect to the AI service right now. Please check your internet connection.';
    } else {
      return 'I encountered an unexpected error. Please try again.';
    }
  }

  // Get a welcome message for new conversations
  String getWelcomeMessage() {
    final welcomeMessages = [
      'Hello! I\'m AgriBot, your agricultural assistant. How can I help you with your farming needs today?',
      'Hi there! I\'m here to help with all your farming questions. What would you like to know?',
      'Welcome! I\'m AgriBot, and I\'m excited to help you with your agricultural journey. What can I assist you with?',
      'Hello farmer! I\'m AgriBot, your AI farming companion. Ask me anything about crops, soil, weather, or farming techniques!',
    ];

    welcomeMessages.shuffle();
    return welcomeMessages.first;
  }

  // Get suggested questions for the user
  List<String> getSuggestedQuestions() {
    return [
      'What crops grow best in my climate?',
      'How do I improve my soil quality?',
      'When should I plant tomatoes?',
      'How can I deal with pest problems naturally?',
      'What are signs of nutrient deficiency in plants?',
      'How much water do my crops need?',
      'What are the best farming practices for beginners?',
      'How do I prepare my soil for planting season?',
    ];
  }

  bool isConfigured() {
    return _openAiApiKey.isNotEmpty &&
        _openAiApiKey != 'your-openai-api-key-here';
  }
}
