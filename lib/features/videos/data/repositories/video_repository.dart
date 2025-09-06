import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/config/app_config.dart';

class VideosRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  VideosRepository(this._firebaseService, this._localStorageService);

  // EXISTING METHODS (keep your existing implementations)


  Future<List<Map<String, dynamic>>> getAllVideos({int limit = 20}) async {
    try {
      final snapshot = await _firebaseService.getVideos();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'uploadDate': (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error getting all videos: $e');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> getVideosByCategory(String category) async {
    try {
      final snapshot = await _firebaseService.getVideosByCategory(category);
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'uploadDate': (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error getting videos by category: $e');
      return [];
    }
  }

  Future<void> markVideoAsWatched(String videoId, String userId) async {
    try {
      await addToWatchHistory(videoId, userId);
    } catch (e) {
      print('Error marking video as watched: $e');
    }
  }


  Future<List<Map<String, dynamic>>> getRecentlyWatchedVideos() async {
    try {
      final watchedVideos = _localStorageService.getWatchedVideos();
      return watchedVideos.take(5).toList();
    } catch (e) {
      print('Error getting recently watched videos: $e');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> searchVideos(String query) async {
    try {
      final snapshot = await _firebaseService.searchVideos(query);
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'uploadDate': (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }


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


  Future<Map<String, dynamic>?> getVideoDetails(String videoId) async {
    try {
      final doc = await _firebaseService.getVideo(videoId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'uploadDate': (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }
      return null;
    } catch (e) {
      print('Error getting video details: $e');
      return null;
    }
  }




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

          likedBy.remove(userId);
          transaction.update(videoRef, {
            'likedBy': likedBy,
            'likes': currentLikes - 1,
          });
        } else {

          likedBy.add(userId);
          transaction.update(videoRef, {
            'likedBy': likedBy,
            'likes': currentLikes + 1,
          });
        }
      });
    } catch (e) {
      print('Error liking video: $e');
      throw Exception('Failed to like video: $e');
    }
  }


  Future<void> saveVideo(String videoId, String userId) async {
    try {
      final savedVideoRef = FirebaseFirestore.instance
          .collection('saved_videos')
          .doc('${userId}_$videoId');

      final savedDoc = await savedVideoRef.get();

      if (savedDoc.exists) {

        await savedVideoRef.delete();
      } else {

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
              savedVideos.add({
                'id': videoDoc.id,
                ...videoData,
                'savedAt': (savedData['savedAt'] as Timestamp?)?.toDate(),
                'uploadDate': (videoData['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'createdAt': (videoData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              });
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


  Future<List<Map<String, dynamic>>> getUserLikedVideos(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .where('isActive', isEqualTo: true)
          .where('likedBy', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'uploadDate': (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isLiked': true,
        };
      }).toList();
    } catch (e) {
      print('Error getting user liked videos: $e');
      return [];
    }
  }


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


  Future<void> incrementViewCount(String videoId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .update({
        'views': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing view count: $e');

    }
  }


  Future<void> addToWatchHistory(String videoId, String userId) async {
    try {

      final videoDoc = await _firebaseService.getVideo(videoId);
      if (videoDoc.exists) {
        final videoData = videoDoc.data() as Map<String, dynamic>;

        final watchedVideo = {
          'id': videoDoc.id,
          'title': videoData['title'] ?? '',
          'thumbnailUrl': videoData['thumbnailUrl'] ?? '',
          'duration': videoData['duration'] ?? '0:00',
          'category': videoData['category'] ?? '',
          'watchedAt': DateTime.now(),
        };


        await _localStorageService.addWatchedVideo(watchedVideo);


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
            watchHistory.add({
              'id': videoDoc.id,
              ...videoData,
              'watchedAt': (data['watchedAt'] as Timestamp?)?.toDate(),
              'uploadDate': (videoData['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          }
        } catch (e) {
          print('Error fetching watched video $videoId: $e');
        }
      }

      return watchHistory;
    } catch (e) {
      print('Error getting watch history from Firebase: $e');
      return [];
    }
  }


  Future<void> rateVideo(String videoId, int rating, String userId) async {
    try {
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }


      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .collection('ratings')
          .doc(userId)
          .set({
        'userId': userId,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));


      await _updateVideoAverageRating(videoId);
    } catch (e) {
      print('Error rating video: $e');
      throw Exception('Failed to rate video: $e');
    }
  }


  Future<void> _updateVideoAverageRating(String videoId) async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        int ratingCount = 0;

        for (final doc in ratingsSnapshot.docs) {
          final data = doc.data();
          final rating = data['rating'] as int? ?? 0;
          totalRating += rating;
          ratingCount++;
        }

        final averageRating = totalRating / ratingCount;

        await FirebaseFirestore.instance
            .collection(AppConfig.videosCollection)
            .doc(videoId)
            .update({
          'averageRating': averageRating,
          'ratingCount': ratingCount,
        });
      }
    } catch (e) {
      print('Error updating average rating: $e');
    }
  }


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
        };
      }).toList();
    } catch (e) {
      print('Error getting video comments: $e');
      return [];
    }
  }


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


      await FirebaseFirestore.instance
          .collection(AppConfig.videosCollection)
          .doc(videoId)
          .update({
        'commentsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding video comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }
}