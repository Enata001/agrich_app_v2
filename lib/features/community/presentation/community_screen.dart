import 'package:agrich_app_v2/features/community/presentation/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/gradient_background.dart';
import 'providers/community_provider.dart';

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final posts = ref.watch(communityPostsProvider);

    return GradientBackground(
      floatingActionButton: _buildFloatingActionButton(context),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: posts.when(
                data: (postsList) => _buildPostsList(context, postsList),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(context),
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
            Icon(
              Icons.people,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Community',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showSearchDialog(context),
              icon: const Icon(
                Icons.search,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => _showFilterDialog(context),
              icon: const Icon(
                Icons.filter_list,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, List<Map<String, dynamic>> posts) {
    if (posts.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(communityPostsProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      color: AppColors.primaryGreen,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: Duration(milliseconds: index * 100),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: PostCard(
                post: post,
                onTap: () => _navigateToPostDetails(context, post['id'] ?? ''),
                onLike: () => _likePost(post['id'] ?? ''),
                onComment: () => _navigateToPostDetails(context, post['id'] ?? ''),
                onShare: () => _sharePost(post),
              ),
            ),
          );
        },
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
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 60,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No posts yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Be the first to share something with the community!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _navigateToCreatePost(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Create First Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: index * 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: const PostShimmer(),
          ),
        );
      },
    );
  }

  // FIXED: Add missing _buildErrorState method
  Widget _buildErrorState(BuildContext context) {
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
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load posts. Please check your internet connection and try again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(communityPostsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
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
      ),
    );
  }

  void _navigateToCreatePost(BuildContext context) {
    context.push(AppRoutes.createPost);
  }

  void _navigateToPostDetails(BuildContext context, String postId) {
    context.push(
      AppRoutes.postDetails,
      extra: {'postId': postId},
    );
  }

  void _likePost(String postId) {
    ref.read(communityRepositoryProvider).likePost(postId);
    ref.invalidate(communityPostsProvider);
  }

  void _sharePost(Map<String, dynamic> post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Posts'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            _performSearch(query);
          },
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Posts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Recent'),
              onTap: () {
                Navigator.pop(context);
                _applyFilter('recent');
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Popular'),
              onTap: () {
                Navigator.pop(context);
                _applyFilter('popular');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Most Liked'),
              onTap: () {
                Navigator.pop(context);
                _applyFilter('most_liked');
              },
            ),
            ListTile(
              leading: const Icon(Icons.comment),
              title: const Text('Most Comments'),
              onTap: () {
                Navigator.pop(context);
                _applyFilter('most_comments');
              },
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

  void _performSearch(String query) {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for: $query'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _applyFilter(String filterType) {
    // TODO: Implement filter functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filter applied: $filterType'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// Shimmer widget for loading state
class PostShimmer extends StatelessWidget {
  const PostShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              ShimmerBox(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          ShimmerBox(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          ShimmerBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),

          // Image placeholder
          ShimmerBox(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _animation.value, 0.0),
              end: Alignment(1.0 - _animation.value, 0.0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}