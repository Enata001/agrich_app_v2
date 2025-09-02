import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

// Recent Videos Provider
final recentVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.getRecentlyWatchedVideos();
});

// Videos by Category Provider
final videosByCategoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.getVideosByCategory(category);
});

// All Videos Provider
final allVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.getAllVideos();
});

final videoCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.getVideoCategories();
});


// Trending Videos Provider
final trendingVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videos = await ref.watch(allVideosProvider.future);

  // Sort by views and recent upload date
  final sortedVideos = List<Map<String, dynamic>>.from(videos);
  sortedVideos.sort((a, b) {
    final aViews = a['views'] as int? ?? 0;
    final bViews = b['views'] as int? ?? 0;
    final aDate = a['uploadDate'] as String? ?? '';
    final bDate = b['uploadDate'] as String? ?? '';

    // Primary sort by views
    final viewComparison = bViews.compareTo(aViews);
    if (viewComparison != 0) return viewComparison;

    // Secondary sort by upload date
    return bDate.compareTo(aDate);
  });

  return sortedVideos.take(10).toList();
});

// Video Player Provider
final videoPlayerProvider = StateNotifierProvider<VideoPlayerNotifier, VideoPlayerState>((ref) {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return VideoPlayerNotifier(videosRepository);
});

class VideoPlayerNotifier extends StateNotifier<VideoPlayerState> {
  final dynamic _videosRepository;

  VideoPlayerNotifier(this._videosRepository) : super(VideoPlayerState.initial());

  Future<void> playVideo(String videoId, String videoUrl) async {
    try {
      state = state.copyWith(
        currentVideoId: videoId,
        currentVideoUrl: videoUrl,
        isPlaying: true,
      );

      // Track video view
      await _trackVideoView(videoId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void pauseVideo() {
    state = state.copyWith(isPlaying: false);
  }

  void resumeVideo() {
    state = state.copyWith(isPlaying: true);
  }

  void stopVideo() {
    state = VideoPlayerState.initial();
  }

  void setPosition(Duration position) {
    state = state.copyWith(position: position);
  }

  void setDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  Future<void> _trackVideoView(String videoId) async {
    try {
      // Track that this video was watched
      // This would typically update analytics or user's watch history
    } catch (e) {
      // Ignore tracking errors
    }
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class VideoPlayerState {
  final String? currentVideoId;
  final String? currentVideoUrl;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? error;

  VideoPlayerState({
    this.currentVideoId,
    this.currentVideoUrl,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  factory VideoPlayerState.initial() => VideoPlayerState();

  VideoPlayerState copyWith({
    String? currentVideoId,
    String? currentVideoUrl,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? error,
  }) {
    return VideoPlayerState(
      currentVideoId: currentVideoId ?? this.currentVideoId,
      currentVideoUrl: currentVideoUrl ?? this.currentVideoUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
    );
  }
}

// Search Videos Provider
final searchVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final videos = await ref.watch(allVideosProvider.future);
  return videos.where((video) {
    final title = (video['title'] as String? ?? '').toLowerCase();
    final description = (video['description'] as String? ?? '').toLowerCase();
    final category = (video['category'] as String? ?? '').toLowerCase();
    final searchQuery = query.toLowerCase();

    return title.contains(searchQuery) ||
        description.contains(searchQuery) ||
        category.contains(searchQuery);
  }).toList();
});

// Popular Videos Provider (based on views)
final popularVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videos = await ref.watch(allVideosProvider.future);

  final sortedVideos = List<Map<String, dynamic>>.from(videos);
  sortedVideos.sort((a, b) {
    final aViews = a['views'] as int? ?? 0;
    final bViews = b['views'] as int? ?? 0;
    return bViews.compareTo(aViews);
  });

  return sortedVideos;
});

// Latest Videos Provider
final latestVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videos = await ref.watch(allVideosProvider.future);

  final sortedVideos = List<Map<String, dynamic>>.from(videos);
  sortedVideos.sort((a, b) {
    final aDate = a['uploadDate'] as String? ?? '';
    final bDate = b['uploadDate'] as String? ?? '';
    return bDate.compareTo(aDate);
  });

  return sortedVideos;
});

// Video Stats Provider
final videoStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final videos = await ref.watch(allVideosProvider.future);

  final totalVideos = videos.length;
  final totalViews = videos.fold<int>(0, (sum, video) => sum + (video['views'] as int? ?? 0));
  final categories = <String, int>{};

  for (final video in videos) {
    final category = video['category'] as String? ?? 'Other';
    categories[category] = (categories[category] ?? 0) + 1;
  }

  return {
    'totalVideos': totalVideos,
    'totalViews': totalViews,
    'averageViews': totalVideos > 0 ? totalViews / totalVideos : 0.0,
    'categoriesCount': categories,
    'mostPopularCategory': categories.entries.isNotEmpty
        ? categories.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None',
  };
});