import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? youtubeVideoId;      // YouTube video ID
  final String? youtubeUrl;          // Full YouTube URL
  final String? embedUrl;            // YouTube embed URL
  final String? videoUrl;            // Direct video URL (for backward compatibility)
  final String thumbnailUrl;
  final String duration;
  final DateTime uploadDate;
  final DateTime createdAt;
  final int views;
  final int likes;
  final int commentsCount;
  final List<String> likedBy;
  final String authorName;
  final String authorId;
  final String? authorAvatar;
  final bool isActive;
  final bool isYouTubeVideo;         // Flag to identify video type

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.youtubeVideoId,
    this.youtubeUrl,
    this.embedUrl,
    this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.uploadDate,
    required this.createdAt,
    required this.views,
    required this.likes,
    required this.commentsCount,
    required this.likedBy,
    required this.authorName,
    required this.authorId,
    this.authorAvatar,
    required this.isActive,
    required this.isYouTubeVideo,
  });

  // Factory constructor for YouTube videos
  factory VideoModel.fromYouTube({
    required String id,
    required String title,
    required String description,
    required String category,
    required String youtubeUrl,
    required String authorName,
    required String authorId,
    String? authorAvatar,
    String? customThumbnail,
    String duration = '0:00',
  }) {
    final youtubeVideoId = _extractYouTubeVideoId(youtubeUrl);

    return VideoModel(
      id: id,
      title: title,
      description: description,
      category: category,
      youtubeVideoId: youtubeVideoId,
      youtubeUrl: youtubeUrl,
      embedUrl: youtubeVideoId != null ? 'https://www.youtube.com/embed/$youtubeVideoId' : null,
      videoUrl: null,
      thumbnailUrl: customThumbnail ??
          (youtubeVideoId != null ? 'https://img.youtube.com/vi/$youtubeVideoId/maxresdefault.jpg' : ''),
      duration: duration,
      uploadDate: DateTime.now(),
      createdAt: DateTime.now(),
      views: 0,
      likes: 0,
      commentsCount: 0,
      likedBy: [],
      authorName: authorName,
      authorId: authorId,
      authorAvatar: authorAvatar,
      isActive: true,
      isYouTubeVideo: true,
    );
  }

  // Factory constructor for direct video URLs
  factory VideoModel.fromDirectUrl({
    required String id,
    required String title,
    required String description,
    required String category,
    required String videoUrl,
    required String thumbnailUrl,
    required String authorName,
    required String authorId,
    String? authorAvatar,
    String duration = '0:00',
  }) {
    return VideoModel(
      id: id,
      title: title,
      description: description,
      category: category,
      youtubeVideoId: null,
      youtubeUrl: null,
      embedUrl: null,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      uploadDate: DateTime.now(),
      createdAt: DateTime.now(),
      views: 0,
      likes: 0,
      commentsCount: 0,
      likedBy: [],
      authorName: authorName,
      authorId: authorId,
      authorAvatar: authorAvatar,
      isActive: true,
      isYouTubeVideo: false,
    );
  }

  // Extract YouTube video ID from various URL formats
  static String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'youtubeVideoId': youtubeVideoId,
      'youtubeUrl': youtubeUrl,
      'embedUrl': embedUrl,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'uploadDate': uploadDate,
      'createdAt': createdAt,
      'views': views,
      'likes': likes,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'authorName': authorName,
      'authorId': authorId,
      'authorAvatar': authorAvatar,
      'isActive': isActive,
      'isYouTubeVideo': isYouTubeVideo,
      'updatedAt': DateTime.now(),
    };
  }

  // Create from Firestore document
  factory VideoModel.fromMap(String id, Map<String, dynamic> map) {
    return VideoModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      youtubeVideoId: map['youtubeVideoId'],
      youtubeUrl: map['youtubeUrl'],
      embedUrl: map['embedUrl'],
      videoUrl: map['videoUrl'],
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      duration: map['duration'] ?? '0:00',
      uploadDate: (map['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      views: map['views'] ?? 0,
      likes: map['likes'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      authorName: map['authorName'] ?? '',
      authorId: map['authorId'] ?? '',
      authorAvatar: map['authorAvatar'],
      isActive: map['isActive'] ?? true,
      isYouTubeVideo: map['isYouTubeVideo'] ?? false,
    );
  }

  // Helper method to get playable URL
  String getPlayableUrl() {
    if (isYouTubeVideo && youtubeUrl != null) {
      return youtubeUrl!;
    } else if (videoUrl != null) {
      return videoUrl!;
    }
    return '';
  }

  // Helper method to check if video is playable
  bool get isPlayable => getPlayableUrl().isNotEmpty;

  VideoModel copyWith({
    String? title,
    String? description,
    String? category,
    String? thumbnailUrl,
    String? duration,
    int? views,
    int? likes,
    int? commentsCount,
    List<String>? likedBy,
    bool? isActive,
  }) {
    return VideoModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      youtubeVideoId: youtubeVideoId,
      youtubeUrl: youtubeUrl,
      embedUrl: embedUrl,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      uploadDate: uploadDate,
      createdAt: createdAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      authorName: authorName,
      authorId: authorId,
      authorAvatar: authorAvatar,
      isActive: isActive ?? this.isActive,
      isYouTubeVideo: isYouTubeVideo,
    );
  }
}