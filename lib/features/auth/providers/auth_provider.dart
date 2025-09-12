// lib/features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/app_providers.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

// ==================== CORE PROVIDERS ====================

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, _) => null,
  );
});

final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserProfile(uid);
});

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserProfile(user.uid);
});

final authMethodsProvider = Provider<AuthMethods>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthMethods(authRepository);
});

final phoneVerificationProvider = StateNotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return PhoneVerificationNotifier(authRepository);
});

final signInMethodProvider = FutureProvider.family<SignInMethod, String>((ref, identifier) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.detectSignInMethod(identifier);
});

// ==================== ENHANCED ACCOUNT STATUS PROVIDERS ====================

final accountStatusProvider = FutureProvider<AccountStatus>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getAccountStatus();
});

final isAccountCompleteProvider = Provider<bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.isAccountComplete;
});

final isPhoneLinkedProvider = Provider<bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.isPhoneLinked();
});

final linkedProvidersProvider = Provider<List<String>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getLinkedProviders();
});

// ==================== PHONE VERIFICATION STATE ====================

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

// ==================== PHONE VERIFICATION NOTIFIER ====================

class PhoneVerificationNotifier extends StateNotifier<PhoneVerificationState> {
  final AuthRepository _authRepository;

  PhoneVerificationNotifier(this._authRepository) : super(const PhoneVerificationState());

  /// Start phone verification process
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

  /// Handle automatic verification (Android only)
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    try {
      switch (state.type) {
        case PhoneVerificationType.signIn:
          await _authRepository.signInWithPhoneCredential(credential);
          break;
        case PhoneVerificationType.linkToAccount:
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

  /// Handle verification failure
  void _onVerificationFailed(FirebaseAuthException e) {
    state = state.copyWith(
      isLoading: false,
      error: _getErrorMessage(e),
      step: PhoneVerificationStep.failed,
    );
  }

  /// Handle code sent
  void _onCodeSent(String verificationId, int? resendToken) {
    state = state.copyWith(
      verificationId: verificationId,
      resendToken: resendToken,
      isLoading: false,
      step: PhoneVerificationStep.codeSent,
    );
  }

  /// Handle auto-retrieval timeout
  void _onCodeAutoRetrievalTimeout(String verificationId) {
    if (state.verificationId != verificationId) {
      state = state.copyWith(verificationId: verificationId);
    }
  }

  /// Verify OTP code
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

  /// Resend verification code
  Future<void> resendCode() async {
    if (state.phoneNumber == null) {
      state = state.copyWith(error: 'Phone number not available for resend');
      return;
    }

    await startPhoneVerification(state.phoneNumber!, state.type);
  }

  /// Get user-friendly error message
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
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      default:
        return e.message ?? 'Phone verification failed.';
    }
  }

  /// Reset verification state
  void reset() {
    state = const PhoneVerificationState();
  }
}

// ==================== AUTH METHODS CLASS ====================

class AuthMethods {
  final AuthRepository _authRepository;

  AuthMethods(this._authRepository);

  // ==================== SIGN UP ====================

  /// Enhanced sign up with email/password (maintains existing method name)
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

  // ==================== PHONE LINKING ====================

  /// Link phone credential to email account (direct credential)
  Future<void> linkPhoneCredentialToEmailAccount(PhoneAuthCredential phoneCredential) async {
    await _authRepository.linkPhoneCredentialToEmailAccount(phoneCredential);
  }

  /// Link phone to email account using OTP
  Future<void> linkPhoneToEmailAccount(
      String phoneNumber,
      String verificationId,
      String smsCode,
      ) async {
    await _authRepository.linkPhoneToEmailAccount(phoneNumber, verificationId, smsCode);
  }

  /// Check if phone is linked
  bool isPhoneLinked() {
    return _authRepository.isPhoneLinked();
  }

  /// Get linked providers
  List<String> getLinkedProviders() {
    return _authRepository.getLinkedProviders();
  }

  // ==================== SIGN IN ====================

  /// Detect sign-in method for identifier
  Future<SignInMethod> detectSignInMethod(String identifier) async {
    return await _authRepository.detectSignInMethod(identifier);
  }

  /// Sign in with email/password
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    return await _authRepository.signInWithEmailAndPassword(email, password);
  }

  /// Sign in with phone OTP
  Future<UserCredential> signInWithPhoneOTP(
      String phoneNumber,
      String verificationId,
      String smsCode,
      ) async {
    return await _authRepository.signInWithPhoneOTP(phoneNumber, verificationId, smsCode);
  }

  /// Sign in with phone credential
  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential,
      ) async {
    return await _authRepository.signInWithPhoneCredential(credential);
  }

  // ==================== PASSWORD RESET ====================

  /// Initiate password reset (email or phone)
  Future<void> initiatePasswordReset(String identifier) async {
    await _authRepository.initiatePasswordReset(identifier);
  }

  /// Reset password using phone verification
  Future<void> resetPasswordWithPhone(String phoneNumber, String newPassword) async {
    await _authRepository.resetPasswordWithPhone(phoneNumber, newPassword);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  // ==================== PHONE VERIFICATION ====================

  /// Verify phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {

    try {
      final isFound = await checkPhoneExists(phoneNumber);
      if (!isFound) {
        throw Exception("No Account Found");
      }
    }
    catch(e){
      throw Exception("No Account Found");
    }
    await _authRepository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // ==================== ACCOUNT MANAGEMENT ====================

  /// Complete account verification
  Future<void> completeAccountVerification(String userId) async {
    await _authRepository.completeAccountVerification(userId);
  }

  /// Get account status
  Future<AccountStatus> getAccountStatus() async {
    return await _authRepository.getAccountStatus();
  }

  /// Check if account is complete
  bool get isAccountComplete {
    return _authRepository.isAccountComplete;
  }

  // ==================== EMAIL VERIFICATION ====================

  /// Send email verification
  Future<void> sendEmailVerification() async {
    await _authRepository.sendEmailVerification();
  }

  /// Reload user
  Future<void> reloadUser() async {
    await _authRepository.reloadUser();
  }

  // ==================== USER EXISTENCE CHECKS ====================

  /// Check if user exists
  Future<bool> checkUserExists(String email) async {
    return await _authRepository.checkUserExists(email);
  }

  /// Check if phone exists
  Future<bool> checkPhoneExists(String phoneNumber) async {
    return await _authRepository.checkPhoneExists(phoneNumber);
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _authRepository.updateUserProfile(uid, data);
  }

  /// Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    return await _authRepository.getUserProfile(uid);
  }

  // ==================== SESSION MANAGEMENT ====================

  /// Sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
  }
}

