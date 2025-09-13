import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/config/app_config.dart';
import '../../../../core/config/utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../data/models/admin_models.dart';
import '../../providers/admin_providers.dart';

import '../widgets/admin_stats_card.dart';
import '../widgets/admin_chart_widgets.dart';
import 'admin_main_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsAutoRefreshProvider);
    final reportsAsync = ref.watch(adminReportsProvider);
    final logsAsync = ref.watch(adminLogsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, ref),
      body: statsAsync.when(
        data: (stats) => _buildDashboard(context, ref, stats, reportsAsync, logsAsync),
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text(
        'Admin Dashboard',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Refresh Button
        IconButton(
          onPressed: () {
            ref.invalidate(adminStatsProvider);
            ref.invalidate(adminReportsProvider);
            ref.invalidate(adminLogsProvider);
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
        ),
        // Time Display
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              DateFormat('MMM dd, HH:mm').format(DateTime.now()),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(
      BuildContext context,
      WidgetRef ref,
      AdminStats stats,
      AsyncValue<List<ContentReport>> reportsAsync,
      AsyncValue<List<AdminActionLog>> logsAsync,
      ) {
    final isTablet = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(adminReportsProvider);
        ref.invalidate(adminLogsProvider);
      },
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(context, stats),
            const SizedBox(height: 24),

            // Key Metrics Cards
            _buildKeyMetrics(context, stats),
            const SizedBox(height: 24),

            // Charts and Analytics
            if (isTablet) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildChartsSection(context, stats)),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildSidePanel(context, reportsAsync, logsAsync)),
                ],
              ),
            ] else ...[
              _buildChartsSection(context, stats),
              const SizedBox(height: 24),
              _buildSidePanel(context, reportsAsync, logsAsync),
            ],

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, AdminStats stats) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good Morning' :
    now.hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryGreen.withValues(alpha:0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha:0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, Admin!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Here\'s what\'s happening with AgriCH today',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha:0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Overview
            Row(
              children: [
                _buildQuickOverviewItem('Active Users', stats.activeUsersToday),
                const SizedBox(width: 24),
                _buildQuickOverviewItem('New Users', stats.newUsersToday),
                const SizedBox(width: 24),
                _buildQuickOverviewItem('Reports', stats.pendingReports,
                    color: stats.pendingReports > 0 ? Colors.orange : null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOverviewItem(String label, int value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: (color ?? Colors.white).withValues(alpha:0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetrics(BuildContext context, AdminStats stats) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: [
          AdminStatsCard(
            title: 'Total Users',
            value: stats.totalUsers.toString(),
            subtitle: '+${stats.newUsersWeek} this week',
            icon: Icons.people,
            color: Colors.blue,
            trend: stats.newUsersWeek > 0 ? TrendDirection.up : TrendDirection.neutral,
          ),
          AdminStatsCard(
            title: 'Posts',
            value: stats.totalPosts.toString(),
            subtitle: 'Community content',
            icon: Icons.article,
            color: Colors.green,
          ),
          AdminStatsCard(
            title: 'Tips',
            value: stats.totalTips.toString(),
            subtitle: 'Educational content',
            icon: Icons.lightbulb,
            color: Colors.orange,
          ),
          AdminStatsCard(
            title: 'Videos',
            value: stats.totalVideos.toString(),
            subtitle: 'Learning resources',
            icon: Icons.video_library,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, AdminStats stats) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // User Growth Chart
          AdminChartCard(
            title: 'User Growth',
            child: AdminUserGrowthChart(
              newUsersToday: stats.newUsersToday,
              newUsersWeek: stats.newUsersWeek,
              newUsersMonth: stats.newUsersMonth,
            ),
          ),
          const SizedBox(height: 16),

          // Content Distribution
          AdminChartCard(
            title: 'Content Distribution',
            child: AdminContentDistributionChart(
              tips: stats.totalTips,
              videos: stats.totalVideos,
              posts: stats.totalPosts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(
      BuildContext context,
      AsyncValue<List<ContentReport>> reportsAsync,
      AsyncValue<List<AdminActionLog>> logsAsync,
      ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Reports
          _buildRecentReports(context, reportsAsync),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(context, logsAsync),
        ],
      ),
    );
  }

  Widget _buildRecentReports(BuildContext context, AsyncValue<List<ContentReport>> reportsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.report, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to full reports view
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          reportsAsync.when(
            data: (reports) {
              final pendingReports = reports.where((r) => r.status == ReportStatus.pending).take(3).toList();

              if (pendingReports.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 8),
                        Text('No pending reports'),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: pendingReports.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final report = pendingReports[index];
                  return _buildReportItem(report);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Failed to load reports'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(ContentReport report) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.withValues(alpha:0.1),
        child: Icon(
          _getContentTypeIcon(report.contentType),
          color: Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        report.reason.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By ${report.reporterName}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            timeago.format(report.createdAt),
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () {
        // Navigate to report details
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context, AsyncValue<List<AdminActionLog>> logsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity log
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          logsAsync.when(
            data: (logs) {
              final recentLogs = logs.take(5).toList();

              if (recentLogs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No recent activity')),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: recentLogs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = recentLogs[index];
                  return _buildActivityItem(log);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Failed to load activity'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AdminActionLog log) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActionColor(log.actionType).withValues(alpha:0.1),
        child: Icon(
          _getActionIcon(log.actionType),
          color: _getActionColor(log.actionType),
          size: 16,
        ),
      ),
      title: Text(
        log.description,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By ${log.adminName}',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          Text(
            timeago.format(log.timestamp),
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Retry logic
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.post:
        return Icons.article;
      case ContentType.comment:
        return Icons.comment;
      case ContentType.video:
        return Icons.video_library;
      case ContentType.tip:
        return Icons.lightbulb;
      case ContentType.user:
        return Icons.person;
    }
  }

  Color _getActionColor(AdminActionType type) {
    switch (type) {
      case AdminActionType.userSuspended:
        return Colors.red;
      case AdminActionType.userActivated:
        return Colors.green;
      case AdminActionType.postDeleted:
      case AdminActionType.commentDeleted:
        return Colors.orange;
      case AdminActionType.tipCreated:
      case AdminActionType.videoAdded:
        return Colors.blue;
      case AdminActionType.tipUpdated:
      case AdminActionType.videoUpdated:
        return Colors.purple;
      case AdminActionType.tipDeleted:
      case AdminActionType.videoDeleted:
        return Colors.red;
      case AdminActionType.contentReported:
        return Colors.orange;
      case AdminActionType.reportResolved:
        return Colors.green;
    }
  }

  IconData _getActionIcon(AdminActionType type) {
    switch (type) {
      case AdminActionType.userSuspended:
        return Icons.block;
      case AdminActionType.userActivated:
        return Icons.check_circle;
      case AdminActionType.postDeleted:
      case AdminActionType.commentDeleted:
      case AdminActionType.tipDeleted:
      case AdminActionType.videoDeleted:
        return Icons.delete;
      case AdminActionType.tipCreated:
        return Icons.add_circle;
      case AdminActionType.videoAdded:
        return Icons.video_library;
      case AdminActionType.tipUpdated:
      case AdminActionType.videoUpdated:
        return Icons.edit;
      case AdminActionType.contentReported:
        return Icons.report;
      case AdminActionType.reportResolved:
        return Icons.check;
    }
  }
}