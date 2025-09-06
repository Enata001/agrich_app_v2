// lib/features/videos/presentation/providers/video_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/app_providers.dart';

// All Videos Provider
final allVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getAllVideos();
  } catch (e) {
    print('Error loading all videos: $e');
    return [];
  }
});

// Recent Videos Provider (for home screen)
final recentVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getRecentlyWatchedVideos();
  } catch (e) {
    print('Error loading recent videos: $e');
    return [];
  }
});

// Videos by Category Provider
final videosByCategoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    if (category == 'All') {
      return await videosRepository.getAllVideos();
    }
    return await videosRepository.getVideosByCategory(category);
  } catch (e) {
    print('Error loading videos for category $category: $e');
    return [];
  }
});

// Popular Videos Provider (based on views and likes)
final popularVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    final allVideos = await videosRepository.getAllVideos();

    // Sort by popularity (views + likes)
    final sortedVideos = List<Map<String, dynamic>>.from(allVideos);
    sortedVideos.sort((a, b) {
      final aViews = a['views'] as int? ?? 0;
      final bViews = b['views'] as int? ?? 0;
      final aLikes = a['likes'] as int? ?? 0;
      final bLikes = b['likes'] as int? ?? 0;

      final aScore = aViews + (aLikes * 10); // Weight likes more
      final bScore = bViews + (bLikes * 10);

      return bScore.compareTo(aScore);
    });

    return sortedVideos;
  } catch (e) {
    print('Error loading popular videos: $e');
    return [];
  }
});

// Trending Videos Provider (recent + popular combination)
final trendingVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    final allVideos = await videosRepository.getAllVideos();

    // Filter videos from last 30 days and sort by engagement
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentVideos = allVideos.where((video) {
      final uploadDate = video['uploadDate'] as DateTime? ?? DateTime.now();
      return uploadDate.isAfter(thirtyDaysAgo);
    }).toList();

    // Sort by engagement rate (views + likes + comments)
    recentVideos.sort((a, b) {
      final aViews = a['views'] as int? ?? 0;
      final bViews = b['views'] as int? ?? 0;
      final aLikes = a['likes'] as int? ?? 0;
      final bLikes = b['likes'] as int? ?? 0;
      final aComments = a['commentsCount'] as int? ?? 0;
      final bComments = b['commentsCount'] as int? ?? 0;

      final aEngagement = aViews + (aLikes * 5) + (aComments * 3);
      final bEngagement = bViews + (bLikes * 5) + (bComments * 3);

      return bEngagement.compareTo(aEngagement);
    });

    return recentVideos;
  } catch (e) {
    print('Error loading trending videos: $e');
    return [];
  }
});

// Search Videos Provider
final searchVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.searchVideos(query);
  } catch (e) {
    print('Error searching videos: $e');
    return [];
  }
});

// Video Categories Provider
final videoCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getVideoCategories();
  } catch (e) {
    // Return default categories from config
    return ['All', ...AppConfig.videoCategories];
  }
});

// Video Stats Provider
final videoStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    final allVideos = await videosRepository.getAllVideos();

    final totalVideos = allVideos.length;
    final totalViews = allVideos.fold<int>(0, (sum, video) => sum + (video['views'] as int? ?? 0));
    final totalLikes = allVideos.fold<int>(0, (sum, video) => sum + (video['likes'] as int? ?? 0));
    final averageViews = totalVideos > 0 ? totalViews / totalVideos : 0.0;

    // Category distribution
    final categories = <String, int>{};
    for (final video in allVideos) {
      final category = video['category'] as String? ?? 'Other';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return {
      'totalVideos': totalVideos,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'averageViews': averageViews,
      'categoriesCount': categories,
      'mostPopularCategory': categories.entries.isNotEmpty
          ? categories.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'None',
    };
  } catch (e) {
    return {
      'totalVideos': 0,
      'totalViews': 0,
      'totalLikes': 0,
      'averageViews': 0.0,
      'categoriesCount': <String, int>{},
      'mostPopularCategory': 'None',
    };
  }
});

// Video Details Provider
final videoDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, videoId) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getVideoDetails(videoId);
  } catch (e) {
    print('Error loading video details for $videoId: $e');
    return null;
  }
});

// User's Saved Videos Provider
final savedVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getUserSavedVideos(userId);
  } catch (e) {
    print('Error loading saved videos for user $userId: $e');
    return [];
  }
});

// User's Liked Videos Provider
final likedVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getUserLikedVideos(userId);
  } catch (e) {
    print('Error loading liked videos for user $userId: $e');
    return [];
  }
});

// Video Player State Provider
class VideoPlayerState {
  final String? currentVideoId;
  final String? currentVideoUrl;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isLoading;
  final String? error;

  VideoPlayerState({
    this.currentVideoId,
    this.currentVideoUrl,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isLoading = false,
    this.error,
  });

