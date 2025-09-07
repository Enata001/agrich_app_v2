import 'package:agrich_app_v2/features/videos/presentation/widgets/video_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/models/user_model.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/custom_input_field.dart';
import 'providers/video_provider.dart';
import 'widgets/video_card.dart';

class VideosMainScreen extends ConsumerStatefulWidget {
  const VideosMainScreen({super.key});

  @override
  ConsumerState<VideosMainScreen> createState() => _VideosMainScreenState();
}

class _VideosMainScreenState extends ConsumerState<VideosMainScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  String _selectedCategory = 'All';
  String _selectedFilter = 'recent'; // recent, popular, trending
  String _searchQuery = '';
  bool _showSearch = false;
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    );

    _scrollController.addListener(_onScroll);
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final shouldHideHeader = offset > 100;

    if (shouldHideHeader && _isHeaderVisible) {
      setState(() => _isHeaderVisible = false);
      _headerAnimationController.reverse();
    } else if (!shouldHideHeader && !_isHeaderVisible) {
      setState(() => _isHeaderVisible = true);
      _headerAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final videosAsync = _getVideosAsync();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Animated Header
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_headerAnimation),
                child: _buildHeader(context),
              ),

              // Search Bar (when active)
              if (_showSearch) _buildSearchBar(),



              // Category Filter
              _buildCategoryFilter(),

              // Sort Filter
              _buildSortFilter(),

              // Videos List
              Expanded(child: _buildVideosList(videosAsync)),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm Videos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Learn farming techniques',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _showSearch = !_showSearch),
              icon: Icon(
                _showSearch ? Icons.close : Icons.search,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => _showFilterMenu(),
              icon: const Icon(Icons.tune, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: CustomInputField(
          controller: _searchController,
          hint: 'Search videos...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          onChanged: (value) {
            setState(() => _searchQuery = value.toLowerCase());
            ref.invalidate(searchVideosProvider);
          },
        ),
      ),
    );
  }


  Widget _buildCategoryFilter() {
    final categories = ['All', ...AppConfig.videoCategories];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortFilter() {
    final filters = [
      {'key': 'recent', 'label': 'Recent', 'icon': Icons.access_time},
      {'key': 'popular', 'label': 'Popular', 'icon': Icons.trending_up},
      {'key': 'trending', 'label': 'Trending', 'icon': Icons.whatshot},
    ];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: filters.map((filter) {
                final isSelected = _selectedFilter == filter['key'];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _selectedFilter = filter['key'] as String,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              filter['icon'] as IconData,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filter['label'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosList(AsyncValue<List<Map<String, dynamic>>> videosAsync) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: videosAsync.when(
        data: (videos) {
          final filteredVideos = _filterVideos(videos);

          if (filteredVideos.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => _refreshVideos(),
            color: AppColors.primaryGreen,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: filteredVideos.length,
              itemBuilder: (context, index) {
                final video = filteredVideos[index];
                return FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  delay: Duration(milliseconds: index * 50),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: VideoCard(
                      video: video,
                      onTap: () => _playVideo(video),
                      onLike: () => _toggleLikeVideo(video),
                      onSave: () => _toggleSaveVideo(video),
                      onShare: () => _shareVideo(video),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  _searchQuery.isNotEmpty || _selectedCategory != 'All'
                      ? Icons.search_off
                      : Icons.play_circle_outline,
                  size: 60,
                  color: AppColors.primaryGreen.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No videos found'
                    : _selectedCategory != 'All'
                    ? 'No videos in this category'
                    : 'No videos available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try searching with different keywords'
                    : 'Check back later for new farming videos',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: const VideoCardShimmer(),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'Unable to load videos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your connection and try again',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _refreshVideos(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 600),
      child: FloatingActionButton(
        onPressed: () => _scrollToTop(),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
      ),
    );
  }

  // Helper Methods
  AsyncValue<List<Map<String, dynamic>>> _getVideosAsync() {
    if (_searchQuery.isNotEmpty) {
      return ref.watch(searchVideosProvider(_searchQuery));
    }

    switch (_selectedFilter) {
      case 'popular':
        return ref.watch(popularVideosProvider);
      case 'trending':
        return ref.watch(trendingVideosProvider);
      case 'recent':
      default:
        return _selectedCategory == 'All'
            ? ref.watch(allVideosProvider)
            : ref.watch(videosByCategoryProvider(_selectedCategory));
    }
  }

  List<Map<String, dynamic>> _filterVideos(List<Map<String, dynamic>> videos) {
    List<Map<String, dynamic>> filtered = videos;

    // Filter by category if not 'All'
    if (_selectedCategory != 'All') {
      filtered = filtered.where((video) {
        final category = video['category'] as String? ?? '';
        return category == _selectedCategory;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((video) {
        final title = (video['title'] as String? ?? '').toLowerCase();
        final description = (video['description'] as String? ?? '')
            .toLowerCase();
        final category = (video['category'] as String? ?? '').toLowerCase();

        return title.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            category.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  Future<void> _refreshVideos() async {
    ref.invalidate(allVideosProvider);
    ref.invalidate(popularVideosProvider);
    ref.invalidate(trendingVideosProvider);
    ref.invalidate(videosByCategoryProvider);
    ref.invalidate(videoStatsProvider);
    await Future.delayed(const Duration(seconds: 1));
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _playVideo(Map<String, dynamic> video){
    final videoId = video['id'] as String;

    // Track video as watched
    final currentUser =UserModel.fromMap(ref.read(localStorageServiceProvider).getUserData()!);
    ref.read(videosRepositoryProvider).markVideoAsWatched(videoId, currentUser.id);

    // Determine if it's a YouTube video
    final isYouTubeVideo = video['isYouTubeVideo'] == true ||
        video['youtubeVideoId'] != null ||
        video['youtubeUrl'] != null;

    // Navigate to video player with all necessary data
    context.push('/video-player/$videoId', extra: {
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
    });
  }

  void _toggleLikeVideo(Map<String, dynamic> video) {
    final videoId = video['id'] as String;
    // Track video as watched
    final currentUser =UserModel.fromMap(ref.read(localStorageServiceProvider).getUserData()!);
    ref.read(videosRepositoryProvider).likeVideo(videoId, currentUser.id);
  }

  void _toggleSaveVideo(Map<String, dynamic> video) {
    final videoId = video['id'] as String;
    final currentUser =UserModel.fromMap(ref.read(localStorageServiceProvider).getUserData()!);
    ref.read(videosRepositoryProvider).saveVideo(videoId, currentUser.id);
  }

  void _shareVideo(Map<String, dynamic> video) {
    final videoTitle = video['title'] as String? ?? 'Farming Video';
    final videoId = video['id'] as String;
    // Share.share('Check out this farming video: $videoTitle\nhttps://agrich.app/videos/$videoId');
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  'Filter Videos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sort options
            Text(
              'Sort by',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildFilterOption('Recent', 'recent', Icons.access_time),
            _buildFilterOption('Popular', 'popular', Icons.trending_up),
            _buildFilterOption('Trending', 'trending', Icons.whatshot),
            const SizedBox(height: 20),
            Text(
              'Category',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', ...AppConfig.videoCategories].map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: AppColors.primaryGreen, width: 1)
                          : null,
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, String value, IconData icon) {
    final isSelected = _selectedFilter == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primaryGreen : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check, color: AppColors.primaryGreen)
            : null,
        onTap: () {
          setState(() => _selectedFilter = value);
          Navigator.pop(context);
        },
      ),
    );
  }
}
