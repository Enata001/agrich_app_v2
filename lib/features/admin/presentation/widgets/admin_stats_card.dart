import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';

enum TrendDirection { up, down, neutral }

class AdminStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TrendDirection? trend;
  final VoidCallback? onTap;

  const AdminStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive design based on available width
                final isNarrow = constraints.maxWidth < 200;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row with icon and trend
                    Row(
                      children: [
                        // Icon container
                        Container(
                          padding: EdgeInsets.all(isNarrow ? 8 : 10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isNarrow ? 8 : 12),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: isNarrow ? 18 : 22,
                          ),
                        ),

                        const Spacer(),

                        // Trend indicator
                        if (trend != null && trend != TrendDirection.neutral)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: trend == TrendDirection.up
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  trend == TrendDirection.up
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: trend == TrendDirection.up
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Spacing
                    SizedBox(height: isNarrow ? 12 : 16),

                    // Value - with responsive font sizing
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: isNarrow ? 24 : 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Spacing
                    SizedBox(height: isNarrow ? 4 : 6),

                    // Title - with text overflow handling
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isNarrow ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Spacing
                    SizedBox(height: isNarrow ? 2 : 4),

                    // Subtitle - with text overflow handling
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isNarrow ? 11 : 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Alternative compact version for very small screens
class CompactAdminStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TrendDirection? trend;
  final VoidCallback? onTap;

  const CompactAdminStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title and value in one line
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (trend != null && trend != TrendDirection.neutral)
                            Icon(
                              trend == TrendDirection.up
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: trend == TrendDirection.up
                                  ? Colors.green[600]
                                  : Colors.red[600],
                              size: 14,
                            ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // Value
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Subtitle
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
