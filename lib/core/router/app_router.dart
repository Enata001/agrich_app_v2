import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/new_password_screen.dart';
import '../../features/auth/presentation/phone_sign_in_screen.dart';
import '../../features/chat/presentation/chatbot_screen.dart';
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
import '../../features/weather/presentation/weather_details_screen.dart';
import '../../index_screen.dart';
import 'app_routes.dart';
import 'route_transitions.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static void push(String location, {dynamic extra}) {
    _rootNavigatorKey.currentContext?.push(location, extra: extra);
  }

  static GoRouter get router => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,


    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.otpVerification,
        name: 'otpVerification',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            // Fallback if no extra data provided
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Invalid verification data')),
              ),
              transitionsBuilder: RouteTransitions.slidePullBackTransition,
            );
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: OtpVerificationScreen(
              verificationId: extra['verificationId'] as String,
              phoneNumber: extra['phoneNumber'] as String,
              resendToken: extra['resendToken'] as int?,

              isSignUp: extra['isSignUp'] as bool? ?? false,
              verificationType:
                  extra['verificationType'] as String? ?? 'signIn',
            ),
            transitionsBuilder: RouteTransitions.slideTransition,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.main,
        name: 'main',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.videoPlayer,
        name: 'video-player',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};

          return CustomTransitionPage(
            key: state.pageKey,
            child: VideoPlayerScreen(
              videoUrl: extra['videoUrl'] ?? extra['youtubeUrl'] ?? '',
              videoTitle: extra['videoTitle'] ?? 'Video',
              videoId: extra['videoId'],
              youtubeVideoId: extra['youtubeVideoId'],
              description: extra['description'],
              videoData: extra,
            ),
            transitionsBuilder: RouteTransitions.slideTransition,
          );
        },
      ),

      GoRoute(
        path: '${AppRoutes.videoPlayer}/:videoId',
        name: 'video-player-with-id',
        pageBuilder: (context, state) {
          final videoId = state.pathParameters['videoId'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};

          return CustomTransitionPage(
            key: state.pageKey,
            child: VideoPlayerScreen(
              videoUrl: extra['videoUrl'] ?? extra['youtubeUrl'] ?? '',
              videoTitle: extra['videoTitle'] ?? 'Video',
              videoId: videoId,
              youtubeVideoId: extra['youtubeVideoId'],
              description: extra['description'],
              videoData: extra,
            ),
            transitionsBuilder: RouteTransitions.slideTransition,
          );
        },
      ),

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
            transitionsBuilder: RouteTransitions.slidePullBackTransition,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.createPost,
        name: 'create-post',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreatePostScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.postDetails,
        name: 'post-details',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: PostDetailsScreen(postId: extra['postId'] as String? ?? ''),
            transitionsBuilder: RouteTransitions.slidePullBackTransition,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.chatList,
        name: 'chat-list',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChatListScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

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
              recipientAvatar: extra['recipientAvatar'],
            ),
            transitionsBuilder: RouteTransitions.slidePullBackTransition,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.phoneSignIn,
        name: 'phone-signin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneSignInScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
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
              phoneNumber: extra['phoneNumber'] as String? ?? '',
              verificationId: extra['verificationId'] as String?,
              verifiedOtp: extra['verifiedOtp']as String,
            ),
            transitionsBuilder: RouteTransitions.slidePullBackTransition,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.weatherDetails,
        name: 'weather-details',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeatherDetailsScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.chatbot,
        name: 'chatbot',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChatbotScreen(),
          transitionsBuilder: RouteTransitions.slidePullBackTransition,
        ),
      ),
    ],

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
