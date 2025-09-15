import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/config/app_config.dart';
import '../../../../core/config/utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/network_service.dart';
import '../../../shared/widgets/custom_navigation_bar.dart';
import '../../data/models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_chart_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsAutoRefreshProvider);
    final reportsAsync = ref.watch(adminReportsProvider);
    final logsAsync = ref.watch(adminLogsProvider);
    final networkStatus = ref.watch(networkStatusProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, ref, networkStatus),
      body: statsAsync.when(
        data: (stats) => _buildDashboard(context, ref, stats, reportsAsync, logsAsync, networkStatus),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, AsyncValue<bool> networkStatus) {
    return AppBar(
      title: const Text(
        'Admin Dashboard',

        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Network status indicator
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Center(
            child: networkStatus.when(
              data: (isConnected) => Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? Colors.white : Colors.red[200],
                size: 20,
              ),
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              error: (_, _) => Icon(Icons.wifi_off, color: Colors.red[200], size: 20),
            ),
          ),
        ),
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
      ],
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header shimmer
          _buildHeaderShimmer(),
          const SizedBox(height: 20),

          // Stats cards shimmer
          _buildStatsCardsShimmer(),
          const SizedBox(height: 24),

          // Charts shimmer
          _buildChartsShimmer(),
        ],
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 200, height: 24, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 300, height: 16, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildQuickOverviewShimmer(),
              const SizedBox(width: 24),
              _buildQuickOverviewShimmer(),
              const SizedBox(width: 24),
              _buildQuickOverviewShimmer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOverviewShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: 60, height: 28, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 4),
        ShimmerBox(width: 80, height: 14, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _buildStatsCardsShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
          context,
          mobile: 2,
          tablet: 4,
          desktop: 4,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 20, height: 20, borderRadius: BorderRadius.circular(12)),
                    const Spacer(),
                    ShimmerBox(width: 60, height: 16, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
                const Spacer(),
                ShimmerBox(width: 80, height: 32, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 8),
                ShimmerBox(width: 120, height: 14, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartsShimmer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 150, height: 20, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: 200, borderRadius: BorderRadius.circular(8)),
            ],
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
      AsyncValue<bool> networkStatus,
      ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(adminReportsProvider);
        ref.invalidate(adminLogsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network status banner
            networkStatus.when(
              data: (isConnected) => !isConnected
                  ? FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.red[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Internet Connection',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Dashboard may show cached data. Check connection for real-time updates.',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, StackTrace _) => const SizedBox.shrink(),
            ),

            // Dashboard Header
            _buildDashboardHeader(context, stats),
            const SizedBox(height: 24),

            // Key Metrics
            _buildKeyMetrics(context, stats),
            const SizedBox(height: 24),

            // Charts Section
            _buildChartsSection(context, stats),
            const SizedBox(height: 24),

            // Recent Activity Section
            _buildRecentActivitySection(context, reportsAsync, logsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context, AdminStats stats) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Here\'s what\'s happening with AgriCH today',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Overview - Responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Mobile layout - vertical stack
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildQuickOverviewItem('Active Users', stats.activeUsersToday)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildQuickOverviewItem('New Users', stats.newUsersToday)),
                      _buildQuickOverviewItem('Reports', stats.pendingReports,
                          color: stats.pendingReports > 0 ? Colors.orange : null),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Desktop/Tablet layout - horizontal
                  return Row(
                    children: [
                      _buildQuickOverviewItem('Active Users', stats.activeUsersToday),
                      const SizedBox(width: 4),
                      _buildQuickOverviewItem('New Users', stats.newUsersToday),
                      const SizedBox(width: 4),
                      _buildQuickOverviewItem('Reports', stats.pendingReports,
                          color: stats.pendingReports > 0 ? Colors.orange : null),
                    ],
                  );
                }
              },
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: (color ?? Colors.white).withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetrics(BuildContext context, AdminStats stats) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid layout
          final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
            context,
            mobile: 2,
            tablet: 4,
            desktop: 4,
          );

          // Adjust aspect ratio based on screen size
          final aspectRatio = constraints.maxWidth < 600 ? 1.1 : 1.3;

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
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
          );
        },
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

          // Responsive charts layout
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                // Mobile layout - vertical stack
                return Column(
                  children: [
                    AdminChartCard(
                      title: 'User Growth',
                      child: AdminUserGrowthChart(
                        newUsersToday: stats.newUsersToday,
                        newUsersWeek: stats.newUsersWeek,
                        newUsersMonth: stats.newUsersMonth,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminChartCard(
                      title: 'Content Distribution',
                      child: AdminContentDistributionChart(
                        tips: stats.totalTips,
                        videos: stats.totalVideos,
                        posts: stats.totalPosts,
                      ),
                    ),
                  ],
                );
              } else {
                // Desktop layout - side by side
                return Row(
                  children: [
                    Expanded(
                      child: AdminChartCard(
                        title: 'User Growth',
                        child: AdminUserGrowthChart(
                          newUsersToday: stats.newUsersToday,
                          newUsersWeek: stats.newUsersWeek,
                          newUsersMonth: stats.newUsersMonth,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdminChartCard(
                        title: 'Content Distribution',
                        child: AdminContentDistributionChart(
                          tips: stats.totalTips,
                          videos: stats.totalVideos,
                          posts: stats.totalPosts,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
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
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Recent reports and logs
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                // Mobile layout - vertical stack
                return Column(
                  children: [
                    _buildRecentReportsCard(reportsAsync, context),
                    const SizedBox(height: 16),
                    _buildRecentLogsCard(logsAsync, context),
                  ],
                );
              } else {
                // Desktop layout - side by side
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRecentReportsCard(reportsAsync, context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRecentLogsCard(logsAsync, context)),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsCard(AsyncValue<List<ContentReport>> reportsAsync, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Reports',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          reportsAsync.when(
            data: (reports) => reports.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No recent reports',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.take(3).length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final report = reports[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Icon(Icons.warning, color: Colors.red[700], size: 18),
                  ),
                  title: Text(
                    report.reason.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'By ${report.reporterName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  trailing: Text(
                    timeago.format(report.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                );
              },
            ),
            loading: () => _buildListShimmer(),
            error: (_, _) => const Center(
              child: Text(
                'Error loading reports',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogsCard(AsyncValue<List<AdminActionLog>> logsAsync, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Admin Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          logsAsync.when(
            data: (logs) => logs.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.take(3).length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(_getActionIcon(log.actionType), color: Colors.green[700], size: 18),
                  ),
                  title: Text(
                    log.actionType.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    log.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    timeago.format(log.timestamp),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                );
              },
            ),
            loading: () => _buildListShimmer(),
            error: (_, StackTrace _) => const Center(
              child: Text(
                'Error loading activity',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListShimmer() {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ShimmerBox(width: 40, height: 40, borderRadius: BorderRadius.circular(20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 4),
                  ShimmerBox(width: 120, height: 12, borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ),
            ShimmerBox(width: 60, height: 12, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      )),
    );
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

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dashboard Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load dashboard data. Please check your connection and try again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(adminStatsProvider);
                  ref.invalidate(adminReportsProvider);
                  ref.invalidate(adminLogsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

