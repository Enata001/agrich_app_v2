import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );

    // Check if post is liked by current user
    final likedBy = List<String>.from(widget.post['likedBy'] ?? []);
    _isLiked = likedBy.contains('current_user_id'); // TODO: Use actual user ID
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.post['content'] as String? ?? '';
    final authorName = widget.post['authorName'] as String? ?? 'Unknown User';
    final authorAvatar = widget.post['authorAvatar'] as String? ?? '';
    final imageUrl = widget.post['imageUrl'] as String? ?? '';
    final likesCount = widget.post['likesCount'] as int? ?? 0;
    final commentsCount = widget.post['commentsCount'] as int? ?? 0;
    final createdAt = widget.post['createdAt'] as DateTime?;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
            _buildHeader(context, authorName, authorAvatar, createdAt),
            if (content.isNotEmpty) _buildContent(context, content),
            if (imageUrl.isNotEmpty) _buildImage(imageUrl),
            _buildActions(context, likesCount, commentsCount),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      String authorName,
      String authorAvatar,
      DateTime? createdAt,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
            backgroundImage: authorAvatar.isNotEmpty
                ? CachedNetworkImageProvider(authorAvatar)
                : null,
            child: authorAvatar.isEmpty
                ? Text(
              authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    timeago.format(createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Show post options menu
            },
            icon: const Icon(
              Icons.more_horiz,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: AppColors.surfaceVariant,
            child: const Center(
              child: LoadingIndicator(size: LoadingSize.small),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: AppColors.surfaceVariant,
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, int likesCount, int commentsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Like and comment counts
          if (likesCount > 0 || commentsCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (likesCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.thumb_up,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likesCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (likesCount > 0 && commentsCount > 0) const Spacer(),
                  if (commentsCount > 0)
                    Text(
                      '$commentsCount ${commentsCount == 1 ? 'comment' : 'comments'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: 'Like',
                color: _isLiked ? AppColors.primaryGreen : AppColors.textSecondary,
                onTap: _handleLike,
              ),
              _buildActionButton(
                context,
                icon: Icons.comment_outlined,
                label: 'Comment',
                color: AppColors.textSecondary,
                onTap: widget.onComment,
              ),
              _buildActionButton(
                context,
                icon: Icons.share_outlined,
                label: 'Share',
                color: AppColors.textSecondary,
                onTap: widget.onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        VoidCallback? onTap,
      }) {
    return AnimatedBuilder(
      animation: _likeAnimation,
      builder: (context, child) {
        final scale = label == 'Like' ? _likeAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    widget.onLike?.call();
  }
}