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

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  bool get isSignedIn => (_localStorageService.getUserData() != null);

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
    String phoneNumber,
  ) async {
    try {
      final emailExists = await checkUserExists(email);
      if (emailExists) {
        throw Exception('An account with this email already exists');
      }

      final phoneExists = await checkPhoneExists(phoneNumber);
      if (phoneExists) {
        throw Exception(
          'This phone number is already linked to another account',
        );
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(username);

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

        await _cacheUserData(credential.user!, isComplete: false);
        await _cacheUserProfile(userModel);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> linkPhoneCredentialToEmailAccount(
    PhoneAuthCredential phoneCredential,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in to link phone');
      }

      final userProfile = await getUserProfile(user.uid);
      if (userProfile?.isPhoneVerified == true) {
        throw Exception('Phone number is already verified');
      }

      final isPhoneLinked = user.providerData.any(
        (provider) => provider.providerId == 'phone',
      );
      if (isPhoneLinked) {
        throw Exception('Phone number is already linked to this account');
      }

      await user.linkWithCredential(phoneCredential);

      await updateUserProfile(user.uid, {
        'isPhoneVerified': true,
        'isEmailVerified': true,
        'phoneNumber': user.phoneNumber,
        'accountStatus': 'complete',
        'phoneVerifiedAt': DateTime.now().toIso8601String(),
      });

      await _cacheUserData(user, isComplete: true);
      await _syncUserProfile(user);
    } on FirebaseAuthException catch (e) {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _deleteIncompleteAccount(currentUser);
      }
      throw _handleAuthException(e);
    }
  }

  Future<void> linkPhoneToEmailAccount(
    String phoneNumber,
    String verificationId,
    String smsCode,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in to link phone');
      }

      final userProfile = await getUserProfile(user.uid);
      if (userProfile?.isPhoneVerified == true) {
        throw Exception('Phone number is already verified');
      }

      final phoneExists = await checkPhoneExists(phoneNumber);
      if (phoneExists) {
        await _deleteIncompleteAccount(user);
        throw Exception(
          'This phone number is already linked to another account',
        );
      }

      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await user.linkWithCredential(phoneCredential);

      await updateUserProfile(user.uid, {
        'isPhoneVerified': true,
        'isEmailVerified': true,
        'phoneNumber': phoneNumber,
        'accountStatus': 'complete',
        'phoneVerifiedAt': DateTime.now().toIso8601String(),
      });

      await _cacheUserData(user, isComplete: true);
      await _syncUserProfile(user);
    } on FirebaseAuthException catch (e) {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _deleteIncompleteAccount(currentUser);
      }
      throw _handleAuthException(e);
    }
  }

  Future<void> _deleteIncompleteAccount(User user) async {
    try {
      await _firebaseService.deleteUser(user.uid);

      await user.delete();

      await _localStorageService.clearUserData();

      print('🗑️ Deleted incomplete account: ${user.uid}');
    } catch (e) {
      print('❌ Error deleting incomplete account: $e');
    }
  }

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
        final userProfile = await getUserProfile(credential.user!.uid);

        if (userProfile == null) {
          throw Exception('User profile not found');
        }

        if (!userProfile.isPhoneVerified) {
          throw IncompleteAccountException(
            'Phone verification required to complete your account',
            phoneNumber: userProfile.phoneNumber,
            userId: credential.user!.uid,
          );
        }

        await _cacheUserData(credential.user!, isComplete: true);
        await _syncUserProfile(credential.user!);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;

        final userProfile = await getUserProfile(user.uid);

        if (userProfile != null) {
          if (!userProfile.isPhoneVerified) {
            await updateUserProfile(user.uid, {'isPhoneVerified': true});
          }

          await _cacheUserData(user, isComplete: true);
          await _syncUserProfile(user);
        } else {
          await user.delete();
          throw Exception(
            'Phone-only accounts are not supported. Please sign up with email and phone.',
          );
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

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

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;

        final userProfile = await getUserProfile(user.uid);

        if (userProfile == null) {
          await user.delete();
          throw Exception(
            'Phone-only accounts are not supported. Please sign up with email and phone.',
          );
        }

        if (!userProfile.isPhoneVerified) {
          await updateUserProfile(user.uid, {'isPhoneVerified': true});
        }

        await _cacheUserData(user, isComplete: true);
        await _syncUserProfile(user);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<SignInMethod> detectSignInMethod(String identifier) async {
    if (identifier.contains('@')) {
      try {
        final querySnapshot = await _firebaseService.getUserByEmail(identifier);

        if (querySnapshot.docs.isEmpty) return SignInMethod.none;
        if (querySnapshot.docs.isNotEmpty) {
          final userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;
          final isPhoneVerified = userData['isPhoneVerified'] ?? false;

          if (!isPhoneVerified) {
            return SignInMethod.emailIncomplete;
          }
        }
      } catch (e) {
        print('Error checking account completion: $e');
      }

      return SignInMethod.email;
    } else {
      try {
        final querySnapshot = await _firebaseService.getUserByPhone(identifier);
        if (querySnapshot.docs.isEmpty) return SignInMethod.none;
        if (querySnapshot.docs.isNotEmpty) {
          final userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;
          final email = userData['email'];

          if (email == null || email.isEmpty) {
            return SignInMethod.phoneOnly;
          }

          return SignInMethod.phoneLinked;
        }
      } catch (e) {
        print('Error checking phone link status: $e');
      }

      return SignInMethod.phone;
    }
  }

  Future<bool> checkUserExists(String email) async {
    try {
      print('Checking for this email: $email');
      final querySnapshot = await _firebaseService.getUserByEmail(email);
      if (querySnapshot.docs.isNotEmpty) {
        print(querySnapshot.docs.firstOrNull);
        return true;
      }

      return false;
    } catch (e) {
      return false;
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

  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      final querySnapshot = await _firebaseService.getUserByPhone(phoneNumber);
      print(querySnapshot.docs.first);
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> completeAccountVerification(String userId) async {
    try {
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      if (userProfile.isPhoneVerified) {
        throw Exception('Account is already verified');
      }

      await updateUserProfile(userId, {
        'isPhoneVerified': true,
        'accountStatus': 'complete',
        'phoneVerifiedAt': DateTime.now().toIso8601String(),
      });

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _cacheUserData(user, isComplete: true);
      }
    } catch (e) {
      throw Exception('Failed to complete account verification: $e');
    }
  }

  bool get isAccountComplete {
    try {
      final cachedProfile = _getCachedUserProfile();
      return cachedProfile?.isPhoneVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<AccountStatus> getAccountStatus() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return AccountStatus.noAccount;

      final userProfile = await getUserProfile(user.uid);
      if (userProfile == null) return AccountStatus.noProfile;

      if (!userProfile.isPhoneVerified) {
        return AccountStatus.pendingPhoneVerification;
      }

      return AccountStatus.complete;
    } catch (e) {
      return AccountStatus.error;
    }
  }

  bool isPhoneLinked() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    return user.providerData.any((provider) => provider.providerId == 'phone');
  }

  List<String> getLinkedProviders() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];

    return user.providerData.map((provider) => provider.providerId).toList();
  }

  Future<void> initiatePasswordReset(String identifier) async {
    if (identifier.contains('@')) {
      await sendPasswordResetEmail(identifier);
    } else {
      final phoneExists = await checkPhoneExists(identifier);
      if (!phoneExists) {
        throw Exception('Phone number not found');
      }
    }
  }

  Future<void> resetPasswordWithPhone(
    String phoneNumber,
    String newPassword,
  ) async {
    try {
      final querySnapshot = await _firebaseService.getUserByPhone(phoneNumber);
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Phone number not found');
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;
      final userId = userData['id'] as String;
      print(userData);

      final user = _firebaseAuth.currentUser;
      print(_firebaseAuth.currentUser?.uid);
      if (user == null || user.uid != userId) {
        throw Exception('User not properly authenticated via phone');
      }

      await user.updatePassword(newPassword);

      await _firebaseService.updateUser(user.uid, {
        'passwordUpdatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

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

  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _cacheUserData(user, isComplete: isAccountComplete);
        await _syncUserProfile(user);
      }
    } catch (e) {}
  }

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

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _localStorageService.clearAllExceptOnboarding();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final cachedProfile = _getCachedUserProfile();
      if (cachedProfile != null && cachedProfile.id == uid) {
        return cachedProfile;
      }

      final doc = await _firebaseService.getUser(uid);
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);

        await _cacheUserProfile(userModel);

        return userModel;
      }
      return null;
    } catch (e) {
      return _getCachedUserProfile();
    }
  }

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
          profilePictureUrl:
              data['profilePictureUrl'] ?? cachedProfile.profilePictureUrl,
          bio: data['bio'] ?? cachedProfile.bio,
          location: data['location'] ?? cachedProfile.location,
          joinedAt: cachedProfile.joinedAt,
          isEmailVerified:
              data['isEmailVerified'] ?? cachedProfile.isEmailVerified,
          isPhoneVerified:
              data['isPhoneVerified'] ?? cachedProfile.isPhoneVerified,
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

  Future<void> _cacheUserData(User user, {required bool isComplete}) async {
    final data = {
      'id': user.uid,
      'email': user.email,
      'username': user.displayName,
      'phoneNumber': user.phoneNumber,
      'profilePictureUrl': user.photoURL,
      'isEmailVerified': user.emailVerified,
      'isPhoneVerified': isComplete,
      'accountComplete': isComplete,
      'lastSignIn': DateTime.now().toIso8601String(),
    };

    final userData = UserModel.fromMap(data);
    await _localStorageService.setUserData(userData.toMap());
  }

  Future<void> _cacheUserProfile(UserModel userModel) async {
    await _localStorageService.setUserData(userModel.toMap());
  }

  UserModel? _getCachedUserProfile() {
    try {
      final userData = _localStorageService.getUserData();
      if (userData != null) {
        return UserModel.fromMap(userData);
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
      print('Error syncing user profile: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'session-expired':
        return 'The verification session has expired.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'provider-already-linked':
        return 'This account is already linked with this provider.';
      case 'invalid-credential':
        return 'The provided credential is invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'missing-phone-number':
        return 'Phone number is required for phone authentication.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'missing-verification-code':
        return 'Please enter the verification code.';
      case 'missing-verification-id':
        return 'Verification ID is missing.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

enum SignInMethod {
  none,
  email,
  emailIncomplete,
  phone,
  phoneLinked,
  phoneOnly,
}

enum AccountStatus {
  noAccount,
  noProfile,
  pendingPhoneVerification,
  complete,
  error,
}

class IncompleteAccountException implements Exception {
  final String message;
  final String phoneNumber;
  final String userId;

  IncompleteAccountException(
    this.message, {
    required this.phoneNumber,
    required this.userId,
  });

  @override
  String toString() => message;
}
