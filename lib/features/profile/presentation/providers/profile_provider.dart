// lib/features/profile/presentation/providers/profile_provider.dart

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/repositories/profile_repository.dart';

// Profile state classes
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

final profileProviderNotifier =
StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
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


// FIXED: User Videos Provider - gets videos created by user
final userVideosProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videoRepository = ref.watch(videosRepositoryProvider);
  final connectivityService = ConnectivityService();

  return await connectivityService.executeWithConnectivity(
        () async {
      final allVideos = await videoRepository.getAllVideos();
      // Filter videos where user is the author
      return allVideos.where((video) => video['authorId'] == userId).toList();
    },
    fallbackValue: <Map<String, dynamic>>[],
    operationName: 'Get User Videos',
  );
});

// FIXED: Saved Posts Provider
final savedPostsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  final connectivityService = ConnectivityService();

  return await connectivityService.executeWithConnectivity(
        () async => await communityRepository.getSavedPosts(userId),
    fallbackValue: <Map<String, dynamic>>[],
    operationName: 'Get Saved Posts',
  );
});

// FIXED: Saved Videos Provider
final savedVideosProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videoRepository = ref.watch(videosRepositoryProvider);
  final connectivityService = ConnectivityService();

  return await connectivityService.executeWithConnectivity(
        () async => await videoRepository.getUserSavedVideos(userId),
    fallbackValue: <Map<String, dynamic>>[],
    operationName: 'Get Saved Videos',
  );
});

// FIXED: Liked Videos Provider
final likedVideosProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videoRepository = ref.watch(videosRepositoryProvider);
  final connectivityService = ConnectivityService();

  return await connectivityService.executeWithConnectivity(
        () async => await videoRepository.getUserLikedVideos(userId),
    fallbackValue: <Map<String, dynamic>>[],
    operationName: 'Get Liked Videos',
  );
});

// FIXED: User Posts Provider - Convert Stream to Future
final userPostsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  final connectivityService = ConnectivityService();

  return await connectivityService.executeWithConnectivity(
        () async {
      final stream = communityRepository.getUserPosts(userId);
      return await stream.first;
    },
    fallbackValue: <Map<String, dynamic>>[],
    operationName: 'Get User Posts',
  );
});

// FIXED: Comprehensive User Stats Provider
final userStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) async {
  final connectivityService = ConnectivityService();

  return await connectivityService.executeWithConnectivity(
        () async {
      // Execute all data fetching concurrently
      final results = await Future.wait([
        ref.read(userPostsProvider(userId).future),
        ref.read(userVideosProvider(userId).future),
        ref.read(savedPostsProvider(userId).future),
        ref.read(savedVideosProvider(userId).future),
        ref.read(likedVideosProvider(userId).future),
      ]);

      final userPosts = results[0];
      final userVideos = results[1];
      final savedPosts = results[2];
      final savedVideos = results[3];
      final likedVideos = results[4];

      // Calculate total likes on user's posts
      int totalLikes = 0;
      for (final post in userPosts) {
        totalLikes += (post['likesCount'] as int?) ?? 0;
      }

      // Calculate total views on user's videos
      int totalVideoViews = 0;
      for (final video in userVideos) {
        totalVideoViews += (video['views'] as int?) ?? 0;
      }

      // Calculate total video likes
      int totalVideoLikes = 0;
      for (final video in userVideos) {
        totalVideoLikes += (video['likes'] as int?) ?? 0;
      }

      return {
        'postsCount': userPosts.length,
        'videosCount': userVideos.length,
        'savedPostsCount': savedPosts.length,
        'savedVideosCount': savedVideos.length,
        'likedVideosCount': likedVideos.length,
        'totalLikes': totalLikes,
        'totalVideoViews': totalVideoViews,
        'totalVideoLikes': totalVideoLikes,
        'totalContent': userPosts.length + userVideos.length,
        'totalSaved': savedPosts.length + savedVideos.length,
        'engagementScore': totalLikes + totalVideoLikes + totalVideoViews,
      };
    },
    fallbackValue: {
      'postsCount': 0,
      'videosCount': 0,
      'savedPostsCount': 0,
      'savedVideosCount': 0,
      'likedVideosCount': 0,
      'totalLikes': 0,
      'totalVideoViews': 0,
      'totalVideoLikes': 0,
      'totalContent': 0,
      'totalSaved': 0,
      'engagementScore': 0,
    },
    operationName: 'Get User Stats',
  );
});

// FIXED: Watch History Provider
final watchHistoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videoRepository = ref.watch(videosRepositoryProvider);
  final connectivityService = ConnectivityService();

  return await connectivityService.executeWithConnectivity(
        () async => await videoRepository.getWatchHistoryFromFirebase(userId),
    fallbackValue: <Map<String, dynamic>>[],
    operationName: 'Get Watch History',
  );
});

// FIXED: Recently Watched Provider
final recentlyWatchedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final videoRepository = ref.watch(videosRepositoryProvider);

  // This uses local storage, so no connectivity check needed
  try {
    return videoRepository.getRecentlyWatchedVideos();
  } catch (e) {
    print('Error getting recently watched videos: $e');
    return [];
  }
});

// Profile Update Provider (unchanged)
final profileUpdateProvider = StateNotifierProvider.autoDispose<ProfileUpdateNotifier, ProfileUpdateState>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileUpdateNotifier(profileRepository);
});

class ProfileUpdateNotifier extends StateNotifier<ProfileUpdateState> {
  final dynamic _profileRepository;
  final ConnectivityService _connectivityService = ConnectivityService();

  ProfileUpdateNotifier(this._profileRepository) : super(ProfileUpdateState.initial());

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _connectivityService.executeWithConnectivity(
            () async => await _profileRepository.updateProfile(userId, data),
        operationName: 'Update Profile',
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> uploadProfilePicture(String imagePath) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _connectivityService.executeWithConnectivity(
            () async {
          final imageUrl = await _profileRepository.uploadProfilePicture(imagePath);
          return imageUrl;
        },
        operationName: 'Upload Profile Picture',
      );

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