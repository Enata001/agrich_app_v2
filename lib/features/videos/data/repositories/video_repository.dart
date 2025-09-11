import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/network_service.dart';

class VideosRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  VideosRepository(this._firebaseService, this._localStorageService);

  // ==================== CORE VIDEO METHODS (STRICTLY ONLINE) ====================

  /// Get all videos - STRICTLY ONLINE ONLY
  Future<List<Map<String, dynamic>>> getAllVideos() async {
    // Check network first - FAIL if offline
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Videos require internet connection. Please check your network and try again.');
    }

    try {
      final snapshot = await _firebaseService.getAllVideos();

      return _processVideoDocuments(snapshot.docs);
    } catch (e) {
      throw Exception('Failed to load videos: $e');
    }
  }

  /// Get videos by category - STRICTLY ONLINE ONLY
  Future<List<Map<String, dynamic>>> getVideosByCategory(String category) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Videos require internet connection. Please check your network and try again.');
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return _processVideoDocuments(snapshot.docs);
    } catch (e) {
      throw Exception('Failed to load videos for category: $category');
    }
  }

  /// Get popular videos - STRICTLY ONLINE ONLY
  Future<List<Map<String, dynamic>>> getPopularVideos() async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Videos require internet connection');
    }

    try {
      final allVideos = await getAllVideos();

      // Sort by popularity (views + likes)
      final sortedVideos = List<Map<String, dynamic>>.from(allVideos);
      sortedVideos.sort((a, b) {
        final aViews = a['views'] as int? ?? 0;
        final bViews = b['views'] as int? ?? 0;
        final aLikes = a['likes'] as int? ?? 0;
        final bLikes = b['likes'] as int? ?? 0;

        final aScore = aViews + (aLikes * 10); // Weight likes more
        final bScore = bViews + (bLikes * 10);

        return bScore.compareTo(aScore);
      });

      return sortedVideos;
    } catch (e) {
      throw Exception('Failed to load popular videos: $e');
    }
  }

  /// Get trending videos - STRICTLY ONLINE ONLY
  Future<List<Map<String, dynamic>>> getTrendingVideos() async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Videos require internet connection');
    }

    try {
      final allVideos = await getAllVideos();

      // Filter videos from last 30 days and sort by engagement
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final recentVideos = allVideos.where((video) {
        final uploadDate = video['uploadDate'] as DateTime? ?? DateTime.now();
        return uploadDate.isAfter(thirtyDaysAgo);
      }).toList();

      // Sort by engagement rate (views + likes + comments)
      recentVideos.sort((a, b) {
        final aViews = a['views'] as int? ?? 0;
        final bViews = b['views'] as int? ?? 0;
        final aLikes = a['likes'] as int? ?? 0;
        final bLikes = b['likes'] as int? ?? 0;
        final aComments = a['commentsCount'] as int? ?? 0;
        final bComments = b['commentsCount'] as int? ?? 0;

        final aEngagement = aViews + (aLikes * 5) + (aComments * 3);
        final bEngagement = bViews + (bLikes * 5) + (bComments * 3);

        return bEngagement.compareTo(aEngagement);
      });

      return recentVideos;
    } catch (e) {
      throw Exception('Failed to load trending videos: $e');
    }
  }

  /// Search videos - STRICTLY ONLINE ONLY
  Future<List<Map<String, dynamic>>> searchVideos(String query) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Search requires internet connection');
    }

    try {
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
      throw Exception('Failed to search videos: $e');
    }
  }

  /// Get video details - STRICTLY ONLINE ONLY
  Future<Map<String, dynamic>?> getVideoDetails(String videoId) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Video details require internet connection');
    }

    try {
      final doc = await _firebaseService.getVideo(videoId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return _processVideoData(videoId, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get video details: $e');
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
      return ['All', ...AppConfig.videoCategories];
    }
  }

  /// Get video stats
  Future<Map<String, int>> getVideoStats() async {
    try {
      final allVideos = await getAllVideos();
      final totalVideos = allVideos.length;
      final totalViews = allVideos.fold<int>(0, (sum, video) => sum + (video['views'] as int? ?? 0));
      final totalLikes = allVideos.fold<int>(0, (sum, video) => sum + (video['likes'] as int? ?? 0));

      return {
        'totalVideos': totalVideos,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
      };
    } catch (e) {
      return {'totalVideos': 0, 'totalViews': 0, 'totalLikes': 0};
    }
  }

  // ==================== RECENTLY WATCHED (LOCAL CACHE ONLY) ====================

  /// ✅ FIXED: Get recently watched videos (from local cache only)
  Future<List<Map<String, dynamic>>> getRecentlyWatchedVideos() async {
    try {
      final watchedVideos = _localStorageService.getWatchedVideos();
      return watchedVideos; // Returns up to 10 videos as configured
    } catch (e) {
      print('Error getting recently watched videos: $e');
      return [];
    }
  }

  /// ✅ FIXED: Mark video as watched (THIS WAS THE KEY ISSUE!)
  Future<void> markVideoAsWatched(String videoId, String userId) async {
    try {
      // Get video info for caching (metadata only, not the actual video)
      final videoDoc = await _firebaseService.getVideo(videoId);
      if (videoDoc.exists) {
        final videoData = videoDoc.data() as Map<String, dynamic>;

        // Create watched video entry with ALL necessary display info
        final watchedVideo = {
          'id': videoId,
          'title': videoData['title'] ?? 'Unknown Video',
          'description': videoData['description'] ?? '',
          'thumbnailUrl': videoData['thumbnailUrl'] ?? '',
          'duration': videoData['duration'] ?? '0:00',
          'category': videoData['category'] ?? '',
          'authorName': videoData['authorName'] ?? '',
          'authorAvatar': videoData['authorAvatar'] ?? '',
          'views': videoData['views'] ?? 0,
          'likes': videoData['likes'] ?? 0,
          'likedBy': videoData['likedBy'] ?? [],
          'isYouTubeVideo': videoData['isYouTubeVideo'] ?? false,
          'youtubeVideoId': videoData['youtubeVideoId'],
          'youtubeUrl': videoData['youtubeUrl'],
          'videoUrl': videoData['videoUrl'],
          'embedUrl': videoData['embedUrl'],
          'uploadDate': videoData['uploadDate'],
          'createdAt': videoData['createdAt'],
          'authorId': videoData['authorId'] ?? '',
          'commentsCount': videoData['commentsCount'] ?? 0,
          'isActive': videoData['isActive'] ?? true,
          'watchedAt': DateTime.now().toIso8601String(), // When it was watched
        };

        // ✅ THIS IS THE KEY: Cache locally for home screen display
        await _localStorageService.addWatchedVideo(watchedVideo);

        // Also try to sync to Firebase for cross-device (but don't fail if offline)
        try {
          await FirebaseFirestore.instance
              .collection('watch_history')
              .doc('${userId}_$videoId')
              .set({
            'userId': userId,
            'videoId': videoId,
            'watchedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          // Ignore Firebase errors when offline - local cache is what matters for home screen
          print('Could not sync watch history to Firebase: $e');
        }
      }
    } catch (e) {
      print('Error marking video as watched: $e');
    }
  }

  // ==================== USER INTERACTION METHODS (ONLINE ONLY) ====================

  /// Like/unlike video
  Future<void> likeVideo(String videoId, String userId) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Cannot like video while offline');
    }

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
          });
        } else {
          // Like
          likedBy.add(userId);
          transaction.update(videoRef, {
            'likedBy': likedBy,
            'likes': currentLikes + 1,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to like video: $e');
    }
  }

  /// Save/unsave video
  Future<void> saveVideo(String videoId, String userId) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Cannot save video while offline');
    }

    try {
      final savedSnapshot = await FirebaseFirestore.instance
          .collection('saved_videos')
          .where('userId', isEqualTo: userId)
          .where('videoId', isEqualTo: videoId)
          .get();

      if (savedSnapshot.docs.isNotEmpty) {
        // Unsave
        await savedSnapshot.docs.first.reference.delete();
      } else {
        // Save
        await FirebaseFirestore.instance.collection('saved_videos').add({
          'userId': userId,
          'videoId': videoId,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
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
      });
    } catch (e) {
      // Don't throw error for view count - it's not critical
      print('Error incrementing view count: $e');
    }
  }

  /// Add to watch history in Firebase
  Future<void> addToWatchHistory(String videoId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('watch_history')
          .doc('${userId}_$videoId')
          .set({
        'userId': userId,
        'videoId': videoId,
        'watchedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Don't throw error - local cache is more important
      print('Error adding to Firebase watch history: $e');
    }
  }

  // ==================== USER SAVED/LIKED VIDEOS (ONLINE ONLY) ====================

  /// Get user's saved videos
  Future<List<Map<String, dynamic>>> getUserSavedVideos(String userId) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Saved videos require internet connection');
    }

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
      throw Exception('Failed to get saved videos: $e');
    }
  }

  /// Get user's liked videos
  Future<List<Map<String, dynamic>>> getUserLikedVideos(String userId) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Liked videos require internet connection');
    }

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
      throw Exception('Failed to get liked videos: $e');
    }
  }

  /// Get watch history from Firebase
  Future<List<Map<String, dynamic>>> getWatchHistoryFromFirebase(String userId) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Watch history requires internet connection');
    }

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
      throw Exception('Failed to get watch history: $e');
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
      throw Exception('Failed to get video comments: $e');
    }
  }

  /// Add comment to video
  Future<void> addVideoComment(String videoId, String userId, String content) async {
    final networkService = NetworkService();
    if (!await networkService.checkConnectivity()) {
      throw NetworkException('Cannot add comment while offline');
    }

    try {
      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .collection('comments')
          .add({
        'userId': userId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Increment comment count
      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .update({
        'commentsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // ==================== HELPER METHODS ====================

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
      'uploadDate': (data['uploadDate'] as Timestamp?)?.toDate(),
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    };
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all video-related cache
  Future<void> clearVideoCache() async {
    try {
      await _localStorageService.clearWatchedVideos();
    } catch (e) {
      print('Error clearing video cache: $e');
    }
  }

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

  bool _isValidYouTubeUrl(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com/(?:[^/]+\/.+/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)',
      caseSensitive: false,
    );
    return regExp.hasMatch(url);
  }

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

}