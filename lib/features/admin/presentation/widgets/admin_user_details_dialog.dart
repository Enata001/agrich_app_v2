
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_models.dart';


class AdminUserDetailsDialog extends ConsumerWidget {
  final AdminUserView user;

  const AdminUserDetailsDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 500 : null,
        height: MediaQuery.of(context).size.height > 600 ? 600 : null,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
                ),
              ],
            ),
            const SizedBox(height: 20),

            // User Profile Section
            _buildUserProfile(context),
            const SizedBox(height: 24),

            // User Stats & Info
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                if (!user.isSuspended)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Show suspend dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Suspend User'),
                  ),
                if (user.isSuspended)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Activate user
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Activate User'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQuickStat('Posts', user.postsCount),
                  const SizedBox(width: 16),
                  _buildQuickStat('Comments', user.commentsCount),
                  const SizedBox(width: 16),
                  _buildQuickStat('Likes', user.likesReceived),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            status ? 'Yes' : 'No',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
}
