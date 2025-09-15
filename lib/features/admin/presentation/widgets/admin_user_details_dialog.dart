import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_models.dart';

class AdminUserDetailsBottomSheet extends ConsumerWidget {
  final AdminUserView user;

  const AdminUserDetailsBottomSheet({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Text(
                      'User Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Section
                      _buildUserProfile(context),
                      const SizedBox(height: 24),

                      // User Stats & Info
                      _buildInfoSection('Account Information', [
                        _buildInfoRow('Email', user.email),
                        _buildInfoRow('Phone', user.phoneNumber ?? 'Not provided'),
                        _buildInfoRow('Location', user.location ?? 'Not provided'),
                        _buildInfoRow('Joined', DateFormat('MMM dd, yyyy').format(user.joinedAt)),
                        _buildInfoRow('Last Active',
                            user.lastActiveAt != null
                                ? timeago.format(user.lastActiveAt!)
                                : 'Never'),
                      ]),
                      const SizedBox(height: 20),

                      _buildInfoSection('Account Status', [
                        _buildStatusRow('Email Verified', user.isEmailVerified),
                        _buildStatusRow('Phone Verified', user.isPhoneVerified),
                        _buildStatusRow('Account Active', user.isActive),
                        _buildStatusRow('Suspended', user.isSuspended),
                      ]),
                      const SizedBox(height: 20),

                      _buildInfoSection('Activity Stats', [
                        _buildInfoRow('Posts', user.postsCount.toString()),
                        _buildInfoRow('Comments', user.commentsCount.toString()),
                        _buildInfoRow('Likes Received', user.likesReceived.toString()),
                      ]),

                      if (user.isSuspended && user.suspensionReason != null) ...[
                        const SizedBox(height: 20),
                        _buildInfoSection('Suspension Details', [
                          _buildInfoRow('Reason', user.suspensionReason!),
                          _buildInfoRow('Suspended At',
                              user.suspendedAt != null
                                  ? DateFormat('MMM dd, yyyy HH:mm').format(user.suspendedAt!)
                                  : 'Unknown'),
                        ]),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Fixed Action Buttons at bottom
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: !user.isSuspended
                          ? ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showSuspendUserDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Suspend User'),
                      )
                          : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showActivateUserDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Activate User'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.1),
            AppColors.primaryGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Profile image and basic info
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    backgroundImage: user.profilePictureUrl?.isNotEmpty == true
                        ? CachedNetworkImageProvider(user.profilePictureUrl!)
                        : null,
                    child: user.profilePictureUrl?.isEmpty != false
                        ? Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _getUserStatusColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isSuspended)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Status indicator
                    Row(
                      children: [
                        Icon(
                          _getUserStatusIcon(),
                          size: 16,
                          color: _getUserStatusColor(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getUserStatusText(),
                          style: TextStyle(
                            color: _getUserStatusColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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

          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('Posts', user.postsCount),
              _buildVerticalDivider(),
              _buildQuickStat('Comments', user.commentsCount),
              _buildVerticalDivider(),
              _buildQuickStat('Likes', user.likesReceived),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            status ? 'Yes' : 'No',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: status ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserStatusColor() {
    if (user.isSuspended) return Colors.red;
    if (!user.isEmailVerified) return Colors.orange;
    if (user.lastActiveAt != null &&
        DateTime.now().difference(user.lastActiveAt!).inDays < 7) {
      return Colors.green;
    }
    return Colors.grey;
  }

  IconData _getUserStatusIcon() {
    if (user.isSuspended) return Icons.block;
    if (!user.isEmailVerified) return Icons.warning;
    if (user.lastActiveAt != null &&
        DateTime.now().difference(user.lastActiveAt!).inDays < 7) {
      return Icons.circle;
    }
    return Icons.circle_outlined;
  }

  String _getUserStatusText() {
    if (user.isSuspended) return 'Suspended';
    if (!user.isPhoneVerified) return 'Unverified';
    if (user.lastActiveAt != null &&
        DateTime.now().difference(user.lastActiveAt!).inDays < 7) {
      return 'Active';
    }
    return 'Inactive';
  }

  void _showSuspendUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Text('Are you sure you want to suspend ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement suspend user logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showActivateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate User'),
        content: Text('Are you sure you want to activate ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement activate user logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }
}

