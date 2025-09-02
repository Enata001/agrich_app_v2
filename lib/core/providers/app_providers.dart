import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../features/community/data/repositories/community_repository.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/tips/data/repositories/tips_repository.dart';
import '../../features/videos/data/repositories/video_repository.dart';
import '../../features/weather/data/repositories/weather_repository.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../router/app_router.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import '../services/weather_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

// Initialize SharedPreferences
final sharedPreferencesInitProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Core Services Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  final asyncPrefs = ref.watch(sharedPreferencesInitProvider);
  return asyncPrefs.when(
    data: (prefs) => prefs,
    loading: () => throw Exception('SharedPreferences not initialized'),
    error: (error, stack) => throw error,
  );
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(firebaseStorageProvider);
  return FirebaseService(firestore, storage);
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AuthRepository(firebaseAuth, firebaseService, localStorage);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return ProfileRepository(firebaseService, localStorage);
});

final videosRepositoryProvider = Provider<VideosRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return VideosRepository(firebaseService, localStorage);
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return CommunityRepository(firebaseService);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return ChatRepository(firebaseService);
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return WeatherRepository(weatherService, localStorage);
});

final tipsRepositoryProvider = Provider<TipsRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return TipsRepository(firebaseService, localStorage);
});

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth.authStateChanges();
});