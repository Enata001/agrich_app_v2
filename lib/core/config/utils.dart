import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static int getGridCrossAxisCount(BuildContext context, {int? mobile, int? tablet, int? desktop}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return desktop ?? 4;
    if (width >= 600) return tablet ?? 3;
    return mobile ?? 2;
  }

  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1400;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(24);
    if (isTablet(context)) return const EdgeInsets.all(16);
    return const EdgeInsets.all(16);
  }

  static double getFontSize(BuildContext context, {double? mobile, double? tablet, double? desktop}) {
    if (isDesktop(context)) return desktop ?? 16;
    if (isTablet(context)) return tablet ?? 15;
    return mobile ?? 14;
  }

  static bool shouldShowSidebar(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static int getItemsPerRow(BuildContext context, {int minItemWidth = 250}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Account for padding
    return (availableWidth / minItemWidth).floor().clamp(1, 6);
  }
}

class YouTubeThumbnailUtils {
  // Different YouTube thumbnail qualities in order of preference
  static const List<String> _thumbnailQualities = [
    'maxresdefault',  // 1280x720 (highest quality)
    'sddefault',      // 640x480 (standard definition)
    'hqdefault',      // 480x360 (high quality)
    'mqdefault',      // 320x180 (medium quality)
    'default',        // 120x90 (lowest quality, always available)
  ];

  /// Get the best available YouTube thumbnail URL
  static String getBestThumbnailUrl(String videoId) {
    // Start with highest quality, the widget will fallback if needed
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  /// Get all possible thumbnail URLs for fallback
  static List<String> getAllThumbnailUrls(String videoId) {
    return _thumbnailQualities
        .map((quality) => 'https://img.youtube.com/vi/$videoId/$quality.jpg')
        .toList();
  }

  /// Get specific quality thumbnail URL
  static String getThumbnailUrl(String videoId, {String quality = 'maxresdefault'}) {
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  /// Check if video ID is valid (11 characters)
  static bool isValidVideoId(String? videoId) {
    return videoId != null && videoId.length == 11;
  }
}
