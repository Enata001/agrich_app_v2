class AppConfig {
  static const String appName = 'Agrich 2.0';
  static const String appVersion = '2.0.0';

  // API Configuration
  static const String weatherApiKey = 'YOUR_WEATHER_API_KEY';
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String tipsCollection = 'tips';
  static const String videosCollection = 'videos';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Storage Paths
  static const String profilePicturesPath = 'profile_pictures';
  static const String postImagesPath = 'post_images';
  static const String videoThumbnailsPath = 'video_thumbnails';
  static const String videosPath = 'videos';

  // Video Categories
  static const List<String> videoCategories = [
    'Harvesting',
    'Spraying',
    'Modern Techniques',
    'Machinery',
    'Planting',
    'Irrigation',
  ];

  // App Limits
  static const int maxPostLength = 500;
  static const int maxCommentLength = 200;
  static const int maxChatMessageLength = 1000;
  static const int videosPerPage = 10;
  static const int postsPerPage = 20;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
}

class CacheKeys {
  static const String onboardingComplete = 'onboarding_complete';
  static const String userData = 'user_data';
  static const String watchedVideos = 'watched_videos';
  static const String dailyTip = 'daily_tip';
  static const String weatherData = 'weather_data';
  static const String lastWeatherUpdate = 'last_weather_update';
}