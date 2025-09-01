import 'package:intl/intl.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';

class TipsRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  TipsRepository(this._firebaseService, this._localStorageService);

  Future<Map<String, dynamic>> getDailyTip() async {
    try {
      // Check if we have today's tip cached
      final cachedTip = _localStorageService.getDailyTip();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (cachedTip != null && cachedTip['date'] == today) {
        return cachedTip;
      }

      // Fetch from Firebase
      final tipDoc = await _firebaseService.getTodaysTip();
      if (tipDoc.exists) {
        final tipData = tipDoc.data() as Map<String, dynamic>;
        final tip = {
          'content': tipData['content'] ?? _getDefaultTip(),
          'category': tipData['category'] ?? 'General',
          'date': today,
          'author': tipData['author'] ?? 'Agrich Team',
        };

        // Cache the tip
        await _localStorageService.setDailyTip(tip);
        return tip;
      } else {
        // Return default tip if none found for today
        final defaultTip = {
          'content': _getDefaultTip(),
          'category': 'General',
          'date': today,
          'author': 'Agrich Team',
        };

        await _localStorageService.setDailyTip(defaultTip);
        return defaultTip;
      }
    } catch (e) {
      // Return cached tip if available
      final cachedTip = _localStorageService.getDailyTip();
      if (cachedTip != null) {
        return cachedTip;
      }

      // Return default tip as fallback
      return {
        'content': _getDefaultTip(),
        'category': 'General',
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'author': 'Agrich Team',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTipsHistory() async {
    try {
      final snapshot = await _firebaseService.getAllTips();
      final tips = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        tips.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'category': data['category'] ?? 'General',
          'date': data['date'] ?? '',
          'author': data['author'] ?? 'Agrich Team',
        });
      }

      // Sort by date (most recent first)
      tips.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      return tips;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTipsByCategory(String category) async {
    try {
      final snapshot = await _firebaseService.tips
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      final tips = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        tips.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'category': data['category'] ?? 'General',
          'date': data['date'] ?? '',
          'author': data['author'] ?? 'Agrich Team',
        });
      }

      return tips;
    } catch (e) {
      return [];
    }
  }

  String _getDefaultTip() {
    final tips = [
      'Water your crops early in the morning to reduce evaporation and maximize absorption.',
      'Rotate your crops seasonally to maintain soil fertility and prevent pest buildup.',
      'Use compost made from organic waste to enrich your soil naturally.',
      'Check your plants regularly for signs of pests or diseases to catch problems early.',
      'Plant cover crops during off-seasons to protect and improve soil health.',
      'Ensure proper spacing between plants to allow adequate airflow and sunlight.',
      'Keep detailed records of planting dates, weather conditions, and harvest yields.',
      'Use mulch around plants to retain moisture and suppress weeds.',
      'Test your soil pH regularly and adjust with lime or sulfur as needed.',
      'Choose drought-resistant varieties if you\'re in an area with limited water supply.',
    ];

    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return tips[dayOfYear % tips.length];
  }
}