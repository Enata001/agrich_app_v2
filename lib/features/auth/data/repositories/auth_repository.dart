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

  // Auth State Stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Current User
  User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is already signed in from cache
  bool isUserSignedIn() {
    final userData = _localStorageService.getUserData();
    return userData != null && userData.containsKey('uid');
  }

  // Email & Password Authentication
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

  Future<UserCredential> createUserWithEmailAndPassword(
      String email,
      String password,
      String username,
      String phoneNumber,
      ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(username);

        // Create user profile in Firestore
        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          username: username,
          phoneNumber: phoneNumber,
          profilePictureUrl: null,
          bio: null,
          location: null,
          joinedAt: DateTime.now(),
          isEmailVerified: credential.user!.emailVerified,
          isPhoneVerified: false,
        );

        await _firebaseService.createUser(
          credential.user!.uid,
          userModel.toMap(),
        );

        await _cacheUserData(credential.user!);
        await _cacheUserProfile(userModel);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Phone Authentication
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

  Future<bool> checkUserExists(String email) async {
    try {
      final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      // If user not found, return false
      if (e.code == 'user-not-found') {
        return false;
      }
      throw _handleAuthException(e);
    }
  }

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

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  // Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _localStorageService.clearUserData();
    await _localStorageService.clear(); // Clear all cached data
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firebaseService.users.doc(user.uid).delete();

        // Delete Firebase Auth account
        await user.delete();

        // Clear local data
        await _localStorageService.clear();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      // Try from cache first
      final cachedProfile = _getCachedUserProfile();
      if (cachedProfile != null && cachedProfile.id == uid) {
        return cachedProfile;
      }

      // Fetch from Firebase
      final doc = await _firebaseService.getUser(uid);
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        await _cacheUserProfile(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      // Return cached profile if available
      return _getCachedUserProfile();
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firebaseService.updateUser(uid, data);

      // Update cached user profile
      final cachedProfile = _getCachedUserProfile();
      if (cachedProfile != null) {
        final updatedProfile = UserModel(
          id: cachedProfile.id,
          email: cachedProfile.email,
          username: data['username'] ?? cachedProfile.username,
          phoneNumber: data['phoneNumber'] ?? cachedProfile.phoneNumber,
          profilePictureUrl: data['profilePictureUrl'] ?? cachedProfile.profilePictureUrl,
          bio: data['bio'] ?? cachedProfile.bio,
          location: data['location'] ?? cachedProfile.location,
          joinedAt: cachedProfile.joinedAt,
          isEmailVerified: cachedProfile.isEmailVerified,
          isPhoneVerified: cachedProfile.isPhoneVerified,
        );
        await _cacheUserProfile(updatedProfile);
      }

      // Update cached user data
      final currentUserData = _localStorageService.getUserData();
      if (currentUserData != null) {
        currentUserData.addAll(data);
        await _localStorageService.setUserData(currentUserData);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Private Methods
  Future<void> _cacheUserData(User user) async {
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'phoneNumber': user.phoneNumber,
      'photoURL': user.photoURL,
      'isEmailVerified': user.emailVerified,
      'lastSignIn': DateTime.now().toIso8601String(),
    };
    await _localStorageService.setUserData(userData);
  }

  Future<void> _cacheUserProfile(UserModel userModel) async {
    await _localStorageService.setString('user_profile', userModel.toMap().toString());
  }

  UserModel? _getCachedUserProfile() {
    try {
      final profileString = _localStorageService.getString('user_profile');
      if (profileString != null) {
        // This is a simplified approach - in production, use proper JSON serialization
        return null; // TODO: Implement proper profile caching
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
  Future<void> linkEmailWithPhone(
      String email,
      String password,
      PhoneAuthCredential phoneCredential,
      ) async {
    try {
      // Create email credential
      final emailCredential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Sign in with email first
      final userCredential = await _firebaseAuth.signInWithCredential(emailCredential);

      // Then link with phone
      await userCredential.user?.linkWithCredential(phoneCredential);

      if (userCredential.user != null) {
        await _cacheUserData(userCredential.user!);

        // Update phone verification status
        await _firebaseService.updateUser(userCredential.user!.uid, {
          'isPhoneVerified': true,
        });
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'session-expired':
        return 'Verification session expired. Please request a new code.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}