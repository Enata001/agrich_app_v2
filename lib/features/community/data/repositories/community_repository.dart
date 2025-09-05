import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/firebase_service.dart';

class CommunityRepository {
  final FirebaseService _firebaseService;

  CommunityRepository(this._firebaseService);

  Stream<List<Map<String, dynamic>>> getPosts() {
    try {
      return _firebaseService.listenToCollection(
        AppConfig.postsCollection,
        orderBy: 'createdAt',
        descending: true,
        limit: 50,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      return Stream.value(_getMockPosts());
    }
  }

  Stream<List<Map<String, dynamic>>> getFilteredPosts(String filter) {
    try {
      Map<String, dynamic>? whereClause;
      String orderBy = 'createdAt';

      switch (filter.toLowerCase()) {
        case 'popular':
          orderBy = 'likesCount';
          break;
        case 'trending':

          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          whereClause = {'createdAt': weekAgo};
          break;
        case 'recent':
        default:
          orderBy = 'createdAt';
          break;
      }

      return _firebaseService.listenToCollection(
        AppConfig.postsCollection,
        where: whereClause,
        orderBy: orderBy,
        descending: true,
        limit: 50,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

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


      if (imageFile != null) {
        imageUrl = await _firebaseService.uploadPostImage(
          imageFile.path,
          'temp_${DateTime.now().millisecondsSinceEpoch}',
        );
      }


      final postData = {
        'content': content,
        'authorId': authorId,
        'authorAvatar': authorAvatar,
        'authorName': authorName,
        'imageUrl': imageUrl ?? '',
        'location': location ?? '',
        'tags': tags ?? <String>[],
        'likesCount': 0,
        'commentsCount': 0,
        'likedBy': <String>[],
        'isArchived': false,
        'isPinned': false,

        'sharesCount': 0,
        'isActive': true,
      };



      final docRef = await _firebaseService.createPost(postData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

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

  Stream<List<Map<String, dynamic>>> searchPosts(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    try {

      return Stream.fromFuture(_firebaseService.searchPosts(query)).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {

      final postDoc = await _firebaseService.getPost(postId);
      if (!postDoc.exists) throw Exception('Post not found');

      final data = postDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final currentLikesCount = data['likesCount'] as int? ?? 0;

      if (likedBy.contains(userId)) {

        likedBy.remove(userId);
        await _firebaseService.updatePost(postId, {
          'likedBy': likedBy,
          'likesCount': currentLikesCount - 1,
        });
      } else {

        likedBy.add(userId);
        await _firebaseService.updatePost(postId, {
          'likedBy': likedBy,
          'likesCount': currentLikesCount + 1,
        });


        if (data['authorId'] != userId) {
          await _createNotification(
            userId: data['authorId'],
            type: 'like',
            title: 'New like on your post',
            message: 'Someone liked your post',
            data: {'postId': postId},
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> savePost(String postId, String userId) async {
    try {
      final savedPosts = await _firebaseService.getSavedPosts(userId);
      final alreadySaved = savedPosts.docs.any((doc) =>
      (doc.data() as Map<String, dynamic>)['postId'] == postId);

      if (alreadySaved) {

        final savedPostDoc = savedPosts.docs.firstWhere((doc) =>
        (doc.data() as Map<String, dynamic>)['postId'] == postId);
        await _firebaseService.unsavePost(savedPostDoc.id);
      } else {

        await _firebaseService.savePost(userId, postId);
      }
    } catch (e) {
      throw Exception('Failed to save post: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserPosts(String userId) {
    try {
      return _firebaseService.listenToCollection(
        AppConfig.postsCollection,
        where: {'authorId': userId, 'isActive': true},
        orderBy: 'createdAt',
        descending: true,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> getUserSavedPosts(String userId) {
    try {
      return _firebaseService.listenToCollection(
        'saved_posts',
        where: {'userId': userId},
        orderBy: 'createdAt',
        descending: true,
      ).asyncMap((snapshot) async {
        final savedPosts = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final postId = data['postId'] as String;

          try {
            final postDoc = await _firebaseService.getPost(postId);
            if (postDoc.exists) {
              final postData = postDoc.data() as Map<String, dynamic>;
              if (postData['isActive'] == true) {
                savedPosts.add({
                  'id': postDoc.id,
                  'savedAt': (data['createdAt'] as Timestamp?)?.toDate(),
                  ...postData,
                  'createdAt': (postData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  'updatedAt': (postData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                });
              }
            }
          } catch (e) {

          }
        }

        return savedPosts;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> addComment(String postId, String content, String userId, Map<String, dynamic> userData) async {
    try {

      final commentData = {
        'postId': postId,
        'authorId': userId,
        'authorName': userData['username'] ?? 'User',
        'authorAvatar': userData['profilePictureUrl'] ?? '',
        'content': content,
      };

      await _firebaseService.addComment(commentData);


      final postDoc = await _firebaseService.getPost(postId);
      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        final currentCount = postData['commentsCount'] as int? ?? 0;

        await _firebaseService.updatePost(postId, {
          'commentsCount': currentCount + 1,
        });


        if (postData['authorId'] != userId) {
          await _createNotification(
            userId: postData['authorId'],
            type: 'comment',
            title: 'New comment on your post',
            message: 'Someone commented on your post',
            data: {'postId': postId},
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getPostComments(String postId) {
    try {
      return _firebaseService.listenToCollection(
        AppConfig.commentsCollection,
        where: {'postId': postId},
        orderBy: 'createdAt',
        descending: false,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firebaseService.createNotification(userId, {
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
      });
    } catch (e) {

      print('Failed to create notification: $e');
    }
  }

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

  Future<String> createComment({
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    String? parentCommentId,
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


      await _updatePostCommentCount(postId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }


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

        }
      }

      return savedPosts;
    } catch (e) {
      return [];
    }
  }


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


  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {


      return {
        'latitude': 5.6037,
        'longitude': -0.1870,
        'address': 'Accra, Ghana',
        'name': 'Current Location',
      };
    } catch (e) {
      return null;
    }
  }


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


  Future<void> deletePost(String postId, String userId) async {
    try {

      final postDoc = await _firebaseService.getPost(postId);
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['authorId'] != userId) {
        throw Exception('Not authorized to delete this post');
      }


      if (postData['imageUrl'] != null && postData['imageUrl'].isNotEmpty) {
        await _firebaseService.deleteFile(postData['imageUrl']);
      }


      final commentsSnapshot = await _firebaseService.getPostComments(postId);
      for (final commentDoc in commentsSnapshot.docs) {
        await _firebaseService.deleteComment(commentDoc.id);
      }


      await _firebaseService.deletePost(postId);


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


  Future<void> _updatePostCommentCount(String postId) async {
    try {
      final commentsSnapshot = await _firebaseService.getPostComments(postId);
      final commentCount = commentsSnapshot.docs.length;

      await _firebaseService.updatePost(postId, {
        'commentsCount': commentCount,
      });
    } catch (e) {

    }
  }


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

}