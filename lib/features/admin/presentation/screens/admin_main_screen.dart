import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../main/presentation/main_screen.dart';
import '../../../shared/widgets/custom_navigation_bar.dart';
import '../widgets/admin_sidebar.dart' hide CustomNavigationBar;
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_tips_screen.dart';
import 'admin_videos_screen.dart';
import '../../../profile/presentation/profile_screen.dart';

// Admin Navigation Tabs
final List<NavigationTab> adminTabs = [
  NavigationTab(
    icon: Icons.dashboard_rounded,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',

    page: const AdminDashboardScreen(),
  ),
  NavigationTab(
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    label: 'Users',
    page: const AdminUsersScreen(),
  ),
  NavigationTab(
    icon: Icons.lightbulb_outline,
    activeIcon: Icons.lightbulb,
    label: 'Tips',
    page: const AdminTipsScreen(),
  ),
  NavigationTab(
    icon: Icons.video_library_outlined,
    activeIcon: Icons.video_library,
    label: 'Videos',
    page: const AdminVideosScreen(),
  ),
  NavigationTab(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
    page: const ProfileScreen(),
  ),
];

class AdminMainScreen extends ConsumerWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);

    return isTablet
        ? const AdminTabletLayout()
        : const AdminMobileLayout();
  }
}

// Mobile Layout for Admin
class AdminMobileLayout extends ConsumerWidget {
  const AdminMobileLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainScreenIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: adminTabs.map((tab) => tab.page).toList(),
      ),
      bottomNavigationBar: CustomNavigationBar(
       items:  adminTabs.map((tab) => CustomNavigationBarItem(
          icon: tab.icon,
          activeIcon: tab.activeIcon,
          label: tab.label,
        )).toList(),
        currentIndex: currentIndex,
        onTap: (index) => ref.read(mainScreenIndexProvider.notifier).state = index,
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }
}




// Tablet/Desktop Layout for Admin
class AdminTabletLayout extends ConsumerWidget {
  const AdminTabletLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainScreenIndexProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar Navigation
          AdminSidebar(
            currentIndex: currentIndex,
            onTap: (index) => ref.read(mainScreenIndexProvider.notifier).state = index,
          ),
          // Main Content Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: adminTabs[currentIndex].page,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


