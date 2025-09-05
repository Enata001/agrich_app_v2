// lib/features/community/presentation/community_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import 'providers/community_provider.dart';
import 'widgets/post_card.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _currentFilter = 'recent';
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final postsAsync = _searchQuery.isNotEmpty
        ? ref.watch(searchPostsProvider(_searchQuery))
        : _currentFilter != 'recent'
        ? ref.watch(filteredPostsProvider(_currentFilter))
        : ref.watch(communityPostsProvider);

    return GradientBackground(
      floatingActionButton: _buildFloatingActionButton(context),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_showSearch) _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: postsAsync.when(
                data: (postsList) => _buildPostsList(context, postsList),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(context, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            if (_showSearch) ...[
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ] else ...[
              const Icon(Icons.people, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Community',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const Spacer(),
            if (!_showSearch) ...[
              IconButton(
                onPressed: () => setState(() => _showSearch = true),
                icon: const Icon(Icons.search, color: Colors.white),
              ),
              IconButton(
                onPressed: () => _showFilterBottomSheet(context),
                icon: const Icon(Icons.tune, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: SafeArea(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search posts...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.2),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.white),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['recent', 'popular', 'trending'];

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = filter == _currentFilter;



            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: Theme(
                data: Theme.of(context).copyWith(canvasColor: Colors.transparent),

                child: FilterChip(
                  label: Text(
                    filter.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryGreen : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentFilter = filter;
                      });
                    }
                  },
                  backgroundColor: Colors.black26.withValues(alpha: 0.05),
                  selectedColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
                  checkmarkColor: Colors.transparent,
                  side: BorderSide(
                    color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, List<dynamic> posts) {
    if (posts.isEmpty) {
      return _buildEmptyState(context);
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshPosts,
          color: AppColors.primaryGreen,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            // Extra bottom padding for FAB
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: PostCard(
                  onLike: () => _likePost(post['id'] ?? ''),
                  onTap: () => _navigateToPostDetails(context, post['id']),
                  onComment: () =>
                      _navigateToPostDetails(context, post['id'] ?? ''),
                  onShare: () => _sharePost(post),
                  onSave: () => _savePost(post['id'] ?? ''),
                  onReport: () => _reportPost(post['id'] ?? ''),
                  post: post,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: LoadingIndicator(
              size: LoadingSize.large,
              message: 'Loading community posts...',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                const SizedBox(height: 24),
                Text(
                  'Unable to load posts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your internet connection and try again.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(communityPostsProvider);
                    if (_currentFilter != 'recent') {
                      ref.invalidate(filteredPostsProvider(_currentFilter));
                    }
                    if (_searchQuery.isNotEmpty) {
                      ref.invalidate(searchPostsProvider(_searchQuery));
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 400),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToCreatePost(context),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
        heroTag: "community_fab", // Unique tag to avoid conflicts
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                  _searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.people_outline,
                  size: 60,
                  color: AppColors.primaryGreen.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty ? 'No results found' : 'No posts yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try searching with different keywords'
                    : 'Be the first to share something with the community!',
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

  void _showFilterBottomSheet(BuildContext context) {
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
                  'Filter Posts',
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
            _buildFilterOption('Recent', 'recent', Icons.access_time),
            _buildFilterOption('Popular', 'popular', Icons.favorite),
            _buildFilterOption('Trending', 'trending', Icons.trending_up),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, String value, IconData icon) {
    final isSelected = _currentFilter == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primaryGreen : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check, color: AppColors.primaryGreen)
            : null,
        onTap: () {
          setState(() {
            _currentFilter = value;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _refreshPosts() async {
    ref.invalidate(communityPostsProvider);
    if (_currentFilter != 'recent') {
      ref.invalidate(filteredPostsProvider(_currentFilter));
    }
    if (_searchQuery.isNotEmpty) {
      ref.invalidate(searchPostsProvider(_searchQuery));
    }
  }

  void _navigateToCreatePost(BuildContext context) {
    context.push(AppRoutes.createPost);
  }

  void _navigateToPostDetails(BuildContext context, String postId) {
    context.push(AppRoutes.postDetails, extra: {'postId': postId});
  }

  Future<void> _likePost(String postId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      await communityRepository.likePost(postId, currentUser.uid);

      // Refresh the relevant provider
      ref.invalidate(communityPostsProvider);
      if (_currentFilter != 'recent') {
        ref.invalidate(filteredPostsProvider(_currentFilter));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to like post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePost(Map<String, dynamic> post) async {
    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      final shareText = await communityRepository.sharePost(post['id']);

      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePost(String postId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      await communityRepository.savePost(postId, currentUser.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reportPost(String postId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final reasons = [
      'Spam or misleading content',
      'Inappropriate language',
      'Harassment or bullying',
      'False information',
      'Copyright violation',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this post?'),
            const SizedBox(height: 16),
            ...reasons.map(
              (reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reason),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(postId, reason);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(String postId, String reason) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      await communityRepository.reportPost(
        postId: postId,
        reporterId: currentUser.uid,
        reason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post reported. Thank you for your feedback.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to report post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