// ==================== AUTH STATE NOTIFIER ====================

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _authRepository.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  /// Enhanced sign up with validation
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

  /// Enhanced sign in with account validation
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
    } on IncompleteAccountException catch (e, stackTrace) {
      // Handle incomplete account specifically
      state = AsyncValue.error(e, stackTrace);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Enhanced phone sign in with validation
  Future<void> signInWithPhone(String phoneNumber, String verificationId, String smsCode) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithPhoneOTP(phoneNumber, verificationId, smsCode);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Complete phone verification for incomplete accounts
  Future<void> completePhoneVerification(
      String phoneNumber,
      String verificationId,
      String smsCode,
      ) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.linkPhoneToEmailAccount(phoneNumber, verificationId, smsCode);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// ==================== PROVIDER IMPLEMENTATIONS ====================

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

// ==================== CONVENIENCE PROVIDERS ====================

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

// ==================== OPERATION PROVIDERS ====================

final profileUpdateProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');

  final authRepository = ref.watch(authRepositoryProvider);
  await authRepository.updateUserProfile(user.uid, data);
});

final emailVerificationProvider = FutureProvider<void>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  await authRepository.sendEmailVerification();
});

final passwordResetProvider = FutureProvider.family<void, String>((ref, identifier) async {
  final authRepository = ref.watch(authRepositoryProvider);
  await authRepository.initiatePasswordReset(identifier);
});

// ==================== VALIDATION PROVIDERS ====================

final userExistsProvider = FutureProvider.family<bool, String>((ref, email) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.checkUserExists(email);
});

final phoneExistsProvider = FutureProvider.family<bool, String>((ref, phoneNumber) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.checkPhoneExists(phoneNumber);
});

// ==================== ACCOUNT COMPLETION PROVIDERS ====================

final accountCompletionProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;

  final userProfile = await ref.watch(currentUserProfileProvider.future);
  if (userProfile == null) return 0.1;

  double completion = 0.0;

  // Email verified
  if (user.emailVerified) completion += 0.3;

  // Phone verified
  if (userProfile.isPhoneVerified) completion += 0.4;

  // Profile picture
  if (userProfile.profilePictureUrl!.isNotEmpty) completion += 0.1;

  // Bio
  if (userProfile.bio != null && userProfile.bio!.isNotEmpty) completion += 0.1;

  // Location
  if (userProfile.location != null && userProfile.location!.isNotEmpty) completion += 0.1;

  return completion;
});

final incompleteAccountDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final accountStatus = await ref.watch(accountStatusProvider.future);

  if (accountStatus == AccountStatus.pendingPhoneVerification) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      final userProfile = await ref.watch(currentUserProfileProvider.future);
      if (userProfile != null) {
        return {
          'userId': user.uid,
          'phoneNumber': userProfile.phoneNumber,
          'email': userProfile.email,
          'username': userProfile.username,
        };
      }
    }
  }

  return null;
});

// ==================== ERROR HANDLING PROVIDERS ====================

final authErrorProvider = StateProvider<String?>((ref) => null);

final clearAuthErrorProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(authErrorProvider.notifier).state = null;
  };
});

// ==================== PHONE VERIFICATION HELPERS ====================

final canResendCodeProvider = StateProvider<bool>((ref) => false);

final resendCountdownProvider = StateProvider<int>((ref) => 0);

final startResendTimerProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(canResendCodeProvider.notifier).state = false;
    ref.read(resendCountdownProvider.notifier).state = 60;

    // Timer would be handled in the UI
  };
});

// ==================== PHONE NUMBER FORMATTING ====================

final formatPhoneNumberProvider = Provider<String Function(String)>((ref) {
  return (String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Add Ghana country code if not present
    if (!cleaned.startsWith('233') && cleaned.length == 10) {
      cleaned = '233$cleaned';
    }

    // Add + prefix if not present
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  };
});

// ==================== VALIDATION HELPERS ====================

final validatePhoneNumberProvider = Provider<bool Function(String)>((ref) {
  return (String phoneNumber) {
    final formatter = ref.read(formatPhoneNumberProvider);
    final formatted = formatter(phoneNumber);

    // Basic validation for Ghana numbers
    return formatted.startsWith('+233') && formatted.length == 13;
  };
});

final validateEmailProvider = Provider<bool Function(String)>((ref) {
  return (String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  };
});

final validatePasswordProvider = Provider<Map<String, bool> Function(String)>((ref) {
  return (String password) {
    return {
      'minLength': password.length >= 6,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumbers': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChar': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  };
});