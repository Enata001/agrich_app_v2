import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import 'core/router/app_routes.dart';
import 'features/shared/widgets/loading_indicator.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );


    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  Future<void> _initializeApp() async {
    try {

      await Future.delayed(const Duration(seconds: 3));


      await ref.read(sharedPreferencesInitProvider.future);


      final localStorage = ref.read(localStorageServiceProvider);
      final authRepository = ref.read(authRepositoryProvider);


      final hasOnboarded = localStorage.isOnboardingComplete();

      if (!hasOnboarded) {

        if (mounted) context.go(AppRoutes.onboarding);
        return;
      }


      final isSignedIn = authRepository.isSignedIn;
      final currentUser = authRepository.currentUser;

      if (isSignedIn && currentUser != null) {
        final tipsRepository = ref.read(tipsRepositoryProvider);
        await tipsRepository.initializeDefaultTips();

        if (mounted) context.go(AppRoutes.main);
      } else {

        if (mounted) context.go(AppRoutes.auth);
      }

    } catch (e) {

      if (mounted) context.go(AppRoutes.auth);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),


              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child:Image.asset('assets/images/tree.png'),
                    ),
                  );
                },
              ),


              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'Agrich',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Modern Agricultural Platform',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(),

              // Loading Indicator
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 1000),
                child: const PulsatingDots(
                  color: Colors.white,
                  size: 8,
                ),
              ),

              const SizedBox(height: 40),

              // Version Text
              FadeIn(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 1500),
                child: Text(
                  'Version 2.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}