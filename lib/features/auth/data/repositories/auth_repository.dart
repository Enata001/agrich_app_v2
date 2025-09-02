import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
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

  bool get isSignedIn => (_localStorageService.getUserData() != null) ?? false;

  // Email & Password Sign In
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

  // Email & Password Sign Up
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
          profilePictureUrl: '',
          bio: '',
          location: '',
          joinedAt: DateTime.now(),
          isEmailVerified: credential.user!.emailVerified,
          isPhoneVerified: false,
        );

        await _firebaseService.createUser(userModel.id, userModel.toMap());
        await _cacheUserData(credential.user!);
        await _cacheUserProfile(userModel);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign In
  // Future<UserCredential> signInWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //
  //     if (googleUser == null) {
  //       throw Exception('Google sign in was cancelled');
  //     }
  //
  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     final userCredential = await _firebaseAuth.signInWithCredential(credential);
  //
  //     if (userCredential.user != null) {
  //       await _cacheUserData(userCredential.user!);
  //
  //       // Check if user profile exists, create if not
  //       final userDoc = await _firebaseService.getUser(userCredential.user!.uid);
  //       if (!userDoc.exists) {
  //         final userModel = UserModel(
  //           uid: userCredential.user!.uid,
  //           email: userCredential.user!.email ?? '',
  //           username: userCredential.user!.displayName ?? 'User',
  //           phoneNumber: userCredential.user!.phoneNumber ?? '',
  //           profilePictureUrl: userCredential.user!.photoURL ?? '',
  //           bio: '',
  //           location: '',
  //           joinedAt: DateTime.now(),
  //           isEmailVerified: userCredential.user!.emailVerified,
  //           isPhoneVerified: false,
  //         );
  //         await _firebaseService.createUser(userModel.uid, userModel.toMap());
  //         await _cacheUserProfile(userModel);
  //       } else {
  //         await _syncUserProfile(userCredential.user!);
  //       }
  //     }
  //
  //     return userCredential;
  //   } on FirebaseAuthException catch (e) {
  //     throw _handleAuthException(e);
  //   }
  // }

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

  // Check if user exists - FIXED: Replace deprecated method
  Future<bool> checkUserExists(String email) async {
    try {
            // Rate limited, try alternative method
        return await _checkUserExistsAlternative(email);
    } catch (e) {
      // Fallback for completely deprecated method
      return await _checkUserExistsAlternative(email);
    }
  }

  // Alternative method to check if user exists
  Future<bool> _checkUserExistsAlternative(String email) async {
    try {
      // Try to create a user with a dummy password to check if email exists
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: 'dummy_password_${DateTime.now().millisecondsSinceEpoch}'
      );
      // If we get here, user didn't exist, but we created one accidentally
      // Delete the accidentally created user
      await _firebaseAuth.currentUser?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true;
      }
      return false;
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

  // Sign Out
  Future<void> signOut() async {
    try {
      // await GoogleSignIn().signOut();
      await _firebaseAuth.signOut();
      await _localStorageService.clearUserData();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      // Check cache first
      final cachedProfile = _getCachedUserProfile();
      if (cachedProfile != null && cachedProfile.id == uid) {
        return cachedProfile;
      }

      // Fetch from Firestore
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

      // Update cached profile
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

  // Link Email with Phone
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
        await _syncUserProfile(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
        // Delete user data from Firestore
        await _firebaseService.deleteUser(user.uid);

        // Delete Firebase Auth user
        await user.delete();

        // Clear local storage
        await _localStorageService.clearUserData();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
    await _localStorageService.setUserData(userModel.toMap());
  }

  UserModel? _getCachedUserProfile() {
    try {
      final profileJson = _localStorageService.getUserData();
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
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}