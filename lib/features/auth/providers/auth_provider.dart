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
    error: (_, _) => null,
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

// Phone Verification State Provider
final phoneVerificationProvider = StateNotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return PhoneVerificationNotifier(authRepository);
});

// Sign-In Method Detection Provider
final signInMethodProvider = FutureProvider.family<SignInMethod, String>((ref, identifier) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.detectSignInMethod(identifier);
});

// Phone Verification State
class PhoneVerificationState {
  final String? verificationId;
  final String? phoneNumber;
  final int? resendToken;
  final bool isLoading;
  final String? error;
  final PhoneVerificationStep step;
  final PhoneVerificationType type;

  const PhoneVerificationState({
    this.verificationId,
    this.phoneNumber,
    this.resendToken,
    this.isLoading = false,
    this.error,
    this.step = PhoneVerificationStep.initial,
    this.type = PhoneVerificationType.signIn,
  });

  PhoneVerificationState copyWith({
    String? verificationId,
    String? phoneNumber,
    int? resendToken,
    bool? isLoading,
    String? error,
    PhoneVerificationStep? step,
    PhoneVerificationType? type,
  }) {
    return PhoneVerificationState(
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      resendToken: resendToken ?? this.resendToken,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      step: step ?? this.step,
      type: type ?? this.type,
    );
  }
}

enum PhoneVerificationStep {
  initial,
  codeSent,
  verifying,
  verified,
  failed,
}

enum PhoneVerificationType {
  signIn,           // Direct phone sign-in
  linkToAccount,    // Link phone to email account (after sign-up)
  passwordReset,    // Phone verification for password reset
}

// Phone Verification Notifier
class PhoneVerificationNotifier extends StateNotifier<PhoneVerificationState> {
  final AuthRepository _authRepository;

  PhoneVerificationNotifier(this._authRepository) : super(const PhoneVerificationState());

  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    try {
      switch (state.type) {
        case PhoneVerificationType.signIn:
          await _authRepository.signInWithPhoneCredential(credential);
          break;
        case PhoneVerificationType.linkToAccount:
        // 🔥 FIXED: Use the credential directly for linking
          await _authRepository.linkPhoneCredentialToEmailAccount(credential);
          break;
        case PhoneVerificationType.passwordReset:
        // Auto-verification for password reset
          break;
      }

      state = state.copyWith(
        isLoading: false,
        step: PhoneVerificationStep.verified,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        step: PhoneVerificationStep.failed,
      );
    }
  }

  // 🔥 FIXED: OTP verification handling
  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(error: 'No verification ID available');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      step: PhoneVerificationStep.verifying,
    );

    try {
      switch (state.type) {
        case PhoneVerificationType.signIn:
          await _authRepository.signInWithPhoneOTP(
            state.phoneNumber!,
            state.verificationId!,
            otp,
          );
          break;
        case PhoneVerificationType.linkToAccount:
        // 🔥 FIXED: Use proper OTP linking method
          await _authRepository.linkPhoneToEmailAccount(
            state.phoneNumber!,
            state.verificationId!,
            otp,
          );
          break;
        case PhoneVerificationType.passwordReset:
        // For password reset, verification success leads to new password screen
          break;
      }

      state = state.copyWith(
        isLoading: false,
        step: PhoneVerificationStep.verified,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
        step: PhoneVerificationStep.failed,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        step: PhoneVerificationStep.failed,
      );
    }
  }


  Future<void> startPhoneVerification(
      String phoneNumber,
      PhoneVerificationType type,
      ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      phoneNumber: phoneNumber,
      step: PhoneVerificationStep.initial,
      type: type,
    );

    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        step: PhoneVerificationStep.failed,
      );
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    state = state.copyWith(
      isLoading: false,
      error: _getErrorMessage(e),
      step: PhoneVerificationStep.failed,
    );
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    state = state.copyWith(
      verificationId: verificationId,
      resendToken: resendToken,
      isLoading: false,
      step: PhoneVerificationStep.codeSent,
    );
  }

  void _onCodeAutoRetrievalTimeout(String verificationId) {
    if (state.verificationId != verificationId) {
      state = state.copyWith(verificationId: verificationId);
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'session-expired':
        return 'The verification session has expired.';
      default:
        return e.message ?? 'Phone verification failed.';
    }
  }

  void reset() {
    state = const PhoneVerificationState();
  }
}

