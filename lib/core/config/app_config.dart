import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'Agrich 2.0';
  static const String appVersion = '2.0.0';


  static String weatherApiKey = dotenv.env['WEATHER_API_KEY'] ??"";
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String openAiBaseUrl = 'https://api.openai.com/v1';

  static const String openAiApiUrl = '$openAiBaseUrl/chat/completions';

  static final String openAiApiKey =dotenv.env['OPENAI_API_KEY']?? "";



  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String tipsCollection = 'tips';
  static const String videosCollection = 'videos';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';


  static const String profilePicturesPath = 'profile_pictures';
  static const String postImagesPath = 'post_images';
  static const String videoThumbnailsPath = 'video_thumbnails';
  static const String videosPath = 'videos';

  static const String adminLogsCollection = 'admin_logs';
  static const String reportedContentCollection = 'reported_content';
  static const String systemConfigCollection = 'system_config';


  static const List<String> videoCategories = [
    'Harvesting',
    'Spraying',
    'Modern Techniques',
    'Machinery',
    'Planting',
    'Irrigation',
    'Pest Control',
    'Fertilization',
    'Crop Rotation',
  ];

  static const List<String> tipCategories = [
    'planting',
    'water management',
    'soil care',
    'fertilization',
    'pest control',
    'harvesting',
    'general',
  ];


  static const int maxPostLength = 500;
  static const int maxCommentLength = 200;
  static const int maxChatMessageLength = 1000;
  static const int videosPerPage = 10;
  static const int postsPerPage = 20;


  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);


  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100;

  static const List<String> adminEmails = [
    'admin@agrich.com',
    'superadmin@agrich.com',
    'moderator@agrich.com',
    // Add more admin emails as needed
  ];

  static bool isAdminEmail(String email) {
    return adminEmails.contains(email.toLowerCase().trim());
  }


}

enum UserType { regular, admin }

// Admin Action Types for Logging
enum AdminActionType {
  userSuspended,
  userActivated,
  postDeleted,
  commentDeleted,
  tipCreated,
  tipUpdated,
  tipDeleted,
  videoAdded,
  videoUpdated,
  videoDeleted,
  contentReported,
  reportResolved,
}
class CacheKeys {
  static const String onboardingComplete = 'onboarding_complete';
  static const String userData = 'user_data';
  static const String watchedVideos = 'watched_videos';
  static const String dailyTip = 'daily_tip';
  static const String weatherData = 'weather_data';
  static const String lastWeatherUpdate = 'last_weather_update';
  static const String cachedPosts = 'cached_posts';
  static const String cachedTips = 'cached_tips';
  static const String cachedWeather = 'weather';
  static const String userChats = 'user_chats';
  static const String chatMessages = 'chat_messages';
  static const String adminStats = 'admin_stats';
  static const String adminUsers = 'admin_users';
  static const String adminReports = 'admin_reports';

}
