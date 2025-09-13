import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/providers/app_providers.dart';

final createPostProvider = StateNotifierProvider<CreatePostNotifier, CreatePostState>((ref) {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return CreatePostNotifier(communityRepository);
});

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  final dynamic _communityRepository;

  CreatePostNotifier(this._communityRepository) : super(CreatePostState.initial());

  Future<void> createPost({
    required String content,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    File? imageFile,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      String? imageUrl;
      if (imageFile != null) {
        // Upload image first
        imageUrl = await _communityRepository.uploadPostImage(imageFile.path, authorId);
      }

      final postData = {
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'imageUrl': imageUrl ?? '',
        'likesCount': 0,
        'commentsCount': 0,
        'likedBy': <String>[],
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await _communityRepository.createPost(postData);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void resetState() {
    state = CreatePostState.initial();
  }
}

class CreatePostState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  CreatePostState({
    required this.isLoading,
    required this.isSuccess,
    this.error,
  });

  factory CreatePostState.initial() => CreatePostState(
    isLoading: false,
    isSuccess: false,
  );

  CreatePostState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return CreatePostState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
    );
  }
}