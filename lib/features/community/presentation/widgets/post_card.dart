import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onAuthorTap;
  final bool showActions;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onAuthorTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = post['content'] as String? ?? '';
    final authorName = post['authorName'] as String? ?? 'Unknown User';
    final authorAvatar = post['authorAvatar'] as String? ?? '';
    final imageUrl = post['imageUrl'] as String? ?? '';
    final likesCount = post['likesCount'] as int? ?? 0;
    final commentsCount = post['commentsCount'] as int? ?? 0;
    final createdAt = post['createdAt'] as DateTime?;
    final likedBy = post['likedBy'] as List<dynamic>? ?? [];
    final isLiked = false; // TODO: Check if current user liked this post

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Post Header
            _buildPostHeader(context, authorName, authorAvatar, createdAt),

            // Post Content
            if (content.isNotEmpty) _buildPostContent(context, content),

            // Post Image
            if (imageUrl.isNotEmpty) _buildPostImage(context, imageUrl),

            // Post Actions
            if (showActions) _buildPostActions(context, likesCount, commentsCount, isLiked),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context, String authorName, String authorAvatar, DateTime? createdAt) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              backgroundImage: authorAvatar.isNotEmpty
                  ? CachedNetworkImageProvider(authorAvatar)
                  : null,
              child: authorAvatar.isEmpty
                  ? Text(
                authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  child: Text(
                    authorName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (createdAt != null)
                  Text(
                    timeago.format(createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              color: Colors.grey.shade600,
            ),
            onSelected: (value) => _handlePostMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border, size: 20),
                    SizedBox(width: 8),
                    Text('Save Post'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Report', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPostImage(BuildContext context, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 300,
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostActions(BuildContext context, int likesCount, int commentsCount, bool isLiked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(likesCount),
            color: isLiked ? Colors.red : Colors.grey.shade600,
            onTap: onLike,
          ),
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: _formatCount(commentsCount),
            color: Colors.grey.shade600,
            onTap: onComment,
          ),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            color: Colors.grey.shade600,
            onTap: onShare,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  void _handlePostMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'save':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post saved!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'share':
        if (onShare != null) {
          onShare!();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Share functionality coming soon!'),
              backgroundColor: AppColors.info,
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;
      case 'report':
        _showReportDialog(context);
        break;
    }
  }

  void _showReportDialog(BuildContext context) {
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
            ...['Spam', 'Inappropriate content', 'False information', 'Harassment', 'Other'].map(
                  (reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reason),
                leading: Radio<String>(
                  value: reason,
                  groupValue: null,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _reportPost(context, value ?? reason);
                  },
                ),
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

  void _reportPost(BuildContext context, String reason) {
    // TODO: Implement actual report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post reported for: $reason. Thank you for your feedback.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Compact version of PostCard for lists
class CompactPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onTap;

  const CompactPostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = post['content'] as String? ?? '';
    final authorName = post['authorName'] as String? ?? 'Unknown User';
    final authorAvatar = post['authorAvatar'] as String? ?? '';
    final likesCount = post['likesCount'] as int? ?? 0;
    final commentsCount = post['commentsCount'] as int? ?? 0;
    final createdAt = post['createdAt'] as DateTime?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              backgroundImage: authorAvatar.isNotEmpty
                  ? CachedNetworkImageProvider(authorAvatar)
                  : null,
              child: authorAvatar.isEmpty
                  ? Text(
                authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content.length > 100 ? '${content.substring(0, 100)}...' : content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        likesCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.comment,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        commentsCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (createdAt != null)
                        Text(
                          timeago.format(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
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
}

// Shimmer loading version of PostCard
class PostCardShimmer extends StatefulWidget {
  const PostCardShimmer({super.key});

  @override
  State<PostCardShimmer> createState() => _PostCardShimmerState();
}

class _PostCardShimmerState extends State<PostCardShimmer>
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header shimmer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildShimmerBox(44, 44, BorderRadius.circular(22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(120, 16, BorderRadius.circular(4)),
                      const SizedBox(height: 4),
                      _buildShimmerBox(80, 12, BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(double.infinity, 16, BorderRadius.circular(4)),
                const SizedBox(height: 8),
                _buildShimmerBox(MediaQuery.of(context).size.width * 0.7, 16, BorderRadius.circular(4)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Image shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmerBox(double.infinity, 200, BorderRadius.circular(12)),
          ),

          const SizedBox(height: 16),

          // Actions shimmer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShimmerBox(60, 32, BorderRadius.circular(16)),
                _buildShimmerBox(70, 32, BorderRadius.circular(16)),
                _buildShimmerBox(65, 32, BorderRadius.circular(16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, BorderRadius borderRadius) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
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