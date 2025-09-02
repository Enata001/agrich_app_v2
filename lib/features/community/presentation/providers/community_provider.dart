import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

// Community Posts Provider
final communityPostsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return await communityRepository.getPosts();
});

// Post Details Provider
final postDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, postId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return await communityRepository.getPostDetails(postId);
});

// Post Comments Provider
final postCommentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, postId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return await communityRepository.getPostComments(postId);
});

// Like Post Provider
final likePostProvider = StateNotifierProvider<LikePostNotifier, LikePostState>((ref) {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return LikePostNotifier(communityRepository);
});

class LikePostNotifier extends StateNotifier<LikePostState> {
  final dynamic _communityRepository;

  LikePostNotifier(this._communityRepository) : super(LikePostState.initial());

  Future<void> likePost(String postId, String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _communityRepository.likePost(postId, userId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void resetState() {
    state = LikePostState.initial();
  }
}

class LikePostState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  LikePostState({
    required this.isLoading,
    required this.isSuccess,
    this.error,
  });

  factory LikePostState.initial() => LikePostState(
    isLoading: false,
    isSuccess: false,
  );

  LikePostState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return LikePostState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
    );
  }
}

// Add Comment Provider
final addCommentProvider = StateNotifierProvider<AddCommentNotifier, AddCommentState>((ref) {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return AddCommentNotifier(communityRepository);
});

class AddCommentNotifier extends StateNotifier<AddCommentState> {
  final dynamic _communityRepository;

  AddCommentNotifier(this._communityRepository) : super(AddCommentState.initial());

  Future<void> addComment(String postId, Map<String, dynamic> commentData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _communityRepository.addComment(postId, commentData);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void resetState() {
    state = AddCommentState.initial();
  }
}

class AddCommentState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  AddCommentState({
    required this.isLoading,
    required this.isSuccess,
    this.error,
  });

  factory AddCommentState.initial() => AddCommentState(
    isLoading: false,
    isSuccess: false,
  );

  AddCommentState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return AddCommentState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
    );
  }
}

// Filtered Posts Provider
final filteredPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, filter) async {
  final posts = await ref.watch(communityPostsProvider.future);

  switch (filter) {
    case 'recent':
      return posts; // Already sorted by recent
    case 'popular':
      posts.sort((a, b) => (b['likesCount'] as int).compareTo(a['likesCount'] as int));
      return posts;
    case 'most_liked':
      posts.sort((a, b) => (b['likesCount'] as int).compareTo(a['likesCount'] as int));
      return posts;
    case 'most_comments':
      posts.sort((a, b) => (b['commentsCount'] as int).compareTo(a['commentsCount'] as int));
      return posts;
    default:
      return posts;
  }
});

// Search Posts Provider
final searchPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }

  final posts = await ref.watch(communityPostsProvider.future);
  return posts.where((post) {
    final content = (post['content'] as String? ?? '').toLowerCase();
    final authorName = (post['authorName'] as String? ?? '').toLowerCase();
    final searchQuery = query.toLowerCase();

    return content.contains(searchQuery) || authorName.contains(searchQuery);
  }).toList();
});