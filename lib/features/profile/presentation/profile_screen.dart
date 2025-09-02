import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
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
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentUser = ref.watch(currentUserProvider);
    final userProfile = currentUser != null
        ? ref.watch(currentUserProfileProvider)
        : const AsyncValue<dynamic>.data(null);

    return GradientBackground(
      child: SafeArea(
        child: currentUser == null
            ? _buildSignedOutState(context)
            : userProfile.when(
          data: (profile) => _buildProfileContent(context, currentUser, profile),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, dynamic user, dynamic profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: _buildProfileHeader(context, user, profile),
          ),

          const SizedBox(height: 30),

          // Stats Section
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: _buildStatsSection(context, profile),
          ),

          const SizedBox(height: 30),

          // Quick Actions
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
            child: _buildQuickActions(context),
          ),

          const SizedBox(height: 30),

          // Settings Section
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 600),
            child: _buildSettingsSection(context),
          ),

          const SizedBox(height: 30),

          // Sign Out Button
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 800),
            child: _buildSignOutButton(context),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, dynamic profile) {
    final username = profile?.username ?? user?.displayName ?? 'User';
    final email = profile?.email ?? user?.email ?? '';
    final bio = profile?.bio ?? '';
    final location = profile?.location ?? '';
    final profilePicture = profile?.profilePictureUrl ?? user?.photoURL ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                backgroundImage: profilePicture.isNotEmpty
                    ? CachedNetworkImageProvider(profilePicture)
                    : null,
                child: profilePicture.isEmpty
                    ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Username
          Text(
            username,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Email
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),

          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Edit Profile Button
          CustomButton(
            text: 'Edit Profile',
            onPressed: () => context.push(AppRoutes.editProfile),
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
            textColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, dynamic profile) {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.article,
            label: 'Posts',
            value: '12', // TODO: Get actual post count
            color: AppColors.primaryGreen,
          ),
          _buildStatItem(
            context,
            icon: Icons.people,
            label: 'Following',
            value: '45', // TODO: Get actual following count
            color: Colors.blue,
          ),
          _buildStatItem(
            context,
            icon: Icons.favorite,
            label: 'Likes',
            value: '128', // TODO: Get actual likes count
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.video_library,
        'label': 'My Videos',
        'color': Colors.purple,
        'onTap': () {
          // TODO: Navigate to user's videos
          _showComingSoon(context, 'My Videos');
        },
      },
      {
        'icon': Icons.bookmark,
        'label': 'Saved',
        'color': Colors.orange,
        'onTap': () {
          // TODO: Navigate to saved posts
          _showComingSoon(context, 'Saved Posts');
        },
      },
      {
        'icon': Icons.history,
        'label': 'Activity',
        'color': Colors.green,
        'onTap': () {
          // TODO: Navigate to activity history
          _showComingSoon(context, 'Activity History');
        },
      },
      {
        'icon': Icons.analytics,
        'label': 'Analytics',
        'color': Colors.blue,
        'onTap': () {
          // TODO: Navigate to profile analytics
          _showComingSoon(context, 'Profile Analytics');
        },
      },
    ];

    return Container(
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return GestureDetector(
                onTap: action['onTap'] as VoidCallback,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (action['color'] as Color).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          action['label'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: action['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final settings = [
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'subtitle': 'Manage your notification preferences',
        'onTap': () => _showComingSoon(context, 'Notifications'),
      },
      {
        'icon': Icons.privacy_tip,
        'title': 'Privacy & Security',
        'subtitle': 'Control your privacy settings',
        'onTap': () => _showComingSoon(context, 'Privacy & Security'),
      },
      {
        'icon': Icons.dark_mode,
        'title': 'Appearance',
        'subtitle': 'Theme and display options',
        'onTap': () => _showComingSoon(context, 'Appearance'),
      },
      {
        'icon': Icons.help,
        'title': 'Help & Support',
        'subtitle': 'Get help and contact support',
        'onTap': () => _showComingSoon(context, 'Help & Support'),
      },
      {
        'icon': Icons.info,
        'title': 'About',
        'subtitle': 'App version and information',
        'onTap': () => _showAboutDialog(context),
      },
    ];

    return Container(
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
            context,
            icon: setting['icon'] as IconData,
            title: setting['title'] as String,
            subtitle: setting['subtitle'] as String,
            onTap: setting['onTap'] as VoidCallback,
          )),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, {
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
        child: Icon(icon, color: AppColors.primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return CustomButton(
      text: 'Sign Out',
      onPressed: () => _showSignOutDialog(context),
      backgroundColor: Colors.red.shade50,
      textColor: Colors.red,
      icon: Icon(Icons.logout),
    );
  }

  Widget _buildSignedOutState(BuildContext context) {
    return Center(
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
                'Sign In Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please sign in to view your profile and access all features.',
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
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: LoadingIndicator(
        size: LoadingSize.large,
        color: Colors.white,
        message: 'Loading profile...',
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
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
                icon: Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Agrich 2.0'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${AppConfig.appVersion}'),
            const SizedBox(height: 8),
            const Text('A modern agricultural community platform for farmers and agricultural enthusiasts.'),
            const SizedBox(height: 16),
            const Text('Features:'),
            const Text('• Community discussions'),
            const Text('• Educational videos'),
            const Text('• Weather updates'),
            const Text('• Agricultural tips'),
            const Text('• Direct messaging'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
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
              try {
                await ref.read(authRepositoryProvider).signOut();
                if (mounted) {
                  context.go(AppRoutes.auth);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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