// Auth Methods Class - Matches Your Exact Logic
class AuthMethods {
  final AuthRepository _authRepository;

  AuthMethods(this._authRepository);




  // YOUR LOGIC: Sign up with email/password (keeps existing method name)
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


  Future<void> linkPhoneCredentialToEmailAccount(PhoneAuthCredential phoneCredential) async {
    await _authRepository.linkPhoneCredentialToEmailAccount(phoneCredential);
  }

  Future<void> linkPhoneToEmailAccount(
      String phoneNumber,
      String verificationId,
      String smsCode,
      ) async {
    await _authRepository.linkPhoneToEmailAccount(phoneNumber, verificationId, smsCode);
  }

  // 🔥 NEW: Helper methods
  bool isPhoneLinked() {
    return _authRepository.isPhoneLinked();
  }

  List<String> getLinkedProviders() {
    return _authRepository.getLinkedProviders();
  }

  // YOUR LOGIC: Detect if identifier is email or phone
  Future<SignInMethod> detectSignInMethod(String identifier) async {
    return await _authRepository.detectSignInMethod(identifier);
  }

  // YOUR LOGIC: Sign in with email/password
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    return await _authRepository.signInWithEmailAndPassword(email, password);
  }

  // YOUR LOGIC: Sign in with phone/OTP
  Future<UserCredential> signInWithPhoneOTP(
      String phoneNumber,
      String verificationId,
      String smsCode,
      ) async {
    return await _authRepository.signInWithPhoneOTP(phoneNumber, verificationId, smsCode);
  }

  // YOUR LOGIC: Initiate password reset (email or phone)
  Future<void> initiatePasswordReset(String identifier) async {
    await _authRepository.initiatePasswordReset(identifier);
  }

  // YOUR LOGIC: Reset password using phone verification
  Future<void> resetPasswordWithPhone(String phoneNumber, String newPassword) async {
    await _authRepository.resetPasswordWithPhone(phoneNumber, newPassword);
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

  // Password Reset via Email
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

  // Check User/Phone Exists
  Future<bool> checkUserExists(String email) async {
    return await _authRepository.checkUserExists(email);
  }

  Future<bool> checkPhoneExists(String phoneNumber) async {
    return await _authRepository.checkPhoneExists(phoneNumber);
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

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    return await _authRepository.getUserProfile(uid);
  }
}

// Auth State Notifier for complex state management
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _authRepository.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  // YOUR LOGIC: Sign up with email+password+phone
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
      // UI should then trigger phone verification
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // YOUR LOGIC: Sign in with email/password
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // YOUR LOGIC: Sign in with phone/OTP
  Future<void> signInWithPhone(String phoneNumber, String verificationId, String smsCode) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithPhoneOTP(phoneNumber, verificationId, smsCode);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Auth State Notifier Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

// Convenience providers for common auth operations
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, _) => false,
  );
});

final isEmailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailVerified ?? false;
});

final isPhoneVerifiedProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider);
  return userProfile.when(
    data: (profile) => profile?.isPhoneVerified ?? false,
    loading: () => false,
    error: (_, _) => false,
  );
});

final hasLinkedAccountsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  // Check if user has both email and phone providers
  final providers = user.providerData.map((p) => p.providerId).toList();
  return providers.contains('password') && providers.contains('phone');
});

final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

// Profile update provider
final profileUpdateProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');

  final authRepository = ref.watch(authRepositoryProvider);
  await authRepository.updateUserProfile(user.uid, data);
});

// Email verification provider
final emailVerificationProvider = FutureProvider<void>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  await authRepository.sendEmailVerification();
});

// Password reset providers
final passwordResetProvider = FutureProvider.family<void, String>((ref, identifier) async {
  final authRepository = ref.watch(authRepositoryProvider);
  await authRepository.initiatePasswordReset(identifier);
});

// User/Phone existence check providers
final userExistsProvider = FutureProvider.family<bool, String>((ref, email) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.checkUserExists(email);
});

final phoneExistsProvider = FutureProvider.family<bool, String>((ref, phoneNumber) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.checkPhoneExists(phoneNumber);
});
