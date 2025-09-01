import 'dart:io';
import '../../../../core/services/firebase_service.dart';

class CommunityRepository {
  final FirebaseService _firebaseService;

  CommunityRepository(this._firebaseService);

  Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final snapshot = await _firebaseService.getPosts();
      final posts = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        posts.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'authorId': data['authorId'] ?? '',
          'authorName': data['authorName'] ?? 'Unknown User',
          'authorAvatar': data['authorAvatar'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'likesCount': data['likesCount'] ?? 0,
          'commentsCount': data['commentsCount'] ?? 0,
          'likedBy': List<String>.from(data['likedBy'] ?? []),
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        });
      }

      return posts;
    } catch (e) {
      return _getMockPosts();
    }
  }

  Future<Map<String, dynamic>?> getPostDetails(String postId) async {
    try {
      final doc = await _firebaseService.getPost(postId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'content': data['content'] ?? '',
          'authorId': data['authorId'] ?? '',
          'authorName': data['authorName'] ?? 'Unknown User',
          'authorAvatar': data['authorAvatar'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'likesCount': data['likesCount'] ?? 0,
          'commentsCount': data['commentsCount'] ?? 0,
          'likedBy': List<String>.from(data['likedBy'] ?? []),
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final snapshot = await _firebaseService.getComments(postId);
      final comments = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        comments.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'authorId': data['authorId'] ?? '',
          'authorName': data['authorName'] ?? 'Unknown User',
          'authorAvatar': data['authorAvatar'] ?? '',
          'postId': data['postId'] ?? '',
          'createdAt': data['createdAt'],
        });
      }

      return comments;
    } catch (e) {
      return [];
    }
  }

  Future<String> createPost(Map<String, dynamic> postData) async {
    return await _firebaseService.createPost(postData);
  }

  Future<String> uploadPostImage(File imageFile) async {
    final postId = DateTime.now().millisecondsSinceEpoch.toString();
    return await _firebaseService.uploadPostImage(imageFile, postId);
  }

  Future<void> likePost(String postId) async {
    // TODO: Get current user ID from auth state
    const userId = 'current_user_id';
    await _firebaseService.likePost(postId, userId);
  }

  Future<String> addComment(String postId, Map<String, dynamic> commentData) async {
    return await _firebaseService.addComment(postId, commentData);
  }

  Future<void> deletePost(String postId) async {
    await _firebaseService.deletePost(postId);
  }

  List<Map<String, dynamic>> _getMockPosts() {
    return [
      {
        'id': '1',
        'content': 'Just harvested my first batch of organic rice! The yield was amazing thanks to the techniques I learned from the Agrich community. Special thanks to everyone who shared their experiences! 🌾',
        'authorId': 'user1',
        'authorName': 'Kwame Asante',
        'authorAvatar': 'https://via.placeholder.com/50/4CAF50/FFFFFF?text=K',
        'imageUrl': 'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=Rice+Harvest',
        'likesCount': 24,
        'commentsCount': 8,
        'likedBy': ['user2', 'user3'],
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        'updatedAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': '2',
        'content': 'Does anyone have experience with drought-resistant rice varieties? Looking for recommendations for the upcoming dry season. Any advice would be greatly appreciated!',
        'authorId': 'user2',
        'authorName': 'Ama Osei',
        'authorAvatar': 'https://via.placeholder.com/50/8BC34A/FFFFFF?text=A',
        'imageUrl': '',
        'likesCount': 12,
        'commentsCount': 15,
        'likedBy': ['user1'],
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
        'updatedAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'id': '3',
        'content': 'Sharing my experience with natural pest control methods. Used neem oil and companion planting - results have been fantastic! No chemical pesticides needed. 🌱',
        'authorId': 'user3',
        'authorName': 'Yaw Mensah',
        'authorAvatar': 'https://via.placeholder.com/50/689F38/FFFFFF?text=Y',
        'imageUrl': 'https://via.placeholder.com/400x300/689F38/FFFFFF?text=Natural+Farming',
        'likesCount': 35,
        'commentsCount': 12,
        'likedBy': ['user1', 'user2', 'user4'],
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': '4',
        'content': 'Weather has been perfect for planting this week! Getting my fields ready for the new season. What varieties are you all planning to grow?',
        'authorId': 'user4',
        'authorName': 'Akosua Frimpong',
        'authorAvatar': 'https://via.placeholder.com/50/558B2F/FFFFFF?text=A',
        'imageUrl': '',
        'likesCount': 18,
        'commentsCount': 6,
        'likedBy': ['user1', 'user3'],
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 2)),
      },
    ];
  }

}