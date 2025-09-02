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
          'createdAt': data['createdAt']?.toDate(),
          'updatedAt': data['updatedAt']?.toDate(),
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
          'createdAt': data['createdAt']?.toDate(),
          'updatedAt': data['updatedAt']?.toDate(),
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
          'postId': data['postId'] ?? postId,
          'createdAt': data['createdAt']?.toDate(),
          'updatedAt': data['updatedAt']?.toDate(),
        });
      }

      return comments;
    } catch (e) {
      return [];
    }
  }

  Future<void> createPost(Map<String, dynamic> postData) async {
    try {
      await _firebaseService.createPost(postData);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<void> likePost(String postId, [String? userId]) async {
    try {
      // If userId not provided, this is a simple toggle action
      // The actual user ID should come from the auth state
      await _firebaseService.likePost(postId, userId ?? 'current_user');
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> addComment(String postId, Map<String, dynamic> commentData) async {
    try {
      await _firebaseService.addComment(postId, commentData);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firebaseService.deletePost(postId);
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firebaseService.deleteComment(postId, commentId);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<void> updatePost(String postId, Map<String, dynamic> postData) async {
    try {
      await _firebaseService.updatePost(postId, postData);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  Future<String> uploadPostImage(String imagePath, String userId) async {
    try {
      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      return await _firebaseService.uploadPostImage(imagePath, postId);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    try {
      final snapshot = await _firebaseService.searchPosts(query);
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
          'createdAt': data['createdAt']?.toDate(),
          'updatedAt': data['updatedAt']?.toDate(),
        });
      }

      return posts;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final allPosts = await getPosts();
      return allPosts.where((post) => post['authorId'] == userId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> reportPost(String postId, String reporterId, String reason) async {
    try {
      await _firebaseService.reportContent(
        contentType: 'post',
        contentId: postId,
        reporterId: reporterId,
        reason: reason,
      );
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  Future<void> reportComment(String commentId, String reporterId, String reason) async {
    try {
      await _firebaseService.reportContent(
        contentType: 'comment',
        contentId: commentId,
        reporterId: reporterId,
        reason: reason,
      );
    } catch (e) {
      throw Exception('Failed to report comment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingPosts() async {
    try {
      final posts = await getPosts();

      // Calculate trending score based on likes, comments, and recency
      final now = DateTime.now();
      for (final post in posts) {
        final createdAt = post['createdAt'] as DateTime?;
        final likesCount = post['likesCount'] as int;
        final commentsCount = post['commentsCount'] as int;

        if (createdAt != null) {
          final hoursSinceCreation = now.difference(createdAt).inHours;
          final ageWeight = hoursSinceCreation > 0 ? 1.0 / hoursSinceCreation : 1.0;
          final trendingScore = (likesCount * 2 + commentsCount * 3) * ageWeight;
          post['trendingScore'] = trendingScore;
        } else {
          post['trendingScore'] = 0.0;
        }
      }

      // Sort by trending score
      posts.sort((a, b) => (b['trendingScore'] as double).compareTo(a['trendingScore'] as double));

      return posts.take(20).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final posts = await getPosts();
      final totalPosts = posts.length;
      final totalLikes = posts.fold<int>(0, (sum, post) => sum + (post['likesCount'] as int));
      final totalComments = posts.fold<int>(0, (sum, post) => sum + (post['commentsCount'] as int));

      // Get unique authors
      final authors = <String>{};
      for (final post in posts) {
        final authorId = post['authorId'] as String?;
        if (authorId != null && authorId.isNotEmpty) {
          authors.add(authorId);
        }
      }

      return {
        'totalPosts': totalPosts,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'activeUsers': authors.length,
        'averageLikesPerPost': totalPosts > 0 ? totalLikes / totalPosts : 0.0,
        'averageCommentsPerPost': totalPosts > 0 ? totalComments / totalPosts : 0.0,
      };
    } catch (e) {
      return {
        'totalPosts': 0,
        'totalLikes': 0,
        'totalComments': 0,
        'activeUsers': 0,
        'averageLikesPerPost': 0.0,
        'averageCommentsPerPost': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getPostsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final posts = await getPosts();
      return posts.where((post) {
        final createdAt = post['createdAt'] as DateTime?;
        if (createdAt == null) return false;

        return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
      }).toList();
    } catch (e) {
      return [];
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

  Future<List<Map<String, dynamic>>> getSavedPosts(String userId) async {
    try {
      // This would require a saved_posts collection or field
      // For now, return empty list as this feature needs to be implemented
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> savePost(String postId, String userId) async {
    try {
      // This would save the post to user's saved posts
      // Implementation depends on how you want to structure saved posts
      await _firebaseService.batchWrite([
        {
          'type': 'create',
          'collection': 'saved_posts',
          'docId': '${userId}_$postId',
          'data': {
            'userId': userId,
            'postId': postId,
            'savedAt': DateTime.now(),
          },
        },
      ]);
    } catch (e) {
      throw Exception('Failed to save post: $e');
    }
  }

  Future<void> unsavePost(String postId, String userId) async {
    try {
      await _firebaseService.batchWrite([
        {
          'type': 'delete',
          'collection': 'saved_posts',
          'docId': '${userId}_$postId',
        },
      ]);
    } catch (e) {
      throw Exception('Failed to unsave post: $e');
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
        'content': 'Amazing sunrise over the cornfield this morning. Nothing beats farm life! 🌅🌽',
        'authorId': 'mock_user_3',
        'authorName': 'Mike Agriculture',
        'authorAvatar': '',
        'imageUrl': '',
        'likesCount': 42,
        'commentsCount': 7,
        'likedBy': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
        'updatedAt': DateTime.now().subtract(const Duration(hours: 8)),
      },
      {
        'id': 'mock_post_4',
        'content': 'New irrigation system is working perfectly! Water efficiency increased by 30%. Highly recommend investing in modern farming equipment.',
        'authorId': 'mock_user_4',
        'authorName': 'Emma Tech',
        'authorAvatar': '',
        'imageUrl': '',
        'likesCount': 23,
        'commentsCount': 9,
        'likedBy': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': 'mock_post_5',
        'content': 'Weekly weather forecast looks good for planting! Planning to start my winter vegetables this weekend. 🥬🥕',
        'authorId': 'mock_user_5',
        'authorName': 'David Weather',
        'authorAvatar': '',
        'imageUrl': '',
        'likesCount': 17,
        'commentsCount': 5,
        'likedBy': <String>[],
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 2)),
      },
    ];
  }
}