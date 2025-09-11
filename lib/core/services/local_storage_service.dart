import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  // Cache expiration durations
  static const Duration _defaultCacheExpiration = Duration(hours: 1);
  static const Duration _userDataCacheExpiration = Duration(days: 7);
  static const Duration _postsCacheExpiration = Duration(minutes: 30);
  static const Duration _tipsCacheExpiration = Duration(hours: 6);
  static const Duration _chatCacheExpiration = Duration(hours: 1);

  LocalStorageService(this._prefs);

  // ================ CACHE MANAGEMENT WITH EXPIRATION ================

  Future<bool> setCachedData(
      String key,
      Map<String, dynamic> data, {
        Duration? expiration,
      }) async {
    final expirationTime = DateTime.now().add(expiration ?? _defaultCacheExpiration);
    final cachedData = {
      'data': data,
      'expiration': expirationTime.millisecondsSinceEpoch,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };

    return await _prefs.setString(key, jsonEncode(cachedData));
  }

  Map<String, dynamic>? getCachedData(String key) {
    final cachedString = _prefs.getString(key);
    if (cachedString == null) return null;

    try {
      final cachedData = jsonDecode(cachedString) as Map<String, dynamic>;
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(
          cachedData['expiration'] as int
      );

      if (DateTime.now().isAfter(expirationTime)) {
        _prefs.remove(key);
        return null;
      }

      return cachedData['data'] as Map<String, dynamic>;
    } catch (e) {
      _prefs.remove(key);
      return null;
    }
  }



  List<Map<String, dynamic>> sanitizeTimestamps(List<Map<String, dynamic>> rawList) {
    return rawList.map((map) {
      final sanitized = <String, dynamic>{};
      map.forEach((key, value) {
        if (value is Timestamp) {
          sanitized[key] = value.toDate().toIso8601String();
        } else if (value is DateTime) {
          sanitized[key] = value.toIso8601String();
        } else {
          sanitized[key] = value;
        }
      });
      return sanitized;
    }).toList();
  }

  Future<bool> setCachedList(
      String key,
      List<Map<String, dynamic>> data, {
        Duration? expiration,
      }) async {
    final expirationTime = DateTime.now().add(expiration ?? _defaultCacheExpiration);
    final sanitizedData = sanitizeTimestamps(data);

    final cachedData = {
      'data': sanitizedData,
      'expiration': expirationTime.millisecondsSinceEpoch,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };

    return await _prefs.setString(key, jsonEncode(cachedData));
  }

  List<Map<String, dynamic>> getCachedList(String key) {
    final cachedString = _prefs.getString(key);
    if (cachedString == null) return [];

    try {
      final cachedData = jsonDecode(cachedString) as Map<String, dynamic>;
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(
        cachedData['expiration'] as int,
      );

      if (DateTime.now().isAfter(expirationTime)) {
        _prefs.remove(key);
        return [];
      }

      final dataList = cachedData['data'] as List<dynamic>;

      return dataList.map((item) {
        final map = item as Map<String, dynamic>;
        final hydrated = <String, dynamic>{};

        map.forEach((key, value) {
          if (value is String && _isIsoDate(value)) {
            hydrated[key] = DateTime.parse(value);
          } else {
            hydrated[key] = value;
          }
        });

        return hydrated;
      }).toList();
    } catch (e) {
      _prefs.remove(key);
      return [];
    }
  }

  bool _isIsoDate(String value) {
    // Basic check for ISO format
    return RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value);
  }
  // ================ USER DATA ================

  Future<bool> setUserData(Map<String, dynamic> userData) async {
    return await setCachedData(
      CacheKeys.userData,
      userData,
      expiration: _userDataCacheExpiration,
    );
  }

  Map<String, dynamic>? getUserData() {
    return getCachedData(CacheKeys.userData);
  }

  Future<bool> clearUserData() async {
    return await _prefs.remove(CacheKeys.userData);
  }

  Map<String, dynamic> _sanitizeForCache(Map<String, dynamic> video) {
    final sanitized = <String, dynamic>{};

    video.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String(); // or value.seconds
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }
  Future<bool> addWatchedVideo(Map<String, dynamic> video) async {
    print("caching $video");
    final watchedVideos = getWatchedVideos();

    // Remove if already exists
    watchedVideos.removeWhere((v) => v['id'] == video['id']);

    // Add to beginning
    watchedVideos.insert(0, _sanitizeForCache(video));

    // Keep only 10 most recent
    if (watchedVideos.length > 10) {
      watchedVideos.removeRange(10, watchedVideos.length);
    }

    return await _prefs.setString(
      CacheKeys.watchedVideos,
      jsonEncode(watchedVideos),
    );
  }
  List<Map<String, dynamic>> getWatchedVideos() {
    final watchedVideosString = _prefs.getString(CacheKeys.watchedVideos);
    if (watchedVideosString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(watchedVideosString);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<bool> clearWatchedVideos() async {
    return await _prefs.remove(CacheKeys.watchedVideos);
  }

  // ================ CACHED POSTS ================

  Future<bool> setCachedPosts(List<Map<String, dynamic>> posts) async {
    return await setCachedList(
      CacheKeys.cachedPosts,
      posts,
      expiration: _postsCacheExpiration,
    );
  }

  List<Map<String, dynamic>> getCachedPosts() {
    return getCachedList(CacheKeys.cachedPosts);
  }

  // ================ CACHED TIPS ================

  Future<bool> setCachedTips(List<Map<String, dynamic>> tips) async {
    return await setCachedList(CacheKeys.cachedTips, tips, expiration: _tipsCacheExpiration);
  }

  List<Map<String, dynamic>> getCachedTips() {
    return getCachedList(CacheKeys.cachedTips);
  }

  Future<bool> setCachedTipsByCategory(String category, List<Map<String, dynamic>> tips) async {
    return await setCachedList('${CacheKeys.cachedTips}_$category', tips, expiration: _tipsCacheExpiration);
  }

  List<Map<String, dynamic>> getCachedTipsByCategory(String category) {
    return getCachedList('${CacheKeys.cachedTips}_$category');
  }

  // ================ CACHED CHATS ================

  Future<bool> setCachedUserChats(String userId, List<Map<String, dynamic>> chats) async {
    return await setCachedList('${CacheKeys.userChats}_$userId', chats, expiration: _chatCacheExpiration);
  }

  List<Map<String, dynamic>> getCachedUserChats(String userId) {
    return getCachedList('${CacheKeys.userChats}_$userId');
  }

  Future<bool> setCachedMessages(String chatId, List<Map<String, dynamic>> messages) async {
    return await setCachedList('${CacheKeys.chatMessages}_$chatId', messages, expiration: _chatCacheExpiration);
  }

  List<Map<String, dynamic>> getCachedMessages(String chatId) {
    return getCachedList('${CacheKeys.chatMessages}_$chatId');
  }

  // ================ WEATHER DATA ================

  Future<bool> setWeatherData(Map<String, dynamic> weather) async {
    return await setCachedData(CacheKeys.weatherData, weather, expiration: const Duration(minutes: 30));
  }

  Map<String, dynamic>? getWeatherData() {
    return getCachedData(CacheKeys.weatherData);
  }

  // ================ LEGACY METHODS ================

  bool isOnboardingComplete() {
    return _prefs.getBool(CacheKeys.onboardingComplete) ?? false;
  }

  Future<bool> setOnboardingComplete(bool value) async {
    return await _prefs.setBool(CacheKeys.onboardingComplete, value);
  }

  DateTime? getLastWeatherUpdate() {
    final timestamp = _prefs.getString(CacheKeys.lastWeatherUpdate);
    if (timestamp != null) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> setLastWeatherUpdate(DateTime dateTime) async {
    return await _prefs.setString(
      CacheKeys.lastWeatherUpdate,
      dateTime.toIso8601String(),
    );
  }

  Map<String, dynamic>? getDailyTip() {
    final tip =getCachedData(CacheKeys.dailyTip);
    print(tip);
    return tip;
  }

  Map<String, dynamic> sanitizeTip(Map<String, dynamic> tip) {
    final sanitized = <String, dynamic>{};

    tip.forEach((key, value) {
      if (value is DateTime) {
        sanitized[key] = value.toIso8601String(); // or value.millisecondsSinceEpoch
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  Future<bool> setDailyTip(Map<String, dynamic> tip) async {
    final safeTip = sanitizeTip(tip);
    return await setCachedData(CacheKeys.dailyTip, safeTip, expiration: const Duration(hours: 24));
  }
  // ================ CACHE CLEANUP ================

  Future<void> clearExpiredCache() async {
    final allKeys = _prefs.getKeys();
    final keysToRemove = <String>[];

    for (final key in allKeys) {
      if (key.startsWith('cached_') || key.contains('_cache_')) {
        final data = getCachedData(key);
        if (data == null) {
          keysToRemove.add(key);
        }
      }
    }

    for (final key in keysToRemove) {
      await _prefs.remove(key);
    }
  }

  Future<void> clearAllCache() async {
    final allKeys = _prefs.getKeys();
    final cacheKeys = allKeys.where((key) =>
    key.startsWith('cached_') ||
        key.contains('_cache_') ||
        key == CacheKeys.weatherData ||
        key == CacheKeys.cachedPosts ||
        key == CacheKeys.cachedTips
    ).toList();

    for (final key in cacheKeys) {
      await _prefs.remove(key);
    }
  }



  // Generic Methods
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clear() async {
    return await _prefs.clear();
  }

  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}