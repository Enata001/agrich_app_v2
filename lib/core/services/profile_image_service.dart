import 'dart:io';
import 'package:agrich_app_v2/features/community/presentation/providers/community_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/videos/presentation/providers/video_provider.dart';
import '../config/app_config.dart';
import '../providers/app_providers.dart';
import 'firebase_service.dart';

class ProfileImageService {
  final Ref _ref;

  ProfileImageService(this._ref);

  // Update profile image and invalidate all related providers
  Future<void> updateProfileImageGlobally(String userId, String newImageUrl) async {
    try {
      // 1. Update Firebase Auth user photoURL
      final firebaseAuth = _ref.read(firebaseAuthProvider);
      await firebaseAuth.currentUser?.updatePhotoURL(newImageUrl);

      // 2. Update Firestore user document
      await FirebaseFirestore.instance
          .collection(AppConfig.usersCollection)
          .doc(userId)
          .update({
        'profilePictureUrl': newImageUrl,
        'photoURL': newImageUrl, // For backward compatibility
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update all posts by this user
      await _updateUserPostsProfileImage(userId, newImageUrl);

      // 4. Update all chat references
      await _updateUserChatsProfileImage(userId, newImageUrl);

      // 5. Update all video references
      await _updateUserVideosProfileImage(userId, newImageUrl);

      // 6. Update all comments by this user
      await _updateUserCommentsProfileImage(userId, newImageUrl);

      // 7. Invalidate all relevant providers to force refresh
      _invalidateProfileProviders();

    } catch (e) {
      throw Exception('Failed to update profile image globally: $e');
    }
  }

  // Update profile image in all user's posts
  Future<void> _updateUserPostsProfileImage(String userId, String newImageUrl) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Get all posts by this user
      final postsQuery = await FirebaseFirestore.instance
          .collection(AppConfig.postsCollection)
          .where('authorId', isEqualTo: userId)
          .get();

      for (final doc in postsQuery.docs) {
        batch.update(doc.reference, {
          'authorAvatar': newImageUrl,
          'authorProfilePicture': newImageUrl,
        });
      }

      await batch.commit();
      print('✅ Updated ${postsQuery.docs.length} posts with new profile image');
    } catch (e) {
      print('❌ Error updating posts profile image: $e');
    }
  }

  // Update profile image in all user's chats
  Future<void> _updateUserChatsProfileImage(String userId, String newImageUrl) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Get all chats where user is a participant
      final chatsQuery = await FirebaseFirestore.instance
          .collection(AppConfig.chatsCollection)
          .where('participants', arrayContains: userId)
          .get();

      for (final doc in chatsQuery.docs) {
        final data = doc.data();
        final participants = data['participantsData'] as Map<String, dynamic>? ?? {};

        // Update this user's data in participants
        if (participants.containsKey(userId)) {
          participants[userId]['profilePictureUrl'] = newImageUrl;
          participants[userId]['avatar'] = newImageUrl;

          batch.update(doc.reference, {
            'participantsData': participants,
          });
        }
      }

      // Also update all messages by this user
      for (final chatDoc in chatsQuery.docs) {
        final messagesQuery = await chatDoc.reference
            .collection(AppConfig.messagesCollection)
            .where('senderId', isEqualTo: userId)
            .get();

        for (final messageDoc in messagesQuery.docs) {
          batch.update(messageDoc.reference, {
            'senderAvatar': newImageUrl,
            'senderProfilePicture': newImageUrl,
          });
        }
      }

      await batch.commit();
      print('✅ Updated chats and messages with new profile image');
    } catch (e) {
      print('❌ Error updating chats profile image: $e');
    }
  }

  // Update profile image in all user's videos
  Future<void> _updateUserVideosProfileImage(String userId, String newImageUrl) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Get all videos by this user
      final videosQuery = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('authorId', isEqualTo: userId)
          .get();

      for (final doc in videosQuery.docs) {
        batch.update(doc.reference, {
          'authorAvatar': newImageUrl,
          'authorProfilePicture': newImageUrl,
        });
      }

      await batch.commit();
      print('✅ Updated ${videosQuery.docs.length} videos with new profile image');
    } catch (e) {
      print('❌ Error updating videos profile image: $e');
    }
  }

  // Update profile image in all user's comments
  Future<void> _updateUserCommentsProfileImage(String userId, String newImageUrl) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Get all comments by this user across all posts
      final commentsQuery = await FirebaseFirestore.instance
          .collectionGroup(AppConfig.commentsCollection)
          .where('authorId', isEqualTo: userId)
          .get();

      for (final doc in commentsQuery.docs) {
        batch.update(doc.reference, {
          'authorAvatar': newImageUrl,
          'authorProfilePicture': newImageUrl,
        });
      }

      await batch.commit();
      print('✅ Updated ${commentsQuery.docs.length} comments with new profile image');
    } catch (e) {
      print('❌ Error updating comments profile image: $e');
    }
  }

  // Invalidate all providers that cache user data
  void _invalidateProfileProviders() {
    // Invalidate auth providers
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(currentUserProfileProvider);

    // Invalidate community providers
    _ref.invalidate(communityPostsProvider);

    // Invalidate chat providers
    _ref.invalidate(userChatsProvider);


    // Invalidate profile providers
    _ref.invalidate(userPostsProvider);
    _ref.invalidate(userVideosProvider);

    print('✅ Invalidated all profile-related providers');
  }
}

// Provider for ProfileImageService
final profileImageServiceProvider = Provider<ProfileImageService>((ref) {
  return ProfileImageService(ref);
});

// Enhanced Firebase Service update method
extension FirebaseServiceProfileImage on FirebaseService {
  Future<void> updateUserWithProfileImageSync(String uid, Map<String, dynamic> userData) async {
    // Update main user document
    await updateUser(uid, userData);

    // If profilePictureUrl is being updated, sync across all user content
    if (userData.containsKey('profilePictureUrl')) {
      final profileImageService = ProfileImageService(ref);
      await profileImageService.updateProfileImageGlobally(uid, userData['profilePictureUrl']);
    }
  }
}