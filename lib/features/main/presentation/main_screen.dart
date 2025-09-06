import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../shared/widgets/custom_navigation_bar.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../tips/presentation/tips_screen.dart';
import '../../videos/presentation/videos_main_screen.dart';

final mainScreenIndexProvider = StateProvider<int>((ref) => 0);

class NavigationTab {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget page;

  NavigationTab({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.page,
  });
}

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
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          ref.read(mainScreenIndexProvider.notifier).state = index;
        },
        children: _tabs.map((tab) => tab.page).toList(),
      ),
      bottomNavigationBar: CustomNavigationBar(
        floating: false,
        currentIndex: currentIndex,
        items: _tabs.map((tab) => CustomNavigationBarItem(
          icon: tab.icon,
          activeIcon: tab.activeIcon,
          label: tab.label,
        )).toList(),
        onTap: (index) {
          ref.read(mainScreenIndexProvider.notifier).state = index;
          _pageController.jumpToPage(
            index,
          );
        },
      ),
    );
  }
}