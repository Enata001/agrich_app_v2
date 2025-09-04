import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/new_password_screen.dart';
import '../../features/auth/presentation/phone_sign_in_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/main/presentation/main_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/videos/presentation/video_list_screen.dart';
import '../../features/videos/presentation/video_player_screen.dart';
import '../../features/community/presentation/create_post_screen.dart';
import '../../features/community/presentation/post_details_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../index_screen.dart';
import 'app_routes.dart';
import 'route_transitions.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      // Onboarding Screen
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: RouteTransitions.slideTransition,
        ),

      ),

      // Auth Screen
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      // Forgot Password Screen
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: RouteTransitions.slideTransition,
        ),
      ),

      // OTP Verification Screen
      GoRoute(
        path: AppRoutes.otpVerification,
        name: 'otp-verification',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: OtpVerificationScreen(
              phoneNumber: extra['phoneNumber'] as String? ?? '',
              verificationId: extra['verificationId'] as String? ?? '',
            ),
            transitionsBuilder: RouteTransitions.slidePullBackTransition,
          );
        },
      ),

      // Main Screen (Dashboard with Bottom Navigation)
      GoRoute(
        path: AppRoutes.main,
        name: 'main',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainScreen(),
          transitionsBuilder: RouteTransitions.slideTransition,
        ),
      ),

      // Edit Profile Screen
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      // Video Player Screen
      GoRoute(
        path: AppRoutes.videoPlayer,
        name: 'video-player',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: VideoPlayerScreen(
              videoUrl: extra['videoUrl'] as String? ?? '',
              videoTitle: extra['videoTitle'] as String? ?? '',
            ),
            transitionsBuilder: RouteTransitions.slidePullBackTransition,
          );
        },
      ),

      // Videos List Screen
      GoRoute(
        path: AppRoutes.videosList,
        name: 'videos-list',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: VideosListScreen(
              category: extra['category'] as String? ?? '',
            ),
            transitionsBuilder: RouteTransitions.slideTransition,
          );
        },
      ),

      // Create Post Screen
      GoRoute(
        path: AppRoutes.createPost,
        name: 'create-post',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreatePostScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      // Post Details Screen
      GoRoute(
        path: AppRoutes.postDetails,
        name: 'post-details',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: PostDetailsScreen(postId: extra['postId'] as String? ?? ''),
            transitionsBuilder: RouteTransitions.slideTransition,
          );
        },
      ),

      // Chat List Screen
      GoRoute(
        path: AppRoutes.chatList,
        name: 'chat-list',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChatListScreen(),
          transitionsBuilder: RouteTransitions.slideTransition,
        ),
      ),

      // Individual Chat Screen
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: ChatScreen(
              chatId: extra['chatId'] as String? ?? '',
              recipientName: extra['recipientName'] as String? ?? '',
            ),
            transitionsBuilder: RouteTransitions.slideTransition,
          );
        },
      ),


      GoRoute(
        path: AppRoutes.phoneSignIn,
        name: 'phone-signin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneSignInScreen(),
          transitionsBuilder: RouteTransitions.slideTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.newPassword,
        name: 'new-password',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: NewPasswordScreen(
              phoneNumber: extra['phoneNumber'] as String,
              verificationId: extra['verificationId'] as String?,
            ),
            transitionsBuilder: RouteTransitions.slideTransition,
          );
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.main),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
