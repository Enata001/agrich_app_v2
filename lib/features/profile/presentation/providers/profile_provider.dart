import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/profile_repository.dart';



final profileProviderNotifier = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(profileRepository);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileNotifier(this._profileRepository) : super(ProfileState.initial());

  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true);
      final imageUrl = await _profileRepository.uploadProfilePicture(imageFile);
      state = state.copyWith(isLoading: false);
      return imageUrl;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true);
      await _profileRepository.updateProfile(userId, data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

class ProfileState {
  final bool isLoading;
  final String? error;

  ProfileState({
    required this.isLoading,
    this.error,
  });

  factory ProfileState.initial() => ProfileState(isLoading: false);

  ProfileState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final userVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videoRepository = ref.watch(videosRepositoryProvider);
  return await videoRepository.getAllVideos();
});

// Saved Posts Provider
final savedPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return await communityRepository.getSavedPosts(userId);
});

// User Posts Provider
final userPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return await communityRepository.getUserPosts(userId);
});

// User Stats Provider
final userStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  final videoRepository = ref.watch(videosRepositoryProvider);

  // Get user posts
  final posts = await communityRepository.getUserPosts(userId);
  final videos = await videoRepository.getAllVideos();
  final savedPosts = await communityRepository.getSavedPosts(userId);

  // Calculate total likes across all posts
  final totalLikes = posts.fold<int>(0, (sum, post) => sum + (post['likesCount'] as int? ?? 0));

  return {
    'postsCount': posts.length,
    'videosCount': videos.length,
    'savedPostsCount': savedPosts.length,
    'totalLikes': totalLikes,
  };
});

// Profile Update Provider
final profileUpdateProvider = StateNotifierProvider<ProfileUpdateNotifier, ProfileUpdateState>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileUpdateNotifier(profileRepository);
});

class ProfileUpdateNotifier extends StateNotifier<ProfileUpdateState> {
  final dynamic _profileRepository;

  ProfileUpdateNotifier(this._profileRepository) : super(ProfileUpdateState.initial());

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _profileRepository.updateProfile(userId, data);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void resetState() {
    state = ProfileUpdateState.initial();
  }
}

class ProfileUpdateState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  ProfileUpdateState({
    required this.isLoading,
    required this.isSuccess,
    this.error,
  });

  factory ProfileUpdateState.initial() => ProfileUpdateState(
    isLoading: false,
    isSuccess: false,
  );

  ProfileUpdateState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return ProfileUpdateState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
    );
  }
}