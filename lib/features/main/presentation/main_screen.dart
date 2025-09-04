import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/presentation/home_screen.dart';
import '../../community/presentation/community_screen.dart';

import '../../chat/presentation/chat_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../tips/presentation/tips_screen.dart';
import '../../videos/presentation/videos_main_screen.dart';

final mainScreenIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late PageController _pageController;

  final List<NavigationTab> _tabs = [
    NavigationTab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      page: const HomeScreen(),
    ),
    NavigationTab(
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Community',
      page: const CommunityScreen(),
    ),
    NavigationTab(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle,
      label: 'Videos',
      page: const VideosMainScreen(),
    ),
    NavigationTab(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: 'Tips',
      page: const TipsScreen(),
    ),
    NavigationTab(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chats',
      page: const ChatListScreen(),
    ),
    NavigationTab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      page: const ProfileScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainScreenIndexProvider);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          ref.read(mainScreenIndexProvider.notifier).state = index;
        },
        children: _tabs.map((tab) => tab.page).toList(),
      ),
      bottomNavigationBar: _buildBottomNavigation(currentIndex),
    );
  }

  Widget _buildBottomNavigation(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isActive = index == currentIndex;

              return GestureDetector(
                onTap: () => _onTabTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGreen.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        color: isActive ? AppColors.primaryGreen : Colors.grey.shade600,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: isActive ? AppColors.primaryGreen : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    ref.read(mainScreenIndexProvider.notifier).state = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class NavigationTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;

  NavigationTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });
}