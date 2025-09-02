import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_button.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _sharePost(context),
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, size: 20),
                    SizedBox(width: 8),
                    Text('Report Post'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.bookmark, size: 20),
                    SizedBox(width: 8),
                    Text('Save Post'),
                  ],
                ),
              ),
            ],
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
            color: AppColors.primaryGreen,
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
    final currentUser = ref.watch(currentUserProvider);
    final isLiked = post['likedBy']?.contains(currentUser?.uid) ?? false;

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
                          color: AppColors.textPrimary,
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
                Icon(
                  Icons.public,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),

          // Content
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

          // Image
          if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '$likesCount',
                  color: isLiked ? Colors.red : Colors.grey.shade600,
                  onTap: () => _toggleLike(post['id']),
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: '$commentsCount',
                  color: Colors.grey.shade600,
                  onTap: () => _focusCommentInput(),
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: Colors.grey.shade600,
                  onTap: () => _sharePost(context),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
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
    );
  }

  Widget _buildCommentsSection(BuildContext context, AsyncValue<List<Map<String, dynamic>>> commentsAsync) {
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
                color: AppColors.textPrimary,
              ),
            ),
          ),
          commentsAsync.when(
            data: (comments) => comments.isNotEmpty
                ? Column(
              children: comments.map((comment) => _buildCommentItem(context, comment)).toList(),
            )
                : _buildNoCommentsState(context),
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: LoadingIndicator(
                  size: LoadingSize.small,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load comments',
                style: TextStyle(color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, Map<String, dynamic> comment) {
    final content = comment['content'] as String? ?? '';
    final authorName = comment['authorName'] as String? ?? 'Unknown User';
    final authorAvatar = comment['authorAvatar'] as String? ?? '';
    final createdAt = comment['createdAt'] as DateTime?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (createdAt != null)
                      Text(
                        timeago.format(createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _likeComment(comment['id']),
                      child: Text(
                        'Like',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _replyToComment(context, comment),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    );
  }

  // FIXED: Add missing _buildNoCommentsState method
  Widget _buildNoCommentsState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment on this post',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // FIXED: Add missing _buildNotFoundState method
  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Post not found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The post you\'re looking for doesn\'t exist or has been removed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
                backgroundColor: AppColors.primaryGreen,
                textColor: Colors.white,
                icon: Icon(Icons.arrow_back),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Add missing _buildErrorState method
  Widget _buildErrorState(BuildContext context) {
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
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Unable to load post',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    text: 'Retry',
                    onPressed: () {
                      ref.invalidate(postDetailsProvider(widget.postId));
                      ref.invalidate(postCommentsProvider(widget.postId));
                    },
                    backgroundColor: AppColors.primaryGreen,
                    textColor: Colors.white,
                    icon: Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: 'Go Back',
                    onPressed: () => context.pop(),
                    backgroundColor: Colors.grey.shade200,
                    textColor: AppColors.textPrimary,
                    icon: Icon(Icons.arrow_back),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Add missing _buildCommentInput method
  Widget _buildCommentInput(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
            backgroundImage: currentUser?.photoURL != null
                ? NetworkImage(currentUser!.photoURL!)
                : null,
            child: currentUser?.photoURL == null
                ? Text(
              currentUser?.displayName?.isNotEmpty == true
                  ? currentUser!.displayName![0].toUpperCase()
                  : 'U',
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                minLines: 1,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isAddingComment ? null : _submitComment,
            icon: _isAddingComment
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            )
                : const Icon(
              Icons.send,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike(String postId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      ref.read(communityRepositoryProvider).likePost(postId);
      ref.invalidate(postDetailsProvider(widget.postId));
    }
  }

  void _focusCommentInput() {
    // Focus on comment input and scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isAddingComment) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (content.length > AppConfig.maxCommentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment is too long (max ${AppConfig.maxCommentLength} characters)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAddingComment = true;
    });

    try {
      await ref.read(communityRepositoryProvider).addComment(
        widget.postId,
        {
          'content': content,
          'authorId': currentUser.uid,
          'authorName': currentUser.displayName ?? 'User',
          'authorAvatar': currentUser.photoURL ?? '',
          'createdAt': DateTime.now(),
        },
      );

      _commentController.clear();
      ref.invalidate(postCommentsProvider(widget.postId));
      ref.invalidate(postDetailsProvider(widget.postId));

      // Scroll to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingComment = false;
        });
      }
    }
  }

  void _likeComment(String commentId) {
    // TODO: Implement comment like functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment like feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _replyToComment(BuildContext context, Map<String, dynamic> comment) {
    final authorName = comment['authorName'] as String? ?? 'User';
    _commentController.text = '@$authorName ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );

    // Focus on input
    _focusCommentInput();
  }

  void _sharePost(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'report':
        _reportPost(context);
        break;
      case 'save':
        _savePost(context);
        break;
    }
  }

  void _reportPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Are you sure you want to report this post? Our team will review it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post reported. Thank you for your feedback.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _savePost(BuildContext context) {
    // TODO: Implement save post functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post saved to your bookmarks!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}