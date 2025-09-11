import 'package:agrich_app_v2/features/auth/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_button.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = ref.watch(currentUserProfileProvider);
    final offline = UserModel.fromMap(
      ref.watch(localStorageServiceProvider).getUserData() ?? {},
    );

    return user.when(
      data: (user) {
        print(user);
        return user != null
          ? _buildAuthenticatedProfile(user)
          : _buildUnauthenticatedState();
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildAuthenticatedProfile(offline),
    );
  }

  Widget _buildAuthenticatedProfile(UserModel user) {
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildSimplifiedHeader(user),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    _buildCoreStats(user.id), // FIXED: Pass user ID
                    _buildMinimalActions(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMyPostsTab(user.id), // FIXED: Pass user ID
                          _buildMyVideosTab(user.id), // FIXED: Pass user ID
                          _buildSavedPostsTab(user.id), // FIXED: Pass user ID
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedHeader(UserModel user) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                backgroundImage: user.profilePictureUrl != null
                    ? CachedNetworkImageProvider(user.profilePictureUrl!)
                    : null,
                child: user.profilePictureUrl == null
                    ? Text(
                  user.username.isNotEmpty
                      ? user.username.substring(0, 1).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                )
                    : null,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (user.username != user.username) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],

                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.bio!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Verification Status
                  Row(
                    children: [
                      Icon(
                        user.isEmailVerified ? Icons.verified : Icons.pending,
                        color: user.isEmailVerified ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isEmailVerified
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.isEmailVerified ? 'Verified' : 'Unverified',
                          style: TextStyle(
                            color: user.isEmailVerified
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Build stats with real data
  Widget _buildCoreStats(String userId) {
    final userStatsAsync = ref.watch(userStatsProvider(userId));

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: userStatsAsync.when(
          data: (stats) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.article,
                value: stats['postsCount'].toString(),
                label: 'Posts',
                color: AppColors.primaryGreen,
              ),
              _buildStatItem(
                icon: Icons.video_library,
                value: stats['videosCount'].toString(),
                label: 'Videos',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.bookmark,
                value: stats['totalSaved'].toString(),
                label: 'Saved',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.favorite,
                value: stats['totalLikes'].toString(),
                label: 'Likes',
                color: Colors.red,
              ),
            ],
          ),
          loading: () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.article,
                value: '...',
                label: 'Posts',
                color: AppColors.primaryGreen,
              ),
              _buildStatItem(
                icon: Icons.video_library,
                value: '...',
                label: 'Videos',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.bookmark,
                value: '...',
                label: 'Saved',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.favorite,
                value: '...',
                label: 'Likes',
                color: Colors.red,
              ),
            ],
          ),
          error: (error, stack) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.article,
                value: '0',
                label: 'Posts',
                color: AppColors.primaryGreen,
              ),
              _buildStatItem(
                icon: Icons.video_library,
                value: '0',
                label: 'Videos',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.bookmark,
                value: '0',
                label: 'Saved',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.favorite,
                value: '0',
                label: 'Likes',
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalActions() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Edit Profile',
                onPressed: () => context.push(AppRoutes.editProfile),
                backgroundColor: AppColors.primaryGreen,
                textColor: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _showSettingsBottomSheet(),
                icon: const Icon(Icons.settings, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(25),
          ),
          labelColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'My Posts'),
            Tab(text: 'Videos'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
    );
  }

  // FIXED: Build tabs with real data
  Widget _buildMyPostsTab(String userId) {
    final userPostsAsync = ref.watch(userPostsProvider(userId));

    return userPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _buildEmptyPostsState();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(post);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorState('Failed to load posts'),
    );
  }

  Widget _buildMyVideosTab(String userId) {
    final userVideosAsync = ref.watch(userVideosProvider(userId));

    return userVideosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return _buildEmptyVideosState();
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 16/9,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return _buildVideoCard(video);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorState('Failed to load videos'),
    );
  }

  Widget _buildSavedPostsTab(String userId) {
    final savedPostsAsync = ref.watch(savedPostsProvider(userId));

    return savedPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _buildEmptySavedPostsState();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(post);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorState('Failed to load saved posts'),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['content'] ?? '',
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text('${post['likesCount'] ?? 0}'),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text('${post['commentsCount'] ?? 0}'),
                const Spacer(),
                Text(
                  _formatDate(post['createdAt']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[200],
                image: video['thumbnailUrl'] != null
                    ? DecorationImage(
                  image: CachedNetworkImageProvider(video['thumbnailUrl']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: video['thumbnailUrl'] == null
                  ? const Center(
                child: Icon(Icons.video_library, size: 40, color: Colors.grey),
              )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.visibility, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(
                      '${video['views'] ?? 0}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPostsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your first farming experience',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVideosState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No videos yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first farming video',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySavedPostsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No saved posts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save posts to view them here later',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Refresh the providers
              ref.invalidate(userStatsProvider);
              ref.invalidate(userPostsProvider);
              ref.invalidate(userVideosProvider);
              ref.invalidate(savedPostsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedState() {
    return GradientBackground(
      child: Center(
        child: FadeIn(
          duration: const Duration(milliseconds: 800),
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Agrich',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to access your profile, save content, and connect with the farming community.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Sign In',
                  onPressed: () => context.push(AppRoutes.auth),
                  backgroundColor: Colors.white,
                  textColor: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GradientBackground(
      child: const Center(
        child: LoadingIndicator(
          size: LoadingSize.large,
          color: Colors.white,
          message: 'Loading profile...',
        ),
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      // isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 170,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            ListTile(

              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out'),
              onTap: () => _showSignOutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet

              final authRepository = ref.read(authRepositoryProvider);
              await authRepository.signOut();

              if (mounted) {
                context.go(AppRoutes.auth);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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