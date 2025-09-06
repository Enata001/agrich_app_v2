import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/chatbot_service.dart';

// ChatMessage model
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? id;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.id,
  });

  ChatMessage copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? id,
  }) {
    return ChatMessage(
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
    );
  }
}

// Chatbot state
class ChatbotState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  ChatbotState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService();
});

// Chatbot state notifier
class ChatbotNotifier extends StateNotifier<ChatbotState> {
  final ChatbotService _chatbotService;

  ChatbotNotifier(this._chatbotService) : super(ChatbotState());

  // Initialize conversation with welcome message
  void initializeConversation() {
    if (!state.isInitialized) {
      if (!_chatbotService.isConfigured()) {
        // Show configuration error
        final errorMessage = ChatMessage(
          content: 'Sorry, I\'m not properly configured yet. Please add your OpenAI API key to start chatting with me.',
          isUser: false,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          messages: [errorMessage],
          isInitialized: true,
        );
        return;
      }

      final welcomeMessage = ChatMessage(
        content: _chatbotService.getWelcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [welcomeMessage],
        isInitialized: true,
      );
    }
  }

  // Send message to chatbot
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || state.isLoading) return;

    // Add user message to conversation
    final userMessage = ChatMessage(
      content: message.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Prepare conversation history for API call
      final conversationHistory = _prepareConversationHistory();

      // Get response from AI
      final response = await _chatbotService.sendMessage(message, conversationHistory);

      // Add AI response to conversation
      final aiMessage = ChatMessage(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );

    } catch (e) {
      // Handle error
      final errorMessage = ChatMessage(
        content: 'I apologize, but I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Clear conversation
  void clearConversation() {
    state = state.copyWith(
      messages: [],
      isInitialized: false,
      error: null,
    );
    initializeConversation();
  }

  // Get suggested questions
  List<String> getSuggestedQuestions() {
    return _chatbotService.getSuggestedQuestions();
  }

  // Prepare conversation history for API call
  List<Map<String, String>> _prepareConversationHistory() {
    final history = <Map<String, String>>[];

    // Skip the welcome message and take last 10 exchanges
    final relevantMessages = state.messages
        .where((msg) => !(msg.content.startsWith('Hello!') ||
        msg.content.startsWith('Hi there!') ||
        msg.content.startsWith('Welcome!')))
        .toList();

    final recentMessages = relevantMessages.length > 20
        ? relevantMessages.sublist(relevantMessages.length - 20)
        : relevantMessages;

    for (final message in recentMessages) {
      history.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.content,
      });
    }

    return history;
  }

  // Retry last message
  Future<void> retryLastMessage() async {
    if (state.messages.isEmpty) return;

    // Find the last user message
    ChatMessage? lastUserMessage;
    for (int i = state.messages.length - 1; i >= 0; i--) {
      if (state.messages[i].isUser) {
        lastUserMessage = state.messages[i];
        break;
      }
    }

    if (lastUserMessage != null) {
      // Remove messages after the last user message
      final messagesUpToUser = <ChatMessage>[];
      for (final message in state.messages) {
        messagesUpToUser.add(message);
        if (message == lastUserMessage) break;
      }

      state = state.copyWith(messages: messagesUpToUser);

      // Resend the message
      await sendMessage(lastUserMessage.content);
    }
  }

  // Add a pre-written response (for testing without API)
  void addTestResponse(String userMessage) {
    final userMsg = ChatMessage(
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final responses = [
      'That\'s a great question about farming! Here are some key points to consider...',
      'Based on my agricultural knowledge, I\'d recommend looking into sustainable farming practices.',
      'For optimal crop growth, you should consider factors like soil pH, moisture levels, and seasonal timing.',
      'Pest management is crucial for healthy crops. Have you considered integrated pest management approaches?',
      'Weather patterns significantly impact farming decisions. What\'s your local climate like?',
    ];

    responses.shuffle();

    final aiMsg = ChatMessage(
      content: responses.first,
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, aiMsg],
    );
  }
}

// Chatbot provider
final chatbotProvider = StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  final chatbotService = ref.watch(chatbotServiceProvider);
  return ChatbotNotifier(chatbotService);
});