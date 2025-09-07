import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String? videoId;
  final String? youtubeVideoId;
  final String? description;
  final Map<String, dynamic>? videoData;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    this.videoId,
    this.youtubeVideoId,
    this.description,
    this.videoData,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  YoutubePlayerController? _youtubeController;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool _isYouTubeVideo = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  String? _extractedYouTubeId;

  @override
  void initState() {
    super.initState();
    _determinePlayerType();
    _initializePlayer();
    _trackVideoView();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  void _determinePlayerType() {
    if (widget.youtubeVideoId != null && widget.youtubeVideoId!.isNotEmpty) {
      _isYouTubeVideo = true;
      _extractedYouTubeId = widget.youtubeVideoId;
      return;
    }

    if (_isYouTubeUrl(widget.videoUrl)) {
      _isYouTubeVideo = true;
      _extractedYouTubeId = _extractYouTubeVideoId(widget.videoUrl);
      return;
    }

    if (widget.videoData != null) {
      final data = widget.videoData!;
      if (data['isYouTubeVideo'] == true ||
          data['youtubeVideoId'] != null ||
          data['youtubeUrl'] != null) {
        _isYouTubeVideo = true;
        _extractedYouTubeId =
            data['youtubeVideoId'] ??
            _extractYouTubeVideoId(data['youtubeUrl'] ?? '');
        return;
      }
    }

    _isYouTubeVideo = false;
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('youtube-nocookie.com');
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\.be/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _initializePlayer() async {
    if (_isYouTubeVideo) {
      await _initializeYouTubePlayer();
    } else {
      await _initializeRegularPlayer();
    }
  }

  Future<void> _initializeYouTubePlayer() async {
    try {
      if (_extractedYouTubeId == null || _extractedYouTubeId!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid YouTube video ID';
        });
        return;
      }

      _youtubeController = YoutubePlayerController(
        initialVideoId: _extractedYouTubeId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          loop: false,
          forceHD: false,
          startAt: 0,
        ),
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize YouTube player: $e';
      });
    }
  }

  Future<void> _initializeRegularPlayer() async {
    try {
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL is empty';
        });
        return;
      }

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryGreen,
          handleColor: AppColors.primaryGreen,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: LoadingIndicator(
              size: LoadingSize.large,
              color: Colors.white,
              message: 'Loading video...',
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  void _trackVideoView() {
    if (widget.videoId != null) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.read(videosRepositoryProvider).incrementViewCount(widget.videoId!);

        ref
            .read(videosRepositoryProvider)
            .addToWatchHistory(widget.videoId!, currentUser.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),

            Expanded(flex: 3, child: _buildVideoPlayer()),

            Expanded(flex: 2, child: _buildVideoInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.videoTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _shareVideo(),
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return _buildErrorWidget(_errorMessage);
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    if (_isYouTubeVideo && _youtubeController != null) {
      return _buildYouTubePlayer();
    } else if (!_isYouTubeVideo && _chewieController != null) {
      return _buildRegularPlayer();
    }

    return _buildErrorWidget('Player initialization failed');
  }

  Widget _buildYouTubePlayer() {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      },
      player: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primaryGreen,
        progressColors: ProgressBarColors(
          playedColor: AppColors.primaryGreen,
          handleColor: AppColors.primaryGreen,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
        onReady: () {
          print('YouTube player ready');
        },
        onEnded: (data) {
          print('YouTube video ended');
        },
      ),
      builder: (context, player) {
        return AspectRatio(aspectRatio: 16 / 9, child: player);
      },
    );
  }

  Widget _buildRegularPlayer() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: LoadingIndicator(
          size: LoadingSize.large,
          color: Colors.white,
          message: 'Loading video...',
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withValues(alpha: 0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load video',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializePlayer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.videoTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            _buildVideoMetadata(),

            const SizedBox(height: 16),

            _buildActionButtons(),

            const SizedBox(height: 16),

            if (widget.description != null &&
                widget.description!.isNotEmpty) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoMetadata() {
    final videoData = widget.videoData;
    if (videoData == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.visibility,
          size: 16,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '${videoData['views'] ?? 0} views',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),

        const SizedBox(width: 16),

        Icon(
          Icons.favorite,
          size: 16,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '${videoData['likes'] ?? 0} likes',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),

        const SizedBox(width: 16),

        Icon(
          Icons.access_time,
          size: 16,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          videoData['duration'] ?? '0:00',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),

        const Spacer(),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            videoData['category'] ?? 'General',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final currentUser = ref.watch(currentUserProvider);
    final videoData = widget.videoData;

    if (currentUser == null || videoData == null) {
      return const SizedBox.shrink();
    }

    final isLiked =
        (videoData['likedBy'] as List?)?.contains(currentUser.uid) ?? false;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _toggleLike(),
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 20,
            ),
            label: const Text('Like', style: TextStyle(fontSize: 10)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: isLiked
                  ? AppColors.primaryGreen
                  : Colors.white.withValues(alpha: 0.1),
              foregroundColor: isLiked ? Colors.white : Colors.white,
              side: BorderSide(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _toggleSave(),
            icon: const Icon(Icons.bookmark_border, size: 20),
            label: const Text('Save', style: TextStyle(fontSize: 10)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              side: BorderSide(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareVideo(),
            icon: const Icon(Icons.share, size: 20),
            label: const Text('Share', style: TextStyle(fontSize: 10)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,

              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              side: BorderSide(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleLike() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && widget.videoId != null) {
      ref
          .read(videosRepositoryProvider)
          .likeVideo(widget.videoId!, currentUser.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Video liked!'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _toggleSave() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && widget.videoId != null) {
      ref
          .read(videosRepositoryProvider)
          .saveVideo(widget.videoId!, currentUser.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Video saved!'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _shareVideo() {
    final shareText = _isYouTubeVideo && widget.youtubeVideoId != null
        ? 'Check out this farming video: ${widget.videoTitle}\nhttps://www.youtube.com/watch?v=${widget.youtubeVideoId}'
        : 'Check out this farming video: ${widget.videoTitle}\n${widget.videoUrl}';

    Clipboard.setData(ClipboardData(text: shareText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Video link copied to clipboard'),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
