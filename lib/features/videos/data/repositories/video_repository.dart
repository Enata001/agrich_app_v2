import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/config/app_config.dart';

class VideosRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  VideosRepository(this._firebaseService, this._localStorageService);

  Future<List<Map<String, dynamic>>> getRecentlyWatchedVideos() async {
    final watchedVideos = _localStorageService.getWatchedVideos();
    return watchedVideos.take(10).toList(); // Return last 10 watched videos
  }

  Future<List<Map<String, dynamic>>> getVideosByCategory(String category) async {
    try {
      final snapshot = await _firebaseService.getVideosByCategory(category);
      final videos = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        videos.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'thumbnail': data['thumbnailUrl'] ?? '',
          'url': data['videoUrl'] ?? '',
          'category': data['category'] ?? category,
          'duration': data['duration'] ?? '',
          'views': data['views'] ?? 0,
          'uploadDate': data['uploadDate'] ?? '',
          'author': data['author'] ?? 'Agrich Team',
        });
      }

      return videos;
    } catch (e) {
      return _getMockVideosByCategory(category);
    }
  }

  Future<List<Map<String, dynamic>>> getAllVideos() async {
    try {
      final snapshot = await _firebaseService.getAllVideos();
      final videos = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        videos.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'thumbnail': data['thumbnailUrl'] ?? '',
          'url': data['videoUrl'] ?? '',
          'category': data['category'] ?? '',
          'duration': data['duration'] ?? '',
          'views': data['views'] ?? 0,
          'uploadDate': data['uploadDate'] ?? '',
          'author': data['author'] ?? 'Agrich Team',
        });
      }

      return videos;
    } catch (e) {
      return _getMockVideos();
    }
  }

  Future<List<String>> getVideoCategories() async {
    return AppConfig.videoCategories;
  }

  Future<List<Map<String, dynamic>>> searchVideos(String query) async {
    try {
      final allVideos = await getAllVideos();
      return allVideos.where((video) {
        final title = (video['title'] as String).toLowerCase();
        final description = (video['description'] as String).toLowerCase();
        final category = (video['category'] as String).toLowerCase();
        final searchQuery = query.toLowerCase();

        return title.contains(searchQuery) ||
            description.contains(searchQuery) ||
            category.contains(searchQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markVideoAsWatched(Map<String, dynamic> video) async {
    await _localStorageService.addWatchedVideo(video);
  }

  Future<Map<String, dynamic>?> getVideoDetails(String videoId) async {
    try {
      final doc = await _firebaseService.getVideo(videoId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'thumbnail': data['thumbnailUrl'] ?? '',
          'url': data['videoUrl'] ?? '',
          'category': data['category'] ?? '',
          'duration': data['duration'] ?? '',
          'views': data['views'] ?? 0,
          'uploadDate': data['uploadDate'] ?? '',
          'author': data['author'] ?? 'Agrich Team',
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> _getMockVideos() {
    return [
      {
        'id': '1',
        'title': 'Modern Rice Planting Techniques',
        'description': 'Learn the latest methods for efficient rice planting',
        'thumbnail': 'https://via.placeholder.com/320x180/4CAF50/FFFFFF?text=Rice+Planting',
        'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'category': 'Planting',
        'duration': '15:30',
        'views': 1250,
        'uploadDate': '2024-01-15',
        'author': 'Dr. Kwame Asante',
      },
      {
        'id': '2',
        'title': 'Efficient Harvesting Methods',
        'description': 'Maximize your harvest with these proven techniques',
        'thumbnail': 'https://via.placeholder.com/320x180/8BC34A/FFFFFF?text=Harvesting',
        'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
        'category': 'Harvesting',
        'duration': '12:45',
        'views': 980,
        'uploadDate': '2024-01-10',
        'author': 'Ama Osei',
      },
      {
        'id': '3',
        'title': 'Pest Control in Rice Farming',
        'description': 'Natural and chemical methods for pest management',
        'thumbnail': 'https://via.placeholder.com/320x180/689F38/FFFFFF?text=Pest+Control',
        'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4',
        'category': 'Spraying',
        'duration': '18:20',
        'views': 1450,
        'uploadDate': '2024-01-08',
        'author': 'Prof. Yaw Mensah',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockVideosByCategory(String category) {
    final allVideos = _getMockVideos();
    return allVideos.where((video) => video['category'] == category).toList();
  }
}