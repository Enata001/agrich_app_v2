import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/network_service.dart' hide networkServiceProvider;


final recentVideosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return videosRepository.getRecentlyWatchedVideos();
  } catch (e) {
    print('Error loading recent videos: $e');
    return [];
  }
});


final allVideosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final networkService = ref.watch(networkServiceProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);


  if (!await networkService.checkConnectivity()) {
    throw NetworkException('Videos require internet connection. Please check your network and try again.');
  }

  try {
    return await videosRepository.getAllVideos().timeout(
      const Duration(seconds: 15),
    );
  } catch (e) {
    if (e is NetworkException) rethrow;
    throw Exception('Failed to load videos. Please check your connection and try again.');
  }
});


final videosByCategoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final networkService = ref.watch(networkServiceProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);

  if (!await networkService.checkConnectivity()) {
    throw NetworkException('Videos require internet connection. Please check your network and try again.');
  }

  try {
    if (category == 'All') {
      return await videosRepository.getAllVideos().timeout(Duration(seconds: 15));
    }
    return await videosRepository.getVideosByCategory(category).timeout(Duration(seconds: 15));
  } catch (e) {
    if (e is NetworkException) rethrow;
    throw Exception('Failed to load videos for category: $category');
  }
});


final popularVideosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final networkService = ref.watch(networkServiceProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);

  if (!await networkService.checkConnectivity()) {
    throw NetworkException('Videos require internet connection. Please check your network and try again.');
  }

  try {
    final allVideos = await videosRepository.getAllVideos();


    final sortedVideos = List<Map<String, dynamic>>.from(allVideos);
    sortedVideos.sort((a, b) {
      final aViews = a['views'] as int? ?? 0;
      final bViews = b['views'] as int? ?? 0;
      final aLikes = a['likes'] as int? ?? 0;
      final bLikes = b['likes'] as int? ?? 0;

      final aScore = aViews + (aLikes * 10);
      final bScore = bViews + (bLikes * 10);

      return bScore.compareTo(aScore);
    });

    return sortedVideos;
  } catch (e) {
    if (e is NetworkException) rethrow;
    throw Exception('Failed to load popular videos');
  }
});


final trendingVideosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final networkService = ref.watch(networkServiceProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);

  if (!await networkService.checkConnectivity()) {
    throw NetworkException('Videos require internet connection. Please check your network and try again.');
  }

  try {
    final allVideos = await videosRepository.getAllVideos();


    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentVideos = allVideos.where((video) {
      final uploadDate = video['uploadDate'] as DateTime? ?? DateTime.now();
      return uploadDate.isAfter(thirtyDaysAgo);
    }).toList();


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
    if (e is NetworkException) rethrow;
    throw Exception('Failed to load trending videos');
  }
});





final userSavedVideosProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final networkService = ref.watch(networkServiceProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);

  if (!await networkService.checkConnectivity()) {
    throw NetworkException('Saved videos require internet connection');
  }

  try {
    return await videosRepository.getUserSavedVideos(userId).timeout(
      const Duration(seconds: 12),
    );
  } catch (e) {
    if (e is NetworkException) rethrow;
    throw Exception('Failed to load saved videos');
  }
});


final userLikedVideosProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final networkService = ref.watch(networkServiceProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);

  if (!await networkService.checkConnectivity()) {
    throw NetworkException('Liked videos require internet connection');
  }

  try {
    return await videosRepository.getUserLikedVideos(userId).timeout(
      const Duration(seconds: 12),
    );
  } catch (e) {
    if (e is NetworkException) rethrow;
    throw Exception('Failed to load liked videos');
  }
});



final searchVideosProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final networkService = ref.watch(networkServiceProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);

  if (!await networkService.checkConnectivity()) {
    throw NetworkException('Search requires internet connection. Please check your network and try again.');
  }

  try {
    return await videosRepository.searchVideos(query).timeout(
      const Duration(seconds: 12),
    );
  } catch (e) {
    if (e is NetworkException) rethrow;
    throw Exception('Failed to search videos for: $query');
  }
});



final videoCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getVideoCategories();
  } catch (e) {

    return ['All', ...AppConfig.videoCategories];
  }
});


final videoStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  final networkService = ref.watch(networkServiceProvider);


  if (!await networkService.checkConnectivity()) {
    return {'totalVideos': 0, 'totalViews': 0, 'totalLikes': 0};
  }
  try {
    final allVideos = await videosRepository.getAllVideos();

    final totalVideos = allVideos.length;
    final totalViews = allVideos.fold<int>(0, (sum, video) => sum + (video['views'] as int? ?? 0));
    final totalLikes = allVideos.fold<int>(0, (sum, video) => sum + (video['likes'] as int? ?? 0));
    final averageViews = totalVideos > 0 ? totalViews / totalVideos : 0.0;


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


final videoDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, videoId) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getVideoDetails(videoId);
  } catch (e) {
    print('Error loading video details for $videoId: $e');
    return null;
  }
});


final savedVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getUserSavedVideos(userId);
  } catch (e) {
    print('Error loading saved videos for user $userId: $e');
    return [];
  }
});


final likedVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  try {
    return await videosRepository.getUserLikedVideos(userId);
  } catch (e) {
    print('Error loading liked videos for user $userId: $e');
    return [];
  }
});


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


class VideoFilterState {
  final String category;
  final String sortBy;
  final String duration;
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


final filteredVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final filter = ref.watch(videoFilterProvider);
  final videosRepository = ref.watch(videosRepositoryProvider);

  try {
    List<Map<String, dynamic>> videos;


    if (filter.category == 'All') {
      videos = await videosRepository.getAllVideos();
    } else {
      videos = await videosRepository.getVideosByCategory(filter.category);
    }


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


    if (filter.showSavedOnly) {
      videos = videos.where((video) => video['isSaved'] == true).toList();
    }


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


final videoActionsProvider = Provider<VideoActions>((ref) {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return VideoActions(videosRepository, ref);
});

class VideoActions {
  final dynamic videosRepository;
  final Ref ref;

  VideoActions(this.videosRepository, this.ref);

  Future<void> likeVideo(String videoId, String userId) async {
    try {
      await videosRepository.likeVideo(videoId, userId);

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

    }
  }

  Future<void> addToWatchHistory(String videoId, String userId) async {
    try {
      await videosRepository.addToWatchHistory(videoId, userId);
      ref.invalidate(recentVideosProvider);
    } catch (e) {
      print('Error adding to watch history: $e');

    }
  }
}


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