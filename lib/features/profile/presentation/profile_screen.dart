import 'package:agrich_app_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_button.dart';


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

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user != null
          ? _buildAuthenticatedProfile(user)
          : _buildUnauthenticatedState(),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildAuthenticatedProfile(dynamic user) {
    final userProfile = ref.watch(currentUserProfileProvider);

    return userProfile.when(
      data: (profile) => profile != null
          ? _buildProfileContent(user, profile)
          : _buildNoProfileState(),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildProfileContent(dynamic user, dynamic profile) {
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(user, profile),

            // Tab Bar
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(user, profile),
                  _buildMyVideosTab(user.uid),
                  _buildSavedPostsTab(user.uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user, dynamic profile) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Picture and Info
            Row(
              children: [
                // Profile Picture
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
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
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: user.photoURL != null
                        ? CachedNetworkImageProvider(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                      user.displayName?.isNotEmpty == true
                          ? user.displayName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    )
                        : null,
                  ),
                ),

                const SizedBox(width: 20),

                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (profile.bio?.isNotEmpty == true) ...[
                        Text(
                          profile.bio!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (profile.location?.isNotEmpty == true) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.location!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Joined ${_formatJoinDate(profile.joinedAt)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Edit Profile',
                onPressed: () => context.push(AppRoutes.editProfile),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                textColor: Colors.white,
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'My Videos'),
          Tab(text: 'Saved Posts'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(dynamic user, dynamic profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Section
          _buildStatsSection(user),

          const SizedBox(height: 30),

          // Quick Actions Section
          _buildQuickActions(),

          const SizedBox(height: 30),

          // Settings Section
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildMyVideosTab(String userId) {
    final userVideos = ref.watch(userVideosProvider(userId));

    return userVideos.when(
      data: (videos) => videos.isNotEmpty
          ? _buildVideosList(videos)
          : _buildEmptyVideosState(),
      loading: () => _buildLoadingContent(),
      error: (error, stack) => _buildErrorContent('Unable to load videos'),
    );
  }

  Widget _buildSavedPostsTab(String userId) {
    final savedPosts = ref.watch(savedPostsProvider(userId));

    return savedPosts.when(
      data: (posts) => posts.isNotEmpty
          ? _buildSavedPostsList(posts)
          : _buildEmptySavedPostsState(),
      loading: () => _buildLoadingContent(),
      error: (error, stack) => _buildErrorContent('Unable to load saved posts'),
    );
  }

  Widget _buildStatsSection(dynamic user) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Text(
              'Your Stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.post_add,
                  value: '12',
                  label: 'Posts',
                  color: AppColors.primaryGreen,
                ),
                _buildStatItem(
                  icon: Icons.play_circle,
                  value: '8',
                  label: 'Videos',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.bookmark,
                  value: '24',
                  label: 'Saved',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.favorite,
                  value: '156',
                  label: 'Likes',
                  color: Colors.red,
                ),
              ],
            ),
          ],
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
    return Expanded(
      child: Column(
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.video_library,
        'label': 'My Videos',
        'color': Colors.purple,
        'onTap': () => _tabController.animateTo(1),
      },
      {
        'icon': Icons.bookmark,
        'label': 'Saved Posts',
        'color': Colors.orange,
        'onTap': () => _tabController.animateTo(2),
      },
      {
        'icon': Icons.edit,
        'label': 'Edit Profile',
        'color': Colors.green,
        'onTap': () => context.push(AppRoutes.editProfile),
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'color': Colors.blue,
        'onTap': () => _showComingSoon('Settings'),
      },
    ];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: actions.map((action) => _buildActionTile(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: action['onTap'] as VoidCallback,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final settings = [
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'subtitle': 'Manage your notification preferences',
        'onTap': () => _showComingSoon('Notifications'),
      },
      {
        'icon': Icons.privacy_tip,
        'title': 'Privacy & Security',
        'subtitle': 'Control your privacy settings',
        'onTap': () => _showComingSoon('Privacy & Security'),
      },
      {
        'icon': Icons.help,
        'title': 'Help & Support',
        'subtitle': 'Get help and contact support',
        'onTap': () => _showComingSoon('Help & Support'),
      },
      {
        'icon': Icons.logout,
        'title': 'Sign Out',
        'subtitle': 'Sign out of your account',
        'onTap': () => _showSignOutDialog(),
      },
    ];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...settings.map((setting) => _buildSettingItem(
              icon: setting['icon'] as IconData,
              title: setting['title'] as String,
              subtitle: setting['subtitle'] as String,
              onTap: setting['onTap'] as VoidCallback,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: title == 'Sign Out' ? Colors.red : AppColors.primaryGreen,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: title == 'Sign Out' ? Colors.red : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildVideosList(List<Map<String, dynamic>> videos) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                child: const Icon(Icons.play_arrow, color: AppColors.primaryGreen),
              ),
            ),
            title: Text(
              video['title'] ?? 'Untitled Video',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${video['views'] ?? 0} views',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // Handle video actions
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedPostsList(List<Map<String, dynamic>> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              child: Text(
                (post['authorName'] as String? ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              post['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'by ${post['authorName'] ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            onTap: () {
              context.push(
                AppRoutes.postDetails,
                extra: {'postId': post['id']},
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyVideosState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
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
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey.shade400,
          ),
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

  Widget _buildLoadingContent() {
    return const Center(
      child: LoadingIndicator(
        size: LoadingSize.medium,
        message: 'Loading...',
      ),
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.red.shade600),
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
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign In Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please sign in to view your profile and access personalized features.',
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

  Widget _buildErrorState(BuildContext context, Object error) {
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
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Unable to load profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your connection and try again.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Retry',
                  onPressed: () {
                    ref.invalidate(currentUserProfileProvider);
                  },
                  backgroundColor: Colors.white,
                  textColor: AppColors.primaryGreen,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoProfileState() {
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
                  Icons.account_circle_outlined,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Profile Not Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your profile information could not be loaded. Please try again.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Retry',
                  onPressed: () {
                    ref.invalidate(currentUserProfileProvider);
                  },
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

  String _formatJoinDate(DateTime? joinDate) {
    if (joinDate == null) return 'Recently';

    final now = DateTime.now();
    final difference = now.difference(joinDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppColors.info,
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
              Navigator.pop(context);
              final authMethods = ref.read(authMethodsProvider);
              await authMethods.signOut();
              if (mounted) {
                context.go(AppRoutes.auth);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}