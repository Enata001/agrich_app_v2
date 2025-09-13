import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/chat_repository.dart';

final userChatsProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async* {
  final networkService = ref.watch(networkServiceProvider);
  final chatRepository = ref.watch(chatRepositoryProvider);

  // Yield cached chats first
  final cachedChats = await chatRepository.getCachedUserChats(userId);
  if (cachedChats.isNotEmpty) {
    yield cachedChats;
  }

  // Check network connectivity
  final isConnected = await networkService.checkConnectivity();
  if (!isConnected) {
    if (cachedChats.isEmpty) {
      yield [];
    }
    return;
  }

  try {
    // Timeout only on first emission
    final firstChats = await chatRepository.getUserChats(userId).first.timeout(const Duration(seconds: 15));
    yield firstChats;

    // Continue streaming updates
    yield* chatRepository.getUserChats(userId);
  } catch (e) {
    final fallback = await chatRepository.getCachedUserChats(userId);
    yield fallback;
  }
});
// ✅ FIXED: Auto-disposing chat messages stream with caching
final chatMessagesProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, chatId) async* {
  final networkService = ref.watch(networkServiceProvider);
  final chatRepository = ref.watch(chatRepositoryProvider);

  // First yield cached messages
  final cachedMessages = await chatRepository.getCachedMessages(chatId);
  if (cachedMessages.isNotEmpty) {
    yield cachedMessages;
  }

  // Check network connectivity
  final isConnected = await networkService.checkConnectivity();
  if (!isConnected) {
    if (cachedMessages.isEmpty) {
      yield [];
    }
    return;
  }

  // Stream real-time updates if online
  try {
    yield* chatRepository.getMessages(chatId).timeout(
      const Duration(seconds: 15),
      onTimeout: (sink) async {
        final cached = await chatRepository.getCachedMessages(chatId);
        sink.add(cached);
      },
    );
  } catch (e) {
    final cached = await chatRepository.getCachedMessages(chatId);
    yield cached;
  }
});

// ✅ FIXED: Auto-disposing send message provider
final sendMessageProvider = StateNotifierProvider.autoDispose<SendMessageNotifier, SendMessageState>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return SendMessageNotifier(chatRepository);
});

class SendMessageNotifier extends StateNotifier<SendMessageState> {
  final ChatRepository _chatRepository;

  SendMessageNotifier(this._chatRepository) : super(SendMessageState.initial());

  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

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