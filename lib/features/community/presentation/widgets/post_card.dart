import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:animate_do/animate_do.dart';

import '../../../../core/theme/app_colors.dart';


class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onReport;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onReport,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Check if post is already liked (this would come from your state management)
    _isLiked = false; // You can implement this based on your data structure
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with author info
            _buildPostHeader(),

            // Post content
            _buildPostContent(),

            // Post image (if exists)
            if (widget.post['imageUrl'] != null &&
                widget.post['imageUrl'].toString().isNotEmpty)
              _buildPostImage(),

            // Location and tags
            _buildLocationAndTags(),

            // Interaction stats
            _buildInteractionStats(),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Author avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
            backgroundImage: widget.post['authorAvatar']?.toString().isNotEmpty == true
                ? CachedNetworkImageProvider(widget.post['authorAvatar'])
                : null,
            child: widget.post['authorAvatar']?.toString().isEmpty != false
                ? Text(
              widget.post['authorName']?.toString().isNotEmpty == true
                  ? widget.post['authorName'].toString()[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),

          // Author info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post['authorName']?.toString() ?? 'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(widget.post['createdAt'] ?? DateTime.now()),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Post menu
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Icon(
              Icons.more_horiz,
              color: Colors.grey.shade600,
            ),
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
                    Text('Share Post'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Report Post', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post text content
          Text(
            widget.post['content']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.post['imageUrl'],
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.error, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationAndTags() {
    final hasLocation = widget.post['location']?.toString().isNotEmpty == true;
    final hasTags = widget.post['tags'] != null &&
        (widget.post['tags'] as List).isNotEmpty;

    if (!hasLocation && !hasTags) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          if (hasLocation) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.post['location'].toString(),
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (hasTags) const SizedBox(height: 8),
          ],

          // Tags
          if (hasTags) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (widget.post['tags'] as List).map<Widget>((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionStats() {
    final likesCount = widget.post['likesCount'] as int? ?? 0;
    final commentsCount = widget.post['commentsCount'] as int? ?? 0;

    if (likesCount == 0 && commentsCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (likesCount > 0) ...[
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatCount(likesCount),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (likesCount > 0 && commentsCount > 0) ...[
            const SizedBox(width: 16),
          ],
          if (commentsCount > 0) ...[
            Row(
              children: [
                Icon(
                  Icons.comment,
                  color: AppColors.info,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatCount(commentsCount),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Like button
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Like',
            color: _isLiked ? AppColors.error : Colors.grey.shade600,
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
              _animateButton();
              widget.onLike?.call();
            },
            isAnimated: true,
          ),

          // Comment button
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: 'Comment',
            color: Colors.grey.shade600,
            onTap: widget.onComment,
          ),

          // Share button
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            color: Colors.grey.shade600,
            onTap: widget.onShare,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isAnimated = false,
  }) {
    Widget button = Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
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
      ),
    );

    if (isAnimated) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: button,
        ),
      );
    }

    return button;
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save':
        widget.onSave?.call();
        break;
      case 'share':
        widget.onShare?.call();
        break;
      case 'report':
        widget.onReport?.call();
        break;
    }
  }

  void _animateButton() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }
}