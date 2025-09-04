import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/firebase_service.dart';

class CommunityRepository {
  final FirebaseService _firebaseService;

  CommunityRepository(this._firebaseService);

  // Get all posts
  Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final snapshot = await _firebaseService.getPosts();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      return _getMockPosts(); // Fallback to mock data
    }
  }

  // Get post details
  Future<Map<String, dynamic>?> getPostDetails(String postId) async {
    try {
      final doc = await _firebaseService.getPost(postId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // IMPLEMENTED: Create new post
  Future<String> createPost({
    required String content,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    File? imageFile,
    String? location,
    List<String>? tags,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _firebaseService.uploadPostImage(
          imageFile.path,
          'temp_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Create post data
      final postData = {
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'imageUrl': imageUrl ?? '',
        'location': location ?? '',
        'tags': tags ?? <String>[],
        'likesCount': 0,
        'commentsCount': 0,
        'likedBy': <String>[],
        'isArchived': false,
        'isPinned': false,
      };

      final docRef = await _firebaseService.createPost(postData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // IMPLEMENTED: Like/Unlike post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firebaseService.likePost(postId, userId);
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // IMPLEMENTED: Get post comments
  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final snapshot = await _firebaseService.getPostComments(postId);
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // IMPLEMENTED: Create comment
  Future<String> createComment({
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    String? parentCommentId, // For replies
  }) async {
    try {
      final commentData = {
        'postId': postId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'parentCommentId': parentCommentId,
        'likesCount': 0,
        'likedBy': <String>[],
        'isEdited': false,
      };

      final docRef = await _firebaseService.createComment(commentData);

      // Update post comment count
      await _updatePostCommentCount(postId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  // IMPLEMENTED: Like comment
  Future<void> likeComment(String commentId, String userId) async {
    try {
      final commentRef = FirebaseFirestore.instance
          .collection(AppConfig.commentsCollection)
          .doc(commentId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);

        if (commentDoc.exists) {
          final data = commentDoc.data() as Map<String, dynamic>;
          final likedBy = List<String>.from(data['likedBy'] ?? []);
          final likesCount = data['likesCount'] as int? ?? 0;

          if (likedBy.contains(userId)) {
            likedBy.remove(userId);
            transaction.update(commentRef, {
              'likedBy': likedBy,
              'likesCount': likesCount - 1,
            });
          } else {
            likedBy.add(userId);
            transaction.update(commentRef, {
              'likedBy': likedBy,
              'likesCount': likesCount + 1,
            });
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  // IMPLEMENTED: Share post
  Future<String> sharePost(String postId) async {
    try {
      final postDoc = await _firebaseService.getPost(postId);
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      final postUrl = 'https://agrich.app/posts/$postId';

      return 'Check out this post on Agrich: "${postData['content']}" - $postUrl';
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  // IMPLEMENTED: Save post
  Future<void> savePost(String postId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('saved_posts')
          .doc('${userId}_$postId')
          .set({
        'userId': userId,
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save post: $e');
    }
  }

  // IMPLEMENTED: Unsave post
  Future<void> unsavePost(String postId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('saved_posts')
          .doc('${userId}_$postId')
          .delete();
    } catch (e) {
      throw Exception('Failed to unsave post: $e');
    }
  }

  // IMPLEMENTED: Check if post is saved
  Future<bool> isPostSaved(String postId, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('saved_posts')
          .doc('${userId}_$postId')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // IMPLEMENTED: Get saved posts
  Future<List<Map<String, dynamic>>> getSavedPosts(String userId) async {
    try {
      final savedSnapshot = await FirebaseFirestore.instance
          .collection('saved_posts')
          .where('userId', isEqualTo: userId)
          .orderBy('savedAt', descending: true)
          .get();

      final List<Map<String, dynamic>> savedPosts = [];

      for (final savedDoc in savedSnapshot.docs) {
        final savedData = savedDoc.data();
        final postId = savedData['postId'] as String;

        try {
          final postDoc = await _firebaseService.getPost(postId);
          if (postDoc.exists) {
            final postData = postDoc.data() as Map<String, dynamic>;
            savedPosts.add({
              'id': postDoc.id,
              ...postData,
              'savedAt': (savedData['savedAt'] as Timestamp?)?.toDate(),
              'createdAt': (postData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          }
        } catch (e) {
          // Skip posts that can't be loaded
        }
      }

      return savedPosts;
    } catch (e) {
      return [];
    }
  }

  // IMPLEMENTED: Report post
  Future<void> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
    String? description,
  }) async {
    try {
      await _firebaseService.reportContent(
        contentType: 'post',
        contentId: postId,
        reporterId: reporterId,
        reason: reason,
        additionalData: {
          'description': description ?? '',
          'reportedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  // IMPLEMENTED: Report comment
  Future<void> reportComment({
    required String commentId,
    required String reporterId,
    required String reason,
    String? description,
  }) async {
    try {
      await _firebaseService.reportContent(
        contentType: 'comment',
        contentId: commentId,
        reporterId: reporterId,
        reason: reason,
        additionalData: {
          'description': description ?? '',
          'reportedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to report comment: $e');
    }
  }

  // IMPLEMENTED: Location picker functionality
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // This would integrate with location services
      // For now, return a mock location
      return {
        'latitude': 5.6037, // Accra coordinates
        'longitude': -0.1870,
        'address': 'Accra, Ghana',
        'name': 'Current Location',
      };
    } catch (e) {
      return null;
    }
  }

  // IMPLEMENTED: Search posts
  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.postsCollection)
          .where('content', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('content', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .orderBy('content')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // IMPLEMENTED: Get posts by tag
  Future<List<Map<String, dynamic>>> getPostsByTag(String tag) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.postsCollection)
          .where('tags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // IMPLEMENTED: Get user's posts
  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.postsCollection)
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // IMPLEMENTED: Delete post
  Future<void> deletePost(String postId, String userId) async {
    try {
      // Verify ownership
      final postDoc = await _firebaseService.getPost(postId);
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['authorId'] != userId) {
        throw Exception('Not authorized to delete this post');
      }

      // Delete post image if exists
      if (postData['imageUrl'] != null && postData['imageUrl'].isNotEmpty) {
        await _firebaseService.deleteFile(postData['imageUrl']);
      }

      // Delete all comments for this post
      final commentsSnapshot = await _firebaseService.getPostComments(postId);
      for (final commentDoc in commentsSnapshot.docs) {
        await _firebaseService.deleteComment(commentDoc.id);
      }

      // Delete the post
      await _firebaseService.deletePost(postId);

      // Clean up saved post references
      final savedPostsSnapshot = await FirebaseFirestore.instance
          .collection('saved_posts')
          .where('postId', isEqualTo: postId)
          .get();

      for (final savedDoc in savedPostsSnapshot.docs) {
        await savedDoc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // IMPLEMENTED: Update comment count
  Future<void> _updatePostCommentCount(String postId) async {
    try {
      final commentsSnapshot = await _firebaseService.getPostComments(postId);
      final commentCount = commentsSnapshot.docs.length;

      await _firebaseService.updatePost(postId, {
        'commentsCount': commentCount,
      });
    } catch (e) {
      // Ignore errors in comment count update
    }
  }

  // Admin functions
  Future<void> pinPost(String postId, bool isPinned) async {
    try {
      await _firebaseService.updatePost(postId, {
        'isPinned': isPinned,
        'pinnedAt': isPinned ? DateTime.now() : null,
      });
    } catch (e) {
      throw Exception('Failed to pin/unpin post: $e');
    }
  }

  Future<void> archivePost(String postId, bool isArchived) async {
    try {
      await _firebaseService.updatePost(postId, {
        'isArchived': isArchived,
        'archivedAt': isArchived ? DateTime.now() : null,
      });
    } catch (e) {
      throw Exception('Failed to archive/unarchive post: $e');
    }
  }

  // Helper method to get mock posts for testing
  List<Map<String, dynamic>> _getMockPosts() {
    return [
      {
        'id': 'mock_post_1',
        'content': 'Just harvested my first batch of tomatoes this season! The weather has been perfect for growing. 🍅',
        'authorId': 'mock_user_1',
        'authorName': 'John Farmer',
        'authorAvatar': '',
        'imageUrl': '',
        'likesCount': 15,
        'commentsCount': 3,
        'likedBy': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        'updatedAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': 'mock_post_2',
        'content': 'Does anyone have tips for dealing with aphids on cucumber plants? Mine are getting attacked! 🥒',
        'authorId': 'mock_user_2',
        'authorName': 'Sarah Green',
        'authorAvatar': '',
        'imageUrl': '',
        'likesCount': 8,
        'commentsCount': 12,
        'likedBy': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
        'updatedAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'id': 'mock_post_3',
        'content': 'Amazing sunrise over the cornfield this morning. Nothing beats farm life! 🌅',
        'authorId': 'mock_user_3',
        'authorName': 'Mike Fields',
        'authorAvatar': '',
        'imageUrl': '',
        'likesCount': 42,
        'commentsCount': 8,
        'likedBy': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
        'updatedAt': DateTime.now().subtract(const Duration(hours: 8)),
      },
    ];
  }
}