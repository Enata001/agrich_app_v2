import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/config/app_config.dart';

class VideosRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  VideosRepository(this._firebaseService, this._localStorageService);

  // ==================== YOUTUBE VIDEO METHODS ====================

  /// Create video from YouTube URL
  Future<String> createVideoFromYouTube({
    required String youtubeUrl,
    required String title,
    required String description,
    required String category,
    required String authorName,
    required String authorId,
    String? authorAvatar,
    String? customThumbnail,
    String duration = '0:00',
  }) async {
    try {
      // Validate YouTube URL
      if (!_isValidYouTubeUrl(youtubeUrl)) {
        throw Exception('Invalid YouTube URL');
      }

      // Extract YouTube video ID
      final youtubeVideoId = _extractYouTubeVideoId(youtubeUrl);
      if (youtubeVideoId == null) {
        throw Exception('Could not extract YouTube video ID');
      }

      // Create video data
      final videoData = {
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'youtubeVideoId': youtubeVideoId,
        'youtubeUrl': youtubeUrl,
        'embedUrl': 'https://www.youtube.com/embed/$youtubeVideoId',
        'videoUrl': youtubeUrl, // For backward compatibility
        'thumbnailUrl': customThumbnail?.isNotEmpty == true
            ? customThumbnail
            : 'https://img.youtube.com/vi/$youtubeVideoId/maxresdefault.jpg',
        'duration': duration,
        'authorName': authorName,
        'authorId': authorId,
        'authorAvatar': authorAvatar ?? '',
        'isYouTubeVideo': true,
        'isActive': true,
        'views': 0,
        'likes': 0,
        'commentsCount': 0,
        'likedBy': <String>[],
        'uploadDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore using Firebase service
      final docRef = await _firebaseService.createVideo(videoData);
      return docRef.id;
    } catch (e) {
      print('Error creating YouTube video: $e');
      throw Exception('Failed to create video: $e');
    }
  }

  /// Create video from direct URL (backward compatibility)
  Future<String> createVideoFromDirectUrl({
    required String videoUrl,
    required String thumbnailUrl,
    required String title,
    required String description,
    required String category,
    required String authorName,
    required String authorId,
    String? authorAvatar,
    String duration = '0:00',
  }) async {
    try {
      final videoData = {
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'youtubeVideoId': null,
        'youtubeUrl': null,
        'embedUrl': null,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration,
        'authorName': authorName,
        'authorId': authorId,
        'authorAvatar': authorAvatar ?? '',
        'isYouTubeVideo': false,
        'isActive': true,
        'views': 0,
        'likes': 0,
        'commentsCount': 0,
        'likedBy': <String>[],
        'uploadDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firebaseService.createVideo(videoData);
      return docRef.id;
    } catch (e) {
      print('Error creating direct video: $e');
      throw Exception('Failed to create video: $e');
    }
  }

  // ==================== VIDEO RETRIEVAL METHODS ====================

  /// Get all videos with updated structure
  Future<List<Map<String, dynamic>>> getAllVideos({int limit = 20}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return _processVideoDocuments(snapshot.docs);
    } catch (e) {
      print('Error getting all videos: $e');
      return [];
    }
  }

  /// Get videos by category
  Future<List<Map<String, dynamic>>> getVideosByCategory(String category) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.limit(20).get();
      return _processVideoDocuments(snapshot.docs);
    } catch (e) {
      print('Error getting videos by category: $e');
      return [];
    }
  }

  /// Get popular videos (sorted by engagement)
  Future<List<Map<String, dynamic>>> getPopularVideos({int limit = 20}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('views', descending: true)
          .limit(limit)
          .get();

      return _processVideoDocuments(snapshot.docs);
    } catch (e) {
      print('Error getting popular videos: $e');
      return [];
    }
  }

  /// Get trending videos (recent videos with high engagement)
  Future<List<Map<String, dynamic>>> getTrendingVideos({int limit = 20}) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .where('createdAt', isGreaterThan: thirtyDaysAgo)
          .orderBy('createdAt', descending: false)
          .orderBy('views', descending: true)
          .limit(limit)
          .get();

      final videos = _processVideoDocuments(snapshot.docs);

      // Sort by engagement score (views + likes * 5 + comments * 3)
      videos.sort((a, b) {
        final aEngagement = (a['views'] as int? ?? 0) +
            ((a['likes'] as int? ?? 0) * 5) +
            ((a['commentsCount'] as int? ?? 0) * 3);
        final bEngagement = (b['views'] as int? ?? 0) +
            ((b['likes'] as int? ?? 0) * 5) +
            ((b['commentsCount'] as int? ?? 0) * 3);
        return bEngagement.compareTo(aEngagement);
      });

      return videos;
    } catch (e) {
      print('Error getting trending videos: $e');
      return [];
    }
  }

  /// Search videos
  Future<List<Map<String, dynamic>>> searchVideos(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final title = (data['title'] as String? ?? '').toLowerCase();
        final description = (data['description'] as String? ?? '').toLowerCase();
        final category = (data['category'] as String? ?? '').toLowerCase();
        final authorName = (data['authorName'] as String? ?? '').toLowerCase();
        final searchTerm = query.toLowerCase();

        return title.contains(searchTerm) ||
            description.contains(searchTerm) ||
            category.contains(searchTerm) ||
            authorName.contains(searchTerm);
      }).toList();

      return _processVideoDocuments(results);
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  /// Get video details
  Future<Map<String, dynamic>?> getVideoDetails(String videoId) async {
    try {
      final doc = await _firebaseService.getVideo(videoId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return _processVideoData(videoId, data);
      }
      return null;
    } catch (e) {
      print('Error getting video details: $e');
      return null;
    }
  }

  /// Get video categories
  Future<List<String>> getVideoCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      final sortedCategories = categories.toList()..sort();
      return ['All', ...sortedCategories];
    } catch (e) {
      print('Error getting video categories: $e');
      return ['All', ...AppConfig.videoCategories];
    }
  }

  // ==================== USER INTERACTION METHODS ====================

  /// Like/unlike video
  Future<void> likeVideo(String videoId, String userId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final videoRef = FirebaseFirestore.instance
            .collection(AppConfig.videosCollection)
            .doc(videoId);

        final videoDoc = await transaction.get(videoRef);
        if (!videoDoc.exists) {
          throw Exception('Video not found');
        }

        final data = videoDoc.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final currentLikes = data['likes'] as int? ?? 0;

        if (likedBy.contains(userId)) {
          // Unlike
          likedBy.remove(userId);
          transaction.update(videoRef, {
            'likedBy': likedBy,
            'likes': currentLikes - 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Like
          likedBy.add(userId);
          transaction.update(videoRef, {
            'likedBy': likedBy,
            'likes': currentLikes + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error liking video: $e');
      throw Exception('Failed to like video: $e');
    }
  }

  /// Save/unsave video
  Future<void> saveVideo(String videoId, String userId) async {
    try {
      final savedVideoRef = FirebaseFirestore.instance
          .collection('saved_videos')
          .doc('${userId}_$videoId');

      final savedDoc = await savedVideoRef.get();

      if (savedDoc.exists) {
        // Unsave
        await savedVideoRef.delete();
      } else {
        // Save
        await savedVideoRef.set({
          'userId': userId,
          'videoId': videoId,
          'savedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving video: $e');
      throw Exception('Failed to save video: $e');
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String videoId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .update({
        'views': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  /// Mark video as watched
  Future<void> markVideoAsWatched(String videoId, String userId) async {
    try {
      await addToWatchHistory(videoId, userId);
      await incrementViewCount(videoId);
    } catch (e) {
      print('Error marking video as watched: $e');
    }
  }

  /// Add video to watch history
  Future<void> addToWatchHistory(String videoId, String userId) async {
    try {
      final videoDoc = await _firebaseService.getVideo(videoId);
      if (videoDoc.exists) {
        final videoData = videoDoc.data() as Map<String, dynamic>;

        // Add to local storage
        final watchedVideo = {
          'id': videoDoc.id,
          'title': videoData['title'] ?? '',
          'thumbnailUrl': videoData['thumbnailUrl'] ?? '',
          'duration': videoData['duration'] ?? '0:00',
          'category': videoData['category'] ?? '',
          'isYouTubeVideo': videoData['isYouTubeVideo'] ?? false,
          'youtubeVideoId': videoData['youtubeVideoId'],
          'youtubeUrl': videoData['youtubeUrl'],
          'videoUrl': videoData['videoUrl'],
          'watchedAt': DateTime.now(),
        };

        await _localStorageService.addWatchedVideo(watchedVideo);

        // Add to Firebase
        await FirebaseFirestore.instance
            .collection('watch_history')
            .doc('${userId}_$videoId')
            .set({
          'userId': userId,
          'videoId': videoId,
          'watchedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error adding to watch history: $e');
    }
  }

  // ==================== USER DATA METHODS ====================

  /// Get user's saved videos
  Future<List<Map<String, dynamic>>> getUserSavedVideos(String userId) async {
    try {
      final savedSnapshot = await FirebaseFirestore.instance
          .collection('saved_videos')
          .where('userId', isEqualTo: userId)
          .orderBy('savedAt', descending: true)
          .get();

      final List<Map<String, dynamic>> savedVideos = [];

      for (final savedDoc in savedSnapshot.docs) {
        final savedData = savedDoc.data();
        final videoId = savedData['videoId'] as String;

        try {
          final videoDoc = await _firebaseService.getVideo(videoId);
          if (videoDoc.exists) {
            final videoData = videoDoc.data() as Map<String, dynamic>;
            if (videoData['isActive'] == true) {
              final processedVideo = _processVideoData(videoDoc.id, videoData);
              processedVideo['savedAt'] = (savedData['savedAt'] as Timestamp?)?.toDate();
              savedVideos.add(processedVideo);
            }
          }
        } catch (e) {
          print('Error fetching saved video $videoId: $e');
        }
      }

      return savedVideos;
    } catch (e) {
      print('Error getting user saved videos: $e');
      return [];
    }
  }

  /// Get user's liked videos
  Future<List<Map<String, dynamic>>> getUserLikedVideos(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .where('likedBy', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return _processVideoDocuments(snapshot.docs).map((video) {
        video['isLiked'] = true;
        return video;
      }).toList();
    } catch (e) {
      print('Error getting user liked videos: $e');
      return [];
    }
  }

  /// Get recently watched videos
  Future<List<Map<String, dynamic>>> getRecentlyWatchedVideos() async {
    try {
      final watchedVideos = _localStorageService.getWatchedVideos();
      return watchedVideos.take(5).toList();
    } catch (e) {
      print('Error getting recently watched videos: $e');
      return [];
    }
  }

  /// Get watch history from Firebase
  Future<List<Map<String, dynamic>>> getWatchHistoryFromFirebase(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('watch_history')
          .where('userId', isEqualTo: userId)
          .orderBy('watchedAt', descending: true)
          .limit(20)
          .get();

      final List<Map<String, dynamic>> watchHistory = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final videoId = data['videoId'] as String;

        try {
          final videoDoc = await _firebaseService.getVideo(videoId);
          if (videoDoc.exists) {
            final videoData = videoDoc.data() as Map<String, dynamic>;
            final processedVideo = _processVideoData(videoDoc.id, videoData);
            processedVideo['watchedAt'] = (data['watchedAt'] as Timestamp?)?.toDate();
            watchHistory.add(processedVideo);
          }
        } catch (e) {
          print('Error fetching watch history video $videoId: $e');
        }
      }

      return watchHistory;
    } catch (e) {
      print('Error getting watch history from Firebase: $e');
      return [];
    }
  }

  // ==================== STATUS CHECK METHODS ====================

  /// Check if video is saved by user
  Future<bool> isVideoSaved(String videoId, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('saved_videos')
          .doc('${userId}_$videoId')
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking if video is saved: $e');
      return false;
    }
  }

  /// Check if video is liked by user
  Future<bool> isVideoLiked(String videoId, String userId) async {
    try {
      final doc = await _firebaseService.getVideo(videoId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        return likedBy.contains(userId);
      }
      return false;
    } catch (e) {
      print('Error checking if video is liked: $e');
      return false;
    }
  }

  // ==================== VIDEO COMMENTS METHODS ====================

  /// Get video comments
  Future<List<Map<String, dynamic>>> getVideoComments(String videoId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error getting video comments: $e');
      return [];
    }
  }

  /// Add video comment
  Future<void> addVideoComment(String videoId, String comment, String userId, String userName) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .collection('comments')
          .add({
        'userId': userId,
        'userName': userName,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      // Update comment count
      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .update({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding video comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  // ==================== YOUTUBE UTILITY METHODS ====================

  /// Validate YouTube URL
  bool _isValidYouTubeUrl(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)',
      caseSensitive: false,
    );
    return regExp.hasMatch(url);
  }

  /// Extract YouTube video ID from URL
  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Check if URL is YouTube
  bool isYouTubeUrl(String url) {
    return _isValidYouTubeUrl(url);
  }

  /// Extract YouTube video ID (public method)
  String? extractYouTubeVideoId(String url) {
    return _extractYouTubeVideoId(url);
  }

  /// Get YouTube thumbnail URL
  String getYouTubeThumbnail(String videoId, {String quality = 'maxresdefault'}) {
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Process video documents from Firestore
  List<Map<String, dynamic>> _processVideoDocuments(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _processVideoData(doc.id, data);
    }).toList();
  }

  /// Process individual video data
  Map<String, dynamic> _processVideoData(String id, Map<String, dynamic> data) {
    return {
      'id': id,
      ...data,
      // Ensure backward compatibility
      'videoUrl': data['youtubeUrl'] ?? data['videoUrl'] ?? '',
      'uploadDate': (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    };
  }

  // ==================== UPDATE METHODS ====================

  /// Update video information
  Future<void> updateVideo(String videoId, Map<String, dynamic> updates) async {
    try {
      await _firebaseService.updateVideo(videoId, {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating video: $e');
      throw Exception('Failed to update video: $e');
    }
  }

  /// Delete video
  Future<void> deleteVideo(String videoId) async {
    try {
      // Delete video document
      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .delete();

      // Clean up related data
      await _cleanupVideoData(videoId);
    } catch (e) {
      print('Error deleting video: $e');
      throw Exception('Failed to delete video: $e');
    }
  }

  /// Cleanup video related data
  Future<void> _cleanupVideoData(String videoId) async {
    try {
      // Delete saved videos
      final savedVideosSnapshot = await FirebaseFirestore.instance
          .collection('saved_videos')
          .where('videoId', isEqualTo: videoId)
          .get();

      for (final doc in savedVideosSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete watch history
      final watchHistorySnapshot = await FirebaseFirestore.instance
          .collection('watch_history')
          .where('videoId', isEqualTo: videoId)
          .get();

      for (final doc in watchHistorySnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete comments subcollection
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .collection('comments')
          .get();

      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error cleaning up video data: $e');
    }
  }
}