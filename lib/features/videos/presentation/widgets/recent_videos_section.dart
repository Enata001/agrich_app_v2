import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/network_service.dart'
    hide networkServiceProvider;
import '../../../../core/providers/app_providers.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/video_provider.dart';
import 'video_thumbnail_card.dart';

class RecentVideosSection extends ConsumerWidget {
  const RecentVideosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentVideos = ref.watch(recentVideosProvider);
    final networkStatus = ref.watch(networkStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recently Watched',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // ✅ Show network status for videos
            networkStatus.when(
              data: (isOnline) => isOnline
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OFFLINE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentVideos.when(
          data: (videos) {
            return videos.isEmpty
                ? _buildEmptyState(context)
                : _buildVideosList(context, ref, videos);
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context),
        ),
      ],
    );
  }

  Widget _buildVideosList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> videos,
  ) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length > 5 ? 5 : videos.length,
        // Show max 5 videos
        itemBuilder: (context, index) {
          final video = videos[index];
          return VideoThumbnailCard(
            video: video,
            // width: 340,
            onTap: () => _playVideo(context, ref, video),
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            Padding(padding: const EdgeInsets.only(right: 20)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.6),
            Colors.grey.withValues(alpha: 0.2),
            AppColors.primaryGreen.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No videos watched yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start watching videos to see them here',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(child: LoadingIndicator()),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Error loading recent videos',
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Play video with network check
  void _playVideo(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> video,
  ) async {
    final networkService = ref.read(networkServiceProvider);
    final isConnected = await networkService.checkConnectivity();

    if (!isConnected) {
      // Show network error for videos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Videos require internet connection. Please check your network.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final videoId = video['id'] as String;

    // ✅ Mark as watched again (updates watch order)
    final localStorage = ref.read(localStorageServiceProvider);
    final userData = localStorage.getUserData();
    if (userData != null) {
      final userId = userData['id'] as String;
      await ref
          .read(videosRepositoryProvider)
          .markVideoAsWatched(videoId, userId);

      // Refresh the recent videos list
      ref.invalidate(recentVideosProvider);
    }

    // Determine if it's a YouTube video
    final isYouTubeVideo =
        video['isYouTubeVideo'] == true ||
        video['youtubeVideoId'] != null ||
        video['youtubeUrl'] != null;

    // Navigate to video player with all necessary data
    context.push(
      '/video-player/$videoId',
      extra: {
        'videoId': videoId,
        'videoUrl': video['videoUrl'] ?? '',
        'youtubeVideoId': video['youtubeVideoId'],
        'youtubeUrl': video['youtubeUrl'],
        'embedUrl': video['embedUrl'],
        'videoTitle': video['title'] ?? 'Video',
        'description': video['description'] ?? '',
        'category': video['category'] ?? '',
        'duration': video['duration'] ?? '0:00',
        'views': video['views'] ?? 0,
        'likes': video['likes'] ?? 0,
        'likedBy': video['likedBy'] ?? [],
        'authorName': video['authorName'] ?? '',
        'authorId': video['authorId'] ?? '',
        'authorAvatar': video['authorAvatar'],
        'uploadDate': video['uploadDate'],
        'thumbnailUrl': video['thumbnailUrl'] ?? '',
        'isYouTubeVideo': isYouTubeVideo,
        'commentsCount': video['commentsCount'] ?? 0,
        'isActive': video['isActive'] ?? true,
      },
    );
  }
}
