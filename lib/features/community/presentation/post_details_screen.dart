import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/config/app_config.dart';

import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'providers/community_provider.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailsScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAddingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postDetails = ref.watch(postDetailsProvider(widget.postId));
    final postComments = ref.watch(postCommentsProvider(widget.postId));

    return CustomScaffold(
      showGradient: true,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Share post
            },
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: postDetails.when(
        data: (post) => post != null
            ? _buildPostDetailsContent(context, post, postComments)
            : _buildNotFoundState(context),
        loading: () => const Center(
          child: LoadingIndicator(
            size: LoadingSize.medium,
            color: Colors.white,
            message: 'Loading post...',
          ),
        ),
        error: (error, stack) => _buildErrorState(context),
      ),
    );
  }

  Widget _buildPostDetailsContent(
      BuildContext context,
      Map<String, dynamic> post,
      AsyncValue<List<Map<String, dynamic>>> commentsAsync,
      ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Post Content
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: _buildPostCard(context, post),
                ),

                const SizedBox(height: 30),

                // Comments Section
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: _buildCommentsSection(context, commentsAsync),
                ),
              ],
            ),
          ),
        ),

        // Comment Input
        _buildCommentInput(context),
      ],
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post) {
    final content = post['content'] as String? ?? '';
    final authorName = post['authorName'] as String? ?? 'Unknown User';
    final authorAvatar = post['authorAvatar'] as String? ?? '';
    final imageUrl = post['imageUrl'] as String? ?? '';
    final likesCount = post['likesCount'] as int? ?? 0;
    final commentsCount = post['commentsCount'] as int? ?? 0;
    final createdAt = post['createdAt'] as DateTime?;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
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
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
                    // TODO: Show post options
                  },
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
          ),

          // Image
          if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 300,
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: LoadingIndicator(size: LoadingSize.small),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (likesCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
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

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.thumb_up_outlined,
                  label: 'Like',
                  onTap: () {
                    // TODO: Like post
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: () {
                    // Focus on comment input
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    // TODO: Share post
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(
      BuildContext context,
      AsyncValue<List<Map<String, dynamic>>> commentsAsync,
      ) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Comments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          commentsAsync.when(
            data: (comments) => comments.isEmpty
                ? _buildNoCommentsState(context)
                : _buildCommentsList(context, comments),
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: LoadingIndicator(size: LoadingSize.small),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load comments',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(BuildContext context, List<Map<String, dynamic>> comments) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(context, comment);
      },
    );
  }

  Widget _buildCommentItem(BuildContext context, Map<String, dynamic> comment) {
    final content = comment['content'] as String? ?? '';
    final authorName = comment['authorName'] as String? ?? 'Unknown User';
    final authorAvatar = comment['authorAvatar'] as String? ?? '';
    final createdAt = comment['createdAt'] as DateTime?;

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          CircleAvatar(
          radius: 18,
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
              fontSize: 14,
            ),
          )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
              children: [
              Text(
              authorName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (createdAt != null) ...[
        const SizedBox(width: 8),
    Text(
    timeago.format(createdAt),
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: AppColors.textSecondary,
    ),
    ),