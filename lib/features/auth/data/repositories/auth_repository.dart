import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  AuthRepository(
      this._firebaseAuth,
      this._firebaseService,
      this._localStorageService,
      );

  // Auth state stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Current user
  User? get currentUser => _firebaseAuth.currentUser;

  bool get isSignedIn => (_localStorageService.getUserData() != null);

  // YOUR LOGIC: Sign-up with Email + Password + Phone (phone verification comes next)
  Future<UserCredential> createUserWithEmailAndPassword(
      String email,
      String password,
      String username,
      String phoneNumber,
      ) async {
    try {
      // Step 1: Create email/password account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(username);

        // Step 2: Create user profile in Firestore (phone NOT verified yet)
        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          username: username,
          phoneNumber: phoneNumber, // Store phone number
          profilePictureUrl: '',
          bio: '',
          location: '',
          joinedAt: DateTime.now(),
          isEmailVerified: credential.user!.emailVerified,
          isPhoneVerified: false, // Will be verified in next step
        );

        await _firebaseService.createUser(userModel.id, userModel.toMap());
        await _cacheUserData(credential.user!);
        await _cacheUserProfile(userModel);

        // NOTE: Phone verification will be triggered by UI after this
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> linkPhoneCredentialToEmailAccount(PhoneAuthCredential phoneCredential) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user signed in to link phone');

      // Check if phone provider is already linked
      final isPhoneLinked = user.providerData.any((provider) => provider.providerId == 'phone');
      if (isPhoneLinked) {
        throw Exception('Phone number is already linked to this account');
      }

      // Link phone credential to current email account
      await user.linkWithCredential(phoneCredential);

      // Update user profile to mark phone as verified
      await updateUserProfile(user.uid, {
        'isPhoneVerified': true,
        'phoneNumber': user.phoneNumber, // Firebase sets this after linking
      });

      // Update cached data
      await _cacheUserData(user);
      await _syncUserProfile(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 🔥 FIXED: OTP-based phone linking
  Future<void> linkPhoneToEmailAccount(
      String phoneNumber,
      String verificationId,
      String smsCode,
      ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user signed in to link phone');

      // Check if phone provider is already linked
      final isPhoneLinked = user.providerData.any((provider) => provider.providerId == 'phone');
      if (isPhoneLinked) {
        throw Exception('Phone number is already linked to this account');
      }

      // Create phone credential from OTP
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Link phone to current email account
      await user.linkWithCredential(phoneCredential);

      // Update user profile to mark phone as verified
      await updateUserProfile(user.uid, {
        'isPhoneVerified': true,
        'phoneNumber': phoneNumber,
      });

      // Update cached data
      await _cacheUserData(user);
      await _syncUserProfile(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 🔥 NEW: Check if phone is already linked
  bool isPhoneLinked() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    return user.providerData.any((provider) => provider.providerId == 'phone');
  }

  // 🔥 NEW: Get linked providers
  List<String> getLinkedProviders() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];

    return user.providerData.map((provider) => provider.providerId).toList();
  }



  // YOUR LOGIC: Detect if identifier is email or phone and check existence
  Future<SignInMethod> detectSignInMethod(String identifier) async {
    if (identifier.contains('@')) {
      // It's an email
      final userExists = await checkUserExists(identifier);
      return userExists ? SignInMethod.email : SignInMethod.none;
    } else {
      // It's a phone number, check in Firestore
      final phoneExists = await checkPhoneExists(identifier);
      return phoneExists ? SignInMethod.phone : SignInMethod.none;
    }
  }

  // YOUR LOGIC: Check if phone number exists in Firestore
  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      final querySnapshot = await _firebaseService.getUserByPhone(phoneNumber);
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // YOUR LOGIC: Sign in with Email/Password
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _cacheUserData(credential.user!);
        await _syncUserProfile(credential.user!);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // YOUR LOGIC: Sign in with Phone/OTP
  Future<UserCredential> signInWithPhoneOTP(
      String phoneNumber,
      String verificationId,
      String smsCode,
      ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _cacheUserData(userCredential.user!);
        await _syncUserProfile(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // YOUR LOGIC: Forgot password - Email OR Phone
  Future<void> initiatePasswordReset(String identifier) async {
    if (identifier.contains('@')) {
      // Email reset
      await sendPasswordResetEmail(identifier);
    } else {
      // Phone reset - verify phone first, then allow password change
      final phoneExists = await checkPhoneExists(identifier);
      if (!phoneExists) {
        throw Exception('Phone number not found');
      }
      // Phone verification will be handled by UI, then resetPasswordWithPhone
    }
  }

  // YOUR LOGIC: Reset password using phone verification
  Future<void> resetPasswordWithPhone(
      String phoneNumber,
      String newPassword,
      ) async {
    try {
      // Get user by phone number from Firestore
      final querySnapshot = await _firebaseService.getUserByPhone(phoneNumber);
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Phone number not found');
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;
      final userId = userData['id'] as String;

      // Get current user (should be signed in via phone at this point)
      final user = _firebaseAuth.currentUser;
      if (user == null || user.uid != userId) {
        throw Exception('User not properly authenticated via phone');
      }

      // Update password
      await user.updatePassword(newPassword);

      // Update in Firestore
      await _firebaseService.updateUser(user.uid, {
        'passwordUpdatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Phone Authentication (used for all phone verification scenarios)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Helper method for direct phone credential sign-in
  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential,
      ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _cacheUserData(userCredential.user!);
        await _syncUserProfile(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Modern user existence check for email
  Future<bool> checkUserExists(String email) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: 'temp_check_${DateTime.now().millisecondsSinceEpoch}',
      );

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
      }

      return false;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return true;
        case 'invalid-email':
          throw Exception('Invalid email format');
        default:
          return await _checkUserExistsWithPasswordReset(email);
      }
    } catch (e) {
      return await _checkUserExistsWithPasswordReset(email);
    }
  }

  Future<bool> _checkUserExistsWithPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return false;
        case 'invalid-email':
          throw Exception('Invalid email format');
        default:
          return true;
      }
    } catch (e) {
      return true;
    }
  }

  // Password Reset via Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _localStorageService.clearUserData();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final cachedProfile = _getCachedUserProfile();
      if (cachedProfile != null && cachedProfile.id == uid) {
        return cachedProfile;
      }

      final doc = await _firebaseService.getUser(uid);
      if (doc.exists) {
        print(doc.data() as Map<String, dynamic>);
        final userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        await _cacheUserProfile(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      return _getCachedUserProfile();
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firebaseService.updateUser(uid, data);

      final cachedProfile = _getCachedUserProfile();
      if (cachedProfile != null && cachedProfile.id == uid) {
        final updatedProfile = UserModel(
          id: cachedProfile.id,
          email: data['email'] ?? cachedProfile.email,
          username: data['username'] ?? cachedProfile.username,
          phoneNumber: data['phoneNumber'] ?? cachedProfile.phoneNumber,
          profilePictureUrl: data['profilePictureUrl'] ?? cachedProfile.profilePictureUrl,
          bio: data['bio'] ?? cachedProfile.bio,
          location: data['location'] ?? cachedProfile.location,
          joinedAt: cachedProfile.joinedAt,
          isEmailVerified: data['isEmailVerified'] ?? cachedProfile.isEmailVerified,
          isPhoneVerified: data['isPhoneVerified'] ?? cachedProfile.isPhoneVerified,
        );
        await _cacheUserProfile(updatedProfile);
      }

      final currentUserData = _localStorageService.getUserData();
      if (currentUserData != null) {
        currentUserData.addAll(data);
        await _localStorageService.setUserData(currentUserData);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reload User
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _cacheUserData(user);
        await _syncUserProfile(user);
      }
    } catch (e) {
      // Ignore reload errors
    }
  }

  // Delete User Account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firebaseService.deleteUser(user.uid);
        await user.delete();
        await _localStorageService.clearUserData();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Private helper methods
  Future<void> _cacheUserData(User user) async {
    final userData = {
      'id': user.uid,
      'email': user.email,
      'username': user.displayName,
      'phoneNumber': user.phoneNumber,
      'profilePictureUrl': user.photoURL,
      'isEmailVerified': user.emailVerified,
      'lastSignIn': DateTime.now().toIso8601String(),
    };
    await _localStorageService.setUserData(userData);
  }

  Future<void> _cacheUserProfile(UserModel userModel) async {
    await _localStorageService.setUserData(userModel.toMap());
  }

  UserModel? _getCachedUserProfile() {
    try {
      final profileJson = _localStorageService.getUserData();
      print(profileJson);
      if (profileJson != null) {
        return UserModel.fromMap(profileJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _syncUserProfile(User user) async {
    try {
      final doc = await _firebaseService.getUser(user.uid);
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        await _cacheUserProfile(userModel);
      }
    } catch (e) {
      // Ignore sync errors
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'requires-recent-login':
        return 'This operation is sensitive and requires recent authentication.';
      case 'provider-already-linked':
        return 'This account is already linked with this provider.';
      case 'invalid-credential':
        return 'The provided credential is invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'missing-phone-number':
        return 'Phone number is required for phone authentication.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'session-expired':
        return 'The verification session has expired. Please try again.';
      case 'missing-verification-code':
        return 'Please enter the verification code.';
      case 'missing-verification-id':
        return 'Verification ID is missing.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

// Sign-in method enum
enum SignInMethod {
  email,
  phone,
  none,
}