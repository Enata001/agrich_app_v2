import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../shared/widgets/custom_button.dart';


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Learn Modern Farming',
      description: 'Discover the latest techniques and best practices in modern agricultural methods through our comprehensive video tutorials.',
      imagePath: 'assets/images/onboarding_1.png',
      backgroundColor: AppColors.primaryGreen,
    ),
    OnboardingPage(
      title: 'Connect with Community',
      description: 'Join thousands of farmers sharing experiences, asking questions, and supporting each other in the journey.',
      imagePath: 'assets/images/onboarding_2.png',
      backgroundColor: AppColors.accent,
    ),
    OnboardingPage(
      title: 'Get Daily Tips & Weather',
      description: 'Receive personalized farming tips and real-time weather updates to make informed decisions for your crops.',
      imagePath: 'assets/images/onboarding_3.png',
      backgroundColor: AppColors.info,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], index);
            },
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: TextButton(
                onPressed: _completeOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.8),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Skip'),
              ),
            ),
          ),

          // Bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.backgroundColor,
            page.backgroundColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              // Image
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                delay: Duration(milliseconds: 200 * index),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(150),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForPage(index),
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Title
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: Duration(milliseconds: 400 + (200 * index)),
                child: Text(
                  page.title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Description
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: Duration(milliseconds: 600 + (200 * index)),
                child: Text(
                  page.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: WormEffect(
              dotColor: AppColors.border,
              activeDotColor: AppColors.primaryGreen,
              dotHeight: 8,
              dotWidth: 8,
              spacing: 16,
            ),
          ),

          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  child: CustomButton(
                    text: 'Previous',
                    variant: ButtonVariant.outlined,
                    onPressed: _previousPage,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: CustomButton(
                  text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  onPressed: _currentPage == _pages.length - 1
                      ? _completeOnboarding
                      : _nextPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForPage(int index) {
    switch (index) {
      case 0:
        return Icons.agriculture;
      case 1:
        return Icons.people;
      case 2:
        return Icons.wb_sunny;
      default:
        return Icons.eco;
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() {
    final localStorage = ref.read(localStorageServiceProvider);
    localStorage.setBool('onboarding_complete', true);
    context.go(AppRoutes.auth);
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
  });
}