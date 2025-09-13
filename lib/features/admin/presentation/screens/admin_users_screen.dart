
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/config/utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_input_field.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_user_details_dialog.dart';
import '../widgets/admin_action_dialog.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Update filter based on selected tab
        final filters = [
          UserFilterType.all,
          UserFilterType.active,
          UserFilterType.suspended,
          UserFilterType.unverified,
        ];
        ref.read(userFilterProvider.notifier).state = filters[_tabController.index];
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final isTablet = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Search and Filters
          _buildSearchAndFilters(context),

          // Users List
          Expanded(
            child: usersAsync.when(
              data: (users) => users.isEmpty
                  ? _buildEmptyState(context)
                  : _buildUsersList(context, users, isTablet),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final userCount = usersAsync.whenOrNull(data: (users) => users.length) ?? 0;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '$userCount users',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Refresh button
        IconButton(
          onPressed: () => ref.invalidate(adminUsersProvider),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        // Export button
        IconButton(
          onPressed: _showExportOptions,
          icon: const Icon(Icons.download),
          tooltip: 'Export',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
          children: [
      // Search Bar
      Padding(
      padding: const EdgeInsets.all(16),
      child: CustomInputField(
        controller: _searchController,
        hint: 'Search users by name, email, or phone...',
        prefixIcon: Icon(Icons.search),
        onChanged: (value) {
          ref.read(userSearchQueryProvider.notifier).state = value;
        },
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          onPressed: () {
            _searchController.clear();
            ref.read(userSearchQueryProvider.notifier).state = '';
          },
          icon: const Icon(Icons.clear),
        )
            : null,
      ),
    ),

    // Filter Tabs
            TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primaryGreen,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All Users'),
                Tab(text: 'Active'),
                Tab(text: 'Suspended'),
                Tab(text: 'Unverified'),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, List<AdminUserView> users, bool isTablet) {
    if (isTablet) {
      return _buildUsersGrid(context, users);
    } else {
      return _buildUsersMobileList(context, users);
    }
  }

  Widget _buildUsersGrid(BuildContext context, List<AdminUserView> users) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildUserCard(users[index]);
      },
    );
  }

  Widget _buildUserCard(AdminUserView user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: user.isSuspended
            ? Border.all(color: Colors.red.withValues(alpha:0.3), width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetails(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User Avatar and Status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryGreen.withValues(alpha:0.1),
                      backgroundImage: user.profilePictureUrl?.isNotEmpty == true
                          ? CachedNetworkImageProvider(user.profilePictureUrl!)
                          : null,
                      child: user.profilePictureUrl?.isEmpty != false
                          ? Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getUserStatusColor(user),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // User Info
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(user.postsCount.toString(), 'Posts'),
                    Container(width: 1, height: 20, color: Colors.grey[300]),
                    _buildStatItem(user.likesReceived.toString(), 'Likes'),
                  ],
                ),
                const SizedBox(height: 8),

                // Join Date
                Text(
                  'Joined ${DateFormat('MMM yyyy').format(user.joinedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),

                const Spacer(),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(value, user),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (!user.isSuspended)
                        const PopupMenuItem(
                          value: 'suspend',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Suspend User', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      if (user.isSuspended)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Activate User', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'posts',
                        child: Row(
                          children: [
                            Icon(Icons.article, size: 20),
                            SizedBox(width: 8),
                            Text('View Posts'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.more_horiz, color: AppColors.primaryGreen, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Actions',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildUsersMobileList(BuildContext context, List<AdminUserView> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: user.isSuspended
                ? Border.all(color: Colors.red.withValues(alpha:0.3))
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha:0.1),
                  backgroundImage: user.profilePictureUrl?.isNotEmpty == true
                      ? CachedNetworkImageProvider(user.profilePictureUrl!)
                      : null,
                  child: user.profilePictureUrl?.isEmpty != false
                      ? Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getUserStatusColor(user),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.isSuspended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'SUSPENDED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${user.postsCount} posts • ${user.likesReceived} likes',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      'Joined ${timeago.format(user.joinedAt)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleUserAction(value, user),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                if (!user.isSuspended)
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Suspend', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                if (user.isSuspended)
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Activate', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),
            onTap: () => _showUserDetails(user),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load users',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(adminUsersProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserStatusColor(AdminUserView user) {
    if (user.isSuspended) return Colors.red;
    if (!user.isEmailVerified) return Colors.orange;
    if (user.lastActiveAt != null &&
        DateTime.now().difference(user.lastActiveAt!).inDays < 7) {
      return Colors.green;
    }
    return Colors.grey;
  }

  void _handleUserAction(String action, AdminUserView user) {
    switch (action) {
      case 'details':
        _showUserDetails(user);
        break;
      case 'suspend':
        _showSuspendDialog(user);
        break;
      case 'activate':
        _activateUser(user);
        break;
      case 'posts':
        _showUserPosts(user);
        break;
    }
  }

  void _showUserDetails(AdminUserView user) {
    showDialog(
      context: context,
      builder: (context) => AdminUserDetailsDialog(user: user),
    );
  }

  void _showSuspendDialog(AdminUserView user) {
    showDialog(
      context: context,
      builder: (context) => AdminActionDialog(
        title: 'Suspend User',
        message: 'Are you sure you want to suspend ${user.username}?',
        actionText: 'Suspend',
        actionColor: Colors.red,
        requiresReason: true,
        onConfirm: (reason) => _suspendUser(user, reason),
      ),
    );
  }

  void _suspendUser(AdminUserView user, String reason) async {
    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.suspendUser(user.id, reason, adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.username} has been suspended'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to suspend user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _activateUser(AdminUserView user) async {
    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.activateUser(user.id, adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.username} has been activated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserPosts(AdminUserView user) {
    // Navigate to user posts screen or show dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.username}\'s Posts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder(
                  future: ref.read(adminRepositoryProvider).getUserPosts(user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final posts = snapshot.data as List<Map<String, dynamic>>? ?? [];

                    if (posts.isEmpty) {
                      return const Center(child: Text('No posts found'));
                    }

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              post['content'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Posted ${timeago.format(post['createdAt']?.toDate() ?? DateTime.now())}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deletePost(post['id'], user.username);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deletePost(String postId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete this post by $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminId = ref.read(currentAdminIdProvider);
      if (adminId == null) return;

      final adminRepository = ref.read(adminRepositoryProvider);
      await adminRepository.deletePost(postId, adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportUsers('csv');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportUsers('pdf');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportUsers(String format) {
    // Implementation for exporting users
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting users as $format...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }
}