import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Onboarding
  Future<bool> setOnboardingComplete(bool value) async {
    return await _prefs.setBool(CacheKeys.onboardingComplete, value);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool(CacheKeys.onboardingComplete) ?? false;
  }

  // User Data
  Future<bool> setUserData(Map<String, dynamic> userData) async {
    return await _prefs.setString(CacheKeys.userData, jsonEncode(userData));
  }

  Map<String, dynamic>? getUserData() {
    final userDataString = _prefs.getString(CacheKeys.userData);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> clearUserData() async {
    return await _prefs.remove(CacheKeys.userData);
  }

  // Watched Videos
  Future<bool> addWatchedVideo(Map<String, dynamic> video) async {
    final watchedVideos = getWatchedVideos();

    // Remove if already exists to avoid duplicates
    watchedVideos.removeWhere((v) => v['id'] == video['id']);

    // Add to beginning of list
    watchedVideos.insert(0, video);

    // Keep only last 50 videos
    if (watchedVideos.length > 50) {
      watchedVideos.removeRange(50, watchedVideos.length);
    }

    return await _prefs.setString(
      CacheKeys.watchedVideos,
      jsonEncode(watchedVideos),
    );
  }

  List<Map<String, dynamic>> getWatchedVideos() {
    final watchedVideosString = _prefs.getString(CacheKeys.watchedVideos);
    if (watchedVideosString != null) {
      final List<dynamic> decoded = jsonDecode(watchedVideosString);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<bool> clearWatchedVideos() async {
    return await _prefs.remove(CacheKeys.watchedVideos);
  }

  // Daily Tip
  Future<bool> setDailyTip(Map<String, dynamic> tip) async {
    return await _prefs.setString(CacheKeys.dailyTip, jsonEncode(tip));
  }

  Map<String, dynamic>? getDailyTip() {
    final tipString = _prefs.getString(CacheKeys.dailyTip);
    if (tipString != null) {
      return jsonDecode(tipString) as Map<String, dynamic>;
    }
    return null;
  }

  // Weather Data
  Future<bool> setWeatherData(Map<String, dynamic> weather) async {
    return await _prefs.setString(CacheKeys.weatherData, jsonEncode(weather));
  }

  Map<String, dynamic>? getWeatherData() {
    final weatherString = _prefs.getString(CacheKeys.weatherData);
    if (weatherString != null) {
      return jsonDecode(weatherString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> setLastWeatherUpdate(DateTime dateTime) async {
    return await _prefs.setString(
      CacheKeys.lastWeatherUpdate,
      dateTime.toIso8601String(),
    );
  }

  DateTime? getLastWeatherUpdate() {
    final dateString = _prefs.getString(CacheKeys.lastWeatherUpdate);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  bool isWeatherDataExpired() {
    final lastUpdate = getLastWeatherUpdate();
    if (lastUpdate == null) return true;

    return DateTime.now().difference(lastUpdate) > AppConfig.cacheExpiration;
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