import 'dart:io';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';

class ProfileRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  ProfileRepository(this._firebaseService, this._localStorageService);

  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final userData = _localStorageService.getUserData();
      if (userData == null || userData['id'] == null) {

        throw Exception('No user data found');
      }

      final userId = userData['id'] as String;
      return await _firebaseService.uploadProfilePicture(imageFile, userId);
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firebaseService.updateUser(userId, data);
      final currentUserData = _localStorageService.getUserData();
      if (currentUserData != null) {
        currentUserData.addAll(data);
        await _localStorageService.setUserData(currentUserData);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final doc = await _firebaseService.getUser(userId);
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }
}