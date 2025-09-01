import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/community_repository.dart';

final createPostProvider = StateNotifierProvider<CreatePostNotifier, CreatePostState>((ref) {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return CreatePostNotifier(communityRepository);
});

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  final CommunityRepository _communityRepository;

  CreatePostNotifier(this._communityRepository) : super(CreatePostState.initial());

  Future<void> createPost({
    required String content,
    required String authorId,
    required String authorName,
    required String authorEmail,
    File? imageFile,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _communityRepository.uploadPostImage(imageFile);
      }

      final postData = {
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorEmail': authorEmail,
        'authorAvatar': '', // TODO: Get from user profile
        'imageUrl': imageUrl ?? '',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await _communityRepository.createPost(postData);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw e;
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