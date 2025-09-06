import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/tips_provider.dart';

class DailyTipCard extends ConsumerStatefulWidget {
  final bool isHomeScreen;
  final VoidCallback? onTap;

  const DailyTipCard({
    super.key,
    this.isHomeScreen = true,
    this.onTap,
  });

  @override
  ConsumerState<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends ConsumerState<DailyTipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyTipAsync = ref.watch(dailyTipProvider);

    return dailyTipAsync.when(
      data: (tip) => _buildTipCard(context, tip),
      loading: () => _buildLoadingCard(),
      error: (error, stack) => _buildErrorCard(context, error),
    );
  }

  Widget _buildTipCard(BuildContext context, Map<String, dynamic> tip) {
    final title = tip['title'] as String? ?? 'Daily Farming Tip';
    final content = tip['content'] as String? ?? 'No tip available today';
    final category = tip['category'] as String? ?? 'general';
    final author = tip['author'] as String? ?? 'AgriBot';
    final createdAt = tip['createdAt'] as DateTime? ?? DateTime.now();
    final likesCount = tip['likesCount'] as int? ?? 0;
    final isLiked = tip['isLiked'] as bool? ?? false;
    final isSaved = tip['isSaved'] as bool? ?? false;

    return GestureDetector(
      onTap: widget.onTap ?? () => _handleTap(context, tip),
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isHomeScreen
                  ? [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.85),
              ]
                  : [
                Colors.white,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.isHomeScreen
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: widget.isHomeScreen ? 15 : 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: widget.isHomeScreen ? Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: widget.isHomeScreen
                                  ? AppColors.primaryGreen
                                  : AppColors.primaryGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.isHomeScreen ? 'Daily Tip' : 'Today\'s Featured Tip',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.isHomeScreen
                                    ? AppColors.primaryGreen
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('MMMM d, yyyy').format(createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.isHomeScreen
                                ? AppColors.primaryGreen.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isHomeScreen) ...[
                    IconButton(
                      onPressed: () => _toggleSave(tip),
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? AppColors.primaryGreen : AppColors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatCategory(category),
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isHomeScreen
                      ? AppColors.textPrimary
                      : AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 12),

              // Content
              Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: widget.isHomeScreen
                      ? AppColors.textPrimary.withValues(alpha: 0.8)
                      : AppColors.textPrimary,
                  height: 1.5,
                ),
                maxLines: widget.isHomeScreen ? 3 : null,
                overflow: widget.isHomeScreen ? TextOverflow.ellipsis : null,
              ),

              const SizedBox(height: 16),

              // Footer
              Row(
                children: [
                  // Author
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isHomeScreen
                          ? AppColors.primaryGreen.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: widget.isHomeScreen
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          author,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: widget.isHomeScreen
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Interaction buttons
                  if (!widget.isHomeScreen) ...[
                    // Like button
                    GestureDetector(
                      onTap: () => _toggleLike(tip),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isLiked ? Colors.red : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              likesCount.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Share button
                    GestureDetector(
                      onTap: () => _shareTip(tip),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(
                          Icons.share,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Read more indicator for home screen
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read more',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: widget.isHomeScreen ? 160 : 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isHomeScreen
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.isHomeScreen
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: widget.isHomeScreen ? 15 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoader(width: 40, height: 40, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 4),
                    SkeletonLoader(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 20,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: 4,
          ),
          const SizedBox(height: 4),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 14,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isHomeScreen
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error.withValues(alpha: 0.7),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load daily tip',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.invalidate(dailyTipProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'planting':
        return Icons.eco;
      case 'watering':
        return Icons.water_drop;
      case 'pest control':
        return Icons.bug_report;
      case 'harvesting':
        return Icons.agriculture;
      case 'soil care':
        return Icons.terrain;
      case 'fertilization':
        return Icons.scatter_plot;
      case 'crop rotation':
        return Icons.rotate_right;
      case 'seasonal':
        return Icons.calendar_today;
      default:
        return Icons.lightbulb;
    }
  }

  String _formatCategory(String category) {
    return category.split(' ').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  void _handleTap(BuildContext context, Map<String, dynamic> tip) {
    if (widget.isHomeScreen) {
      // Navigate to tips screen and show this tip
      context.go('/main', extra: {'initialTab': 3}); // Tips tab index
    } else {
      // Show tip details modal
      _showTipDetails(context, tip);
    }
  }

  void _showTipDetails(BuildContext context, Map<String, dynamic> tip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'] ?? 'Daily Tip',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tip['content'] ?? '',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleLike(Map<String, dynamic> tip) {
    final tipId = tip['id'] as String;
    ref.read(tipsActionsProvider).likeTip(tipId, 'current_user_id');
  }

  void _toggleSave(Map<String, dynamic> tip) {
    final tipId = tip['id'] as String;
    ref.read(tipsActionsProvider).saveTip(tipId, 'current_user_id');
  }

  void _shareTip(Map<String, dynamic> tip) {
    // Implement sharing functionality
    // You can use share_plus package
  }
}