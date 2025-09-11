import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/network_error_widget.dart';
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
  final FocusNode _commentFocusNode = FocusNode();

  bool _isAddingComment = false;
  bool _isPostSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfPostSaved();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkIfPostSaved() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      try {
        final communityRepository = ref.read(communityRepositoryProvider);
        final saved = await communityRepository.isPostSaved(widget.postId, currentUser.uid);
        setState(() {
          _isPostSaved = saved;
        });
      } catch (e) {
        // Ignore error
      }
    }
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
            onPressed: () => _sharePost(),
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(_isPostSaved ? Icons.bookmark : Icons.bookmark_border, size: 20),
                    const SizedBox(width: 8),
                    Text(_isPostSaved ? 'Unsave Post' : 'Save Post'),
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
      body: postDetails.when(
        data: (post) => post != null
            ? _buildPostContent(post, postComments)
            : _buildNotFoundState(),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildPostContent(
      Map<String, dynamic> post,
      AsyncValue<List<Map<String, dynamic>>> commentsAsync,
      ) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Post content
              SliverToBoxAdapter(
                child: _buildPostHeader(post),
              ),

              // Comments section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Comments',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Comments list
              commentsAsync.when(
                data: (comments) => comments.isNotEmpty
                    ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: index * 100),
                      child: _buildCommentItem(comments[index]),
                    ),
                    childCount: comments.length,
                  ),
                )
                    : SliverToBoxAdapter(
                  child: _buildNoCommentsState(),
                ),
                loading: () => SliverToBoxAdapter(
                  child: _buildCommentsLoadingState(),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: _buildCommentsErrorState(),
                ),
              ),

              // Bottom spacing for comment input
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostHeader(Map<String, dynamic> post) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  backgroundImage: post['authorAvatar']?.isNotEmpty == true
                      ? CachedNetworkImageProvider(post['authorAvatar'])
                      : null,
                  child: post['authorAvatar']?.isEmpty != false
                      ? Text(
                    post['authorName']?.isNotEmpty == true
                        ? post['authorName'][0].toUpperCase()
                        : 'U',
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
                        post['authorName'] ?? 'Unknown User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timeago.format(post['createdAt'] ?? DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Post content
            Text(
              post['content'] ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
            ),

            // Location
            if (post['location'] != null && post['location'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post['location'],
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Tags
            if (post['tags'] != null && (post['tags'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (post['tags'] as List).map<Widget>((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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

            // Post image
            if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post['imageUrl'],
                  width: double.infinity,
                  height: 300,
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
            ],

            const SizedBox(height: 16),

            // Interaction buttons
            Row(
              children: [
                _buildInteractionButton(
                  icon: Icons.favorite,
                  label: _formatCount(post['likesCount'] ?? 0),
                  color: AppColors.error,
                  onTap: () => _likePost(),
                ),
                _buildInteractionButton(
                  icon: Icons.comment,
                  label: _formatCount(post['commentsCount'] ?? 0),
                  color: AppColors.info,
                  onTap: () => _focusCommentInput(),
                ),
                _buildInteractionButton(
                  icon: Icons.share,
                  label: 'Share',
                  color: AppColors.primaryGreen,
                  onTap: () => _sharePost(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
            backgroundImage: comment['authorAvatar']?.isNotEmpty == true
                ? CachedNetworkImageProvider(comment['authorAvatar'])
                : null,
            child: comment['authorAvatar']?.isEmpty != false
                ? Text(
              comment['authorName']?.isNotEmpty == true
                  ? comment['authorName'][0].toUpperCase()
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['authorName'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment['createdAt'] ?? DateTime.now()),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _likeComment(comment['id']),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(comment['likesCount'] ?? 0),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _replyToComment(comment),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
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

  Widget _buildCommentInput() {
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
            radius: 18,
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
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              maxLength: AppConfig.maxCommentLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isAddingComment ? null : _addComment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _commentController.text.trim().isNotEmpty
                    ? AppColors.primaryGreen
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isAddingComment
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Icon(
                Icons.send,
                color: _commentController.text.trim().isNotEmpty
                    ? Colors.white
                    : Colors.grey.shade600,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: LoadingIndicator(
        size: LoadingSize.large,
        message: 'Loading post...',
      ),
    );
  }

  Widget _buildNotFoundState() {
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The post you\'re looking for doesn\'t exist or has been removed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
                backgroundColor: AppColors.primaryGreen,
                textColor: Colors.white,
                icon: const Icon(Icons.arrow_back),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    // ✅ ADD NETWORK-AWARE ERROR HANDLING
    if (error is NetworkException) {
      return NetworkErrorWidget(
        title: 'Post Unavailable Offline',
        message: 'This post requires internet connection to view.',
        onRetry: () => ref.invalidate(postDetailsProvider(widget.postId)),
      );
    }

    return NetworkErrorWidget(
      title: 'Unable to load post',
      message: 'Please check your connection and try again.',
      onRetry: () => ref.invalidate(postDetailsProvider(widget.postId)),
    );
  }

  Widget _buildNoCommentsState() {
    return Container(
      color: Colors.white,
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

  Widget _buildCommentsLoadingState() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: LoadingIndicator(
          size: LoadingSize.medium,
          message: 'Loading comments...',
        ),
      ),
    );
  }

  Widget _buildCommentsErrorState() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load comments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Retry',
            onPressed: () {
              ref.invalidate(postCommentsProvider(widget.postId));
            },
            backgroundColor: AppColors.primaryGreen,
            textColor: Colors.white,
          ),
        ],
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

  void _focusCommentInput() {
    _commentFocusNode.requestFocus();
  }

  Future<void> _likePost() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      await communityRepository.likePost(widget.postId, currentUser.uid);

      // Refresh post details to show updated like count
      ref.invalidate(postDetailsProvider(widget.postId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to like post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addComment() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || _commentController.text.trim().isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      await communityRepository.createComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'User',
        authorAvatar: currentUser.photoURL ?? '',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingComment = false;
      });
    }
  }

  Future<void> _likeComment(String commentId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      await communityRepository.likeComment(commentId, currentUser.uid);

      ref.invalidate(postCommentsProvider(widget.postId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to like comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _replyToComment(Map<String, dynamic> comment) {
    final authorName = comment['authorName'] as String? ?? 'User';
    _commentController.text = '@$authorName ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    _focusCommentInput();
  }

  Future<void> _sharePost() async {
    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      final shareText = await communityRepository.sharePost(widget.postId);

      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save':
        _toggleSavePost();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  Future<void> _toggleSavePost() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final communityRepository = ref.read(communityRepositoryProvider);

      if (_isPostSaved) {
        await communityRepository.unsavePost(widget.postId, currentUser.uid);
        setState(() {
          _isPostSaved = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post removed from saved posts'),
            backgroundColor: AppColors.info,
          ),
        );
      } else {
        await communityRepository.savePost(widget.postId, currentUser.uid);
        setState(() {
          _isPostSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${_isPostSaved ? 'unsave' : 'save'} post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDialog() {
    final reasons = [
      'Spam or misleading content',
      'Inappropriate language',
      'Harassment or bullying',
      'False information',
      'Copyright violation',
      'Other',
    ];

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
            ...reasons.map(
                  (reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reason),
                onTap: () {
                  Navigator.pop(context);
                  _reportPost(reason);
                },
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

  Future<void> _reportPost(String reason) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final communityRepository = ref.read(communityRepositoryProvider);
      await communityRepository.reportPost(
        postId: widget.postId,
        reporterId: currentUser.uid,
        reason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post reported. Thank you for your feedback.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to report post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}