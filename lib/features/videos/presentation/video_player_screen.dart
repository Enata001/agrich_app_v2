import 'package:agrich_app_v2/features/videos/presentation/providers/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/data/models/user_model.dart';
import '../../shared/widgets/loading_indicator.dart';

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

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with TickerProviderStateMixin {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;

  bool _isYouTubeVideo = false;
  bool _isVideoReady = false;
  bool _isFullScreen = false;
  bool _hasMarkedAsWatched = false;
  bool _showControls = true;
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isLoading = true;

  Map<String, dynamic>? _currentVideo;
  String? _videoUrl;
  String? _youtubeVideoId;

  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeVideo();
  }

  void _setupAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    );
    _controlsAnimationController.forward();
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() => _isLoading = true);

      _markVideoAsWatched();

      if (widget.videoData != null) {
        _currentVideo = widget.videoData!;
      } else {
        final videoRepository = ref.read(videosRepositoryProvider);
        _currentVideo = await videoRepository.getVideoDetails(widget.videoId!);
      }

      if (_currentVideo == null) {
        _showErrorDialog('Video not found');
        return;
      }

      _isYouTubeVideo = _currentVideo!['isYouTubeVideo'] == true;

      if (_isYouTubeVideo) {
        _youtubeVideoId = _currentVideo!['youtubeVideoId'];
        await _initializeYouTubePlayer();
      } else {
        _videoUrl = _currentVideo!['videoUrl'];
        await _initializeVideoPlayer();
      }

      // Check like and save status
      await _checkVideoStatus();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing video: $e');
      _showErrorDialog('Failed to load video');
    }
  }

  Future<void> _initializeYouTubePlayer() async {
    if (_youtubeVideoId == null) return;

    _youtubeController = YoutubePlayerController(
      initialVideoId: _youtubeVideoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'en',
        showLiveFullscreenButton: true,
      ),
    );

    _youtubeController!.addListener(_youtubePlayerListener);
    setState(() => _isVideoReady = true);
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoUrl == null) return;

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
      await _videoController!.initialize();
      _videoController!.addListener(_videoPlayerListener);
      setState(() => _isVideoReady = true);
      _videoController!.play();
    } catch (e) {
      print('Error initializing video player: $e');
      _showErrorDialog('Failed to load video');
    }
  }

  void _youtubePlayerListener() {
    if (_youtubeController?.value.isReady == true && !_hasMarkedAsWatched) {
      _markVideoAsWatched();
    }
  }

  void _videoPlayerListener() {
    if (_videoController?.value.isInitialized == true && !_hasMarkedAsWatched) {
      _markVideoAsWatched();
    }
  }

  Future<void> _markVideoAsWatched() async {
    if (_hasMarkedAsWatched || _currentVideo == null) return;

    try {
      final currentUser = UserModel.fromMap(
        ref.read(localStorageServiceProvider).getUserData() ?? {},
      );

      if (currentUser.id.isNotEmpty) {
        final videoRepository = ref.read(videosRepositoryProvider);
        await videoRepository.markVideoAsWatched(widget.videoId!, currentUser.id);
        _hasMarkedAsWatched = true;
        ref.invalidate(recentVideosProvider);
        print('Video marked as watched successfully');
      }
    } catch (e) {
      print('Error marking video as watched: $e');
    }
  }

  Future<void> _checkVideoStatus() async {
    if (_currentVideo == null) return;

    try {
      final currentUser = UserModel.fromMap(
        ref.read(localStorageServiceProvider).getUserData() ?? {},
      );

      if (currentUser.id.isNotEmpty) {
        final videoRepository = ref.read(videosRepositoryProvider);
        final liked = await videoRepository.isVideoLiked(widget.videoId!, currentUser.id);
        final saved = await videoRepository.isVideoSaved(widget.videoId!, currentUser.id);

        setState(() {
          _isLiked = liked;
          _isSaved = saved;
        });
      }
    } catch (e) {
      print('Error checking video status: $e');
    }
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);

    if (_isFullScreen) {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);

    if (_showControls) {
      _controlsAnimationController.forward();
      // Auto-hide controls after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          _toggleControls();
        }
      });
    } else {
      _controlsAnimationController.reverse();
    }
  }

  Future<void> _toggleLike() async {
    try {
      final currentUser = UserModel.fromMap(
        ref.read(localStorageServiceProvider).getUserData() ?? {},
      );

      if (currentUser.id.isEmpty) {
        _showLoginDialog();
        return;
      }

      setState(() => _isLiked = !_isLiked);

      final videoRepository = ref.read(videosRepositoryProvider);
      await videoRepository.likeVideo(widget.videoId!, currentUser.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLiked ? 'Video liked!' : 'Video unliked!'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error toggling like: $e');
      setState(() => _isLiked = !_isLiked); // Revert on error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update like status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleSave() async {
    try {
      final currentUser = UserModel.fromMap(
        ref.read(localStorageServiceProvider).getUserData() ?? {},
      );

      if (currentUser.id.isEmpty) {
        _showLoginDialog();
        return;
      }

      setState(() => _isSaved = !_isSaved);

      final videoRepository = ref.read(videosRepositoryProvider);
      await videoRepository.saveVideo(widget.videoId!, currentUser.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Video saved!' : 'Video removed from saved!'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error toggling save: $e');
      setState(() => _isSaved = !_isSaved); // Revert on error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update save status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to like and save videos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/auth');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _youtubeController?.dispose();
    _videoController?.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: LoadingIndicator(),
        ),
      );
    }

    if (_currentVideo == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'Video not found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result){
        if (_isFullScreen) {
          _toggleFullScreen();
          // return false;
        }
        // return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isFullScreen ? _buildFullScreenPlayer() : _buildNormalPlayer(),
      ),
    );
  }

  Widget _buildFullScreenPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: SizedBox.expand( // ⬅️ ensures full width + height
        child: Stack(
          children: [
            Center(child: _buildVideoPlayer()),
            if (_showControls) _buildFullScreenControls(),
          ],
        ),
      ),
    );
  }


  Widget _buildNormalPlayer() {
    return SafeArea(
      child: Column(
        children: [
          // Video Player
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.black,
            child: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  Center(child: _buildVideoPlayer()),
                  if (_showControls) _buildVideoControls(),
                ],
              ),
            ),
          ),

          // Video Info
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVideoInfo(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildVideoDescription(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoReady) {
      return const Center(
        child: LoadingIndicator(),
      );
    }

    if (_isYouTubeVideo && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primaryGreen,
        progressColors: ProgressBarColors(
          playedColor: AppColors.primaryGreen,
          handleColor: AppColors.primaryGreen,
        ),
      );
    } else if (_videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }

    return const Center(
      child: Text(
        'Unable to load video',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildVideoControls() {
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _controlsAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Column(
              children: [
                // Top controls
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleFullScreen,
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom controls
                if (!_isYouTubeVideo && _videoController != null)
                  _buildCustomVideoControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullScreenControls() {
    return Stack(
      children: [
        // always visible top bar
        SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: _toggleFullScreen,
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  _toggleFullScreen();
                  context.pop();
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),

        // fading controls (play, scrub bar, etc.)
        AnimatedBuilder(
          animation: _controlsAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _controlsAnimation.value,
              child: Column(
                children: [
                  const Spacer(),
                  if (!_isYouTubeVideo && _videoController != null)
                    _buildCustomVideoControls(),
                ],
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildCustomVideoControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: AppColors.primaryGreen,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),

          // Play/Pause and time
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                  setState(() {});
                },
                icon: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              Text(
                _formatDuration(_videoController!.value.position),
                style: const TextStyle(color: Colors.white),
              ),
              const Text(' / ', style: TextStyle(color: Colors.white)),
              Text(
                _formatDuration(_videoController!.value.duration),
                style: const TextStyle(color: Colors.white),
              ),

              const Spacer(),

              // Volume control
              IconButton(
                onPressed: () {
                  _videoController!.setVolume(
                    _videoController!.value.volume > 0 ? 0.0 : 1.0,
                  );
                  setState(() {});
                },
                icon: Icon(
                  _videoController!.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Text(
            _currentVideo!['title'] ?? '',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 8),

        FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 100),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentVideo!['category'] ?? '',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_currentVideo!['views'] ?? 0} views',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),

              const SizedBox(width: 12),

              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _currentVideo!['duration'] ?? '0:00',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 200),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryGreen,
                child: Text(
                  (_currentVideo!['authorName'] ?? 'A').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                _currentVideo!['authorName'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              Text(
                _formatDate(_currentVideo!['createdAt']),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 300),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleLike,
              icon: Icon(
                _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 20,
              ),
              label: Text(_isLiked ? 'Liked' : 'Like'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLiked ? AppColors.primaryGreen : Colors.grey[100],
                foregroundColor: _isLiked ? Colors.white : Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleSave,
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                size: 20,
              ),
              label: Text(_isSaved ? 'Saved' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaved ? Colors.orange : Colors.grey[100],
                foregroundColor: _isSaved ? Colors.white : Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                final shareUrl = _isYouTubeVideo
                    ? "https://www.youtube.com/watch?v=$_youtubeVideoId"
                    : (_videoUrl ?? "");

                if (shareUrl.isNotEmpty) {
                  SharePlus.instance.share(
                    ShareParams(
                      text:   "🎬 Check out this video: $shareUrl",
                      title: _currentVideo?['title'] ?? 'Video',
                    )

                  );
                }
              },
              icon: const Icon(Icons.share, size: 20),
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoDescription() {
    final description = _currentVideo!['description'] ?? '';
    if (description.isEmpty) return const SizedBox.shrink();

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}