  VideoPlayerState copyWith({
    String? currentVideoId,
    String? currentVideoUrl,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isLoading,
    String? error,
  }) {
    return VideoPlayerState(
      currentVideoId: currentVideoId ?? this.currentVideoId,
      currentVideoUrl: currentVideoUrl ?? this.currentVideoUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final videoPlayerStateProvider = StateNotifierProvider<VideoPlayerNotifier, VideoPlayerState>((ref) {
  return VideoPlayerNotifier();
});

class VideoPlayerNotifier extends StateNotifier<VideoPlayerState> {
  VideoPlayerNotifier() : super(VideoPlayerState());

  void loadVideo(String videoId, String videoUrl) {
    state = state.copyWith(
      currentVideoId: videoId,
      currentVideoUrl: videoUrl,
      isLoading: true,
      error: null,
    );
  }

  void setPlaying(bool isPlaying) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  void setPosition(Duration position) {
    state = state.copyWith(position: position);
  }

  void setDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void reset() {
    state = VideoPlayerState();
  }
}

// Video Filter State Provider
class VideoFilterState {
  final String category;
  final String sortBy; // 'recent', 'popular', 'trending', 'duration'
  final String duration; // 'all', 'short', 'medium', 'long'
  final bool showSavedOnly;

  VideoFilterState({
    this.category = 'All',
    this.sortBy = 'recent',
    this.duration = 'all',
    this.showSavedOnly = false,
  });

  VideoFilterState copyWith({
    String? category,
    String? sortBy,
    String? duration,
    bool? showSavedOnly,
  }) {
    return VideoFilterState(
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      duration: duration ?? this.duration,
      showSavedOnly: showSavedOnly ?? this.showSavedOnly,
    );
  }
}

final videoFilterProvider = StateProvider<VideoFilterState>((ref) => VideoFilterState());

// Filtered Videos Provider (combines all filters)
final filteredVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final filter = ref.watch(videoFilterProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);

  try {
    List<Map<String, dynamic>> videos;

    // Get videos by category
    if (filter.category == 'All') {
      videos = await videosRepository.getAllVideos();
    } else {
      videos = await videosRepository.getVideosByCategory(filter.category);
    }

    // Filter by duration
    if (filter.duration != 'all') {
      videos = videos.where((video) {
        final durationStr = video['duration'] as String? ?? '0:00';
        final duration = _parseDuration(durationStr);

        switch (filter.duration) {
          case 'short':
            return duration.inMinutes <= 5;
          case 'medium':
            return duration.inMinutes > 5 && duration.inMinutes <= 15;
          case 'long':
            return duration.inMinutes > 15;
          default:
            return true;
        }
      }).toList();
    }

    // Filter saved only if requested
    if (filter.showSavedOnly) {
      videos = videos.where((video) => video['isSaved'] == true).toList();
    }

    // Sort videos
    switch (filter.sortBy) {
      case 'popular':
        videos.sort((a, b) {
          final aViews = a['views'] as int? ?? 0;
          final bViews = b['views'] as int? ?? 0;
          return bViews.compareTo(aViews);
        });
        break;
      case 'trending':
        videos.sort((a, b) {
          final aLikes = a['likes'] as int? ?? 0;
          final bLikes = b['likes'] as int? ?? 0;
          return bLikes.compareTo(aLikes);
        });
        break;
      case 'duration':
        videos.sort((a, b) {
          final aDuration = _parseDuration(a['duration'] as String? ?? '0:00');
          final bDuration = _parseDuration(b['duration'] as String? ?? '0:00');
          return aDuration.compareTo(bDuration);
        });
        break;
      case 'recent':
      default:
        videos.sort((a, b) {
          final aDate = a['uploadDate'] as DateTime? ?? DateTime.now();
          final bDate = b['uploadDate'] as DateTime? ?? DateTime.now();
          return bDate.compareTo(aDate);
        });
        break;
    }

    return videos;
  } catch (e) {
    print('Error filtering videos: $e');
    return [];
  }
});

// Video Actions Provider
final videoActionsProvider = Provider<VideoActions>((ref) {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return VideoActions(videosRepository, ref);
});

class VideoActions {
  final dynamic videosRepository; // VideosRepository
  final Ref ref;

  VideoActions(this.videosRepository, this.ref);

  Future<void> likeVideo(String videoId, String userId) async {
    try {
      await videosRepository.likeVideo(videoId, userId);
      // Invalidate relevant providers
      ref.invalidate(allVideosProvider);
      ref.invalidate(videoDetailsProvider(videoId));
      ref.invalidate(likedVideosProvider(userId));
    } catch (e) {
      print('Error liking video: $e');
      rethrow;
    }
  }

  Future<void> saveVideo(String videoId, String userId) async {
    try {
      await videosRepository.saveVideo(videoId, userId);
      // Invalidate relevant providers
      ref.invalidate(savedVideosProvider(userId));
    } catch (e) {
      print('Error saving video: $e');
      rethrow;
    }
  }

  Future<void> incrementViewCount(String videoId) async {
    try {
      await videosRepository.incrementViewCount(videoId);
      ref.invalidate(videoDetailsProvider(videoId));
    } catch (e) {
      print('Error incrementing view count: $e');
      // Don't rethrow as view count is not critical
    }
  }

  Future<void> addToWatchHistory(String videoId, String userId) async {
    try {
      await videosRepository.addToWatchHistory(videoId, userId);
      ref.invalidate(recentVideosProvider);
    } catch (e) {
      print('Error adding to watch history: $e');
      // Don't rethrow as watch history is not critical
    }
  }
}

// Helper function to parse duration string
Duration _parseDuration(String durationStr) {
  try {
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      return Duration(minutes: minutes, seconds: seconds);
    } else if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }
  } catch (e) {
    // If parsing fails, return zero duration
  }
  return Duration.zero;
}