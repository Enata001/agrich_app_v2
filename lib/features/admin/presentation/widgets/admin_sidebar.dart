// lib/features/admin/presentation/widgets/admin_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

import '../../../main/presentation/main_screen.dart';
import '../../providers/admin_providers.dart';
import '../screens/admin_main_screen.dart';

class AdminSidebar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final pendingReportsCount = ref.watch(pendingReportsCountProvider);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Admin Header
          _buildAdminHeader(context, currentUser),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: adminTabs.length,
              itemBuilder: (context, index) {
                return _buildNavigationItem(
                  context,
                  adminTabs[index],
                  index,
                  currentIndex == index,
                  pendingReportsCount,
                );
              },
            ),
          ),

          // Admin Stats Summary
          _buildStatsSection(ref),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // App Logo/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),

          // Admin Info
          Text(
            'Admin Panel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.displayName ?? user?.email ?? 'Administrator',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
      BuildContext context,
      NavigationTab tab,
      int index,
      bool isSelected,
      int pendingReportsCount,
      ) {
    final showBadge = tab.label == 'Dashboard' && pendingReportsCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? (tab.activeIcon ?? tab.icon) : tab.icon,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (showBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pendingReportsCount > 99 ? '99+' : pendingReportsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Quick Stats',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => Column(
              children: [
                _buildQuickStat('Users', stats.totalUsers, Icons.people),
                _buildQuickStat('Tips', stats.totalTips, Icons.lightbulb),
                _buildQuickStat('Videos', stats.totalVideos, Icons.video_library),
                if (stats.pendingReports > 0)
                  _buildQuickStat('Reports', stats.pendingReports, Icons.report,
                      color: Colors.red),
              ],
            ),
            loading: () => const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Text(
              'Failed to load stats',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value > 999 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AgriCH Admin v2.0',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Enhanced Custom Navigation Bar for Mobile
class CustomNavigationBar extends StatelessWidget {
  final List<NavigationTab> tabs;
  final int currentIndex;
  final Function(int) onTap;
  final Color? backgroundColor;

  const CustomNavigationBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? (tab.activeIcon ?? tab.icon) : tab.icon,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}