import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/app_providers.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// User Profile Provider
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserProfile(uid);
});

// Current User Profile Provider
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserProfile(user.uid);
});

// Auth Methods Provider
final authMethodsProvider = Provider<AuthMethods>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthMethods(authRepository);
});

class AuthMethods {
  final AuthRepository _authRepository;

  AuthMethods(this._authRepository);

  // Email & Password Sign In
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    return await _authRepository.signInWithEmailAndPassword(email, password);
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmailAndPassword(
      String email,
      String password,
      String username,
      String phoneNumber,
      ) async {
    return await _authRepository.createUserWithEmailAndPassword(
      email,
      password,
      username,
      phoneNumber,
    );
  }

  // Phone Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _authRepository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential,
      ) async {
    return await _authRepository.signInWithPhoneCredential(credential);
  }

  Future<void> linkEmailWithPhone(
      String email,
      String password,
      PhoneAuthCredential phoneCredential,
      ) async {
    await _authRepository.linkEmailWithPhone(email, password, phoneCredential);
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    await _authRepository.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _authRepository.reloadUser();
  }

  // Check User Exists
  Future<bool> checkUserExists(String email) async {
    return await _authRepository.checkUserExists(email);
  }

  // Sign Out
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
  }

  // Update User Profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _authRepository.updateUserProfile(uid, data);
  }
}

// Auth State Notifier for complex state management
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    // Listen to auth state changes
    _authRepository.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      // State will be updated automatically through the stream
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signUp(
      String email,
      String password,
      String username,
      String phoneNumber,
      ) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.createUserWithEmailAndPassword(
        email,
        password,
        username,
        phoneNumber,
      );
      // State will be updated automatically through the stream
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      // State will be updated automatically through the stream
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
    } catch (e, stackTrace) {
      rethrow;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});