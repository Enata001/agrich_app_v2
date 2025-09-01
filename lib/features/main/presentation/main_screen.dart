import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../community/presentation/community_screen.dart';
import '../../shared/widgets/custom_navigation_bar.dart';
import '../../shared/widgets/gradient_background.dart';



final mainScreenIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late ScrollController _scrollController;
  bool _isBottomNavVisible = true;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Community',
      page: const CommunityScreen(),
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chats',
      page: const ChatListScreen(),
    ),
    NavigationItem(
      icon: Icons.person_outlined,
      activeIcon: Icons.person,
      label: 'Profile',
      page: const ProfileScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();

    // Listen to scroll changes to hide/show bottom navigation
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isBottomNavVisible) {
        setState(() => _isBottomNavVisible = false);
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isBottomNavVisible) {
        setState(() => _isBottomNavVisible = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainScreenIndexProvider);

    return CustomScaffold(
      showGradient: false,
      body: Column(
        children: [
          Expanded(
            child: CustomPageView(
              items: _navigationItems,
              controller: _pageController,
              onPageChanged: (index) {
                ref.read(mainScreenIndexProvider.notifier).state = index;
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(
        items: _navigationItems,
        currentIndex: currentIndex,
        isVisible: _isBottomNavVisible,
        onTap: (index) {
          ref.read(mainScreenIndexProvider.notifier).state = index;
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        },
      ),
    );
  }
}