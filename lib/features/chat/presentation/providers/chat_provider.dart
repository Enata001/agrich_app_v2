import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/chat_repository.dart';

final userChatsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId)  {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getUserChats(userId);
});

final chatMessagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getMessages(chatId);
});

final sendMessageProvider = StateNotifierProvider<SendMessageNotifier, SendMessageState>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return SendMessageNotifier(chatRepository);
});

class SendMessageNotifier extends StateNotifier<SendMessageState> {
  final ChatRepository _chatRepository;

  SendMessageNotifier(this._chatRepository) : super(SendMessageState.initial());

  // ✅ FIXED: Now matches ChatRepository.sendMessage() expectation
  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Ensure chatId is included in messageData
      await _chatRepository.sendMessage(messageData);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void resetState() {
    state = SendMessageState.initial();
  }
}

class SendMessageState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  SendMessageState({
    required this.isLoading,
    required this.isSuccess,
    this.error,
  });

  factory SendMessageState.initial() => SendMessageState(
    isLoading: false,
    isSuccess: false,
  );

  SendMessageState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return SendMessageState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
    );
  }
}