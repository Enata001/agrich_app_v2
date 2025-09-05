// lib/features/tips/data/repositories/tips_repository.dart

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/config/app_config.dart';

class TipsRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  TipsRepository(this._firebaseService, this._localStorageService);

  // Get daily tip - ENHANCED with real Firebase integration
  Future<Map<String, dynamic>> getDailyTip() async {
    try {
      // Check if we have today's tip cached
      final cachedTip = _localStorageService.getDailyTip();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (cachedTip != null && cachedTip['date'] == today) {
        return cachedTip;
      }

      // Try to get today's featured tip from Firebase
      final featuredTip = await _getTodaysFeaturedTip();
      if (featuredTip != null) {
        await _localStorageService.setDailyTip(featuredTip);
        return featuredTip;
      }

      // Get a random high-priority tip
      final randomTip = await _getRandomTip();
      if (randomTip != null) {
        await _localStorageService.setDailyTip(randomTip);
        return randomTip;
      }

      // Create and return default tip if no tips exist
      final defaultTip = await _createDefaultTip();
      await _localStorageService.setDailyTip(defaultTip);
      return defaultTip;
    } catch (e) {
      // Return cached tip if available
      final cachedTip = _localStorageService.getDailyTip();
      if (cachedTip != null) {
        return cachedTip;
      }

      // Return default tip as fallback
      return _getDefaultTipData();
    }
  }

  // Get all tips - NEW IMPLEMENTATION with real-time updates
  Stream<List<Map<String, dynamic>>> getAllTips() {
    try {
      return _firebaseService.listenToCollection(
        AppConfig.tipsCollection,
        where: {'isActive': true},
        orderBy: 'priority',
        descending: true,
        limit: 50,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      return Stream.value(_getDefaultTips());
    }
  }

  // Get tips by category - NEW IMPLEMENTATION
  Stream<List<Map<String, dynamic>>> getTipsByCategory(String category) {
    try {
      return _firebaseService.listenToCollection(
        AppConfig.tipsCollection,
        where: {'isActive': true, 'category': category.toLowerCase()},
        orderBy: 'priority',
        descending: true,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Save/bookmark a tip - NEW IMPLEMENTATION
  Future<void> saveTip(String tipId, String userId) async {
    try {
      final savedTips = await _firebaseService.getSavedTips(userId);
      final alreadySaved = savedTips.docs.any((doc) =>
      (doc.data() as Map<String, dynamic>)['tipId'] == tipId);

      if (alreadySaved) {
        // Unsave - find and delete the saved tip document
        final savedTipDoc = savedTips.docs.firstWhere((doc) =>
        (doc.data() as Map<String, dynamic>)['tipId'] == tipId);
        await _firebaseService.unsaveTip(savedTipDoc.id);
      } else {
        // Save
        await _firebaseService.saveTip(userId, tipId);

        // Update tip save count
        await _incrementTipSaveCount(tipId);
      }
    } catch (e) {
      throw Exception('Failed to save tip: $e');
    }
  }

  // Check if tip is saved - NEW IMPLEMENTATION
  Future<bool> isTipSaved(String tipId, String userId) async {
    try {
      final savedTips = await _firebaseService.getSavedTips(userId);
      return savedTips.docs.any((doc) =>
      (doc.data() as Map<String, dynamic>)['tipId'] == tipId);
    } catch (e) {
      return false;
    }
  }

  // Get user's saved tips - NEW IMPLEMENTATION
  Stream<List<Map<String, dynamic>>> getUserSavedTips(String userId) {
    try {
      return _firebaseService.listenToCollection(
        'saved_tips', // Assuming this collection exists
        where: {'userId': userId},
        orderBy: 'createdAt',
        descending: true,
      ).asyncMap((snapshot) async {
        final savedTips = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final tipId = data['tipId'] as String;

          try {
            final tipDoc = await _firebaseService.getTip(tipId);
            if (tipDoc.exists) {
              final tipData = tipDoc.data() as Map<String, dynamic>;
              if (tipData['isActive'] == true) {
                savedTips.add({
                  'id': tipDoc.id,
                  'savedAt': (data['createdAt'] as Timestamp?)?.toDate(),
                  ...tipData,
                  'createdAt': (tipData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  'updatedAt': (tipData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                });
              }
            }
          } catch (e) {
            // Skip tips that can't be loaded
          }
        }

        return savedTips;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Like a tip - NEW IMPLEMENTATION
  Future<void> likeTip(String tipId, String userId) async {
    try {
      final tipDoc = await _firebaseService.getTip(tipId);
      if (!tipDoc.exists) throw Exception('Tip not found');

      final data = tipDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final currentLikesCount = data['likesCount'] as int? ?? 0;

      if (likedBy.contains(userId)) {
        // Unlike
        likedBy.remove(userId);
        await _firebaseService.updateTip(tipId, {
          'likedBy': likedBy,
          'likesCount': currentLikesCount - 1,
        });
      } else {
        // Like
        likedBy.add(userId);
        await _firebaseService.updateTip(tipId, {
          'likedBy': likedBy,
          'likesCount': currentLikesCount + 1,
        });
      }
    } catch (e) {
      throw Exception('Failed to like tip: $e');
    }
  }

  // Rate a tip - NEW IMPLEMENTATION
  Future<void> rateTip(String tipId, int rating, String userId) async {
    try {
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Store rating in subcollection
      await FirebaseFirestore.instance
          .collection(AppConfig.tipsCollection)
          .doc(tipId)
          .collection('ratings')
          .doc(userId)
          .set({
        'userId': userId,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update tip's average rating
      await _updateTipAverageRating(tipId);
    } catch (e) {
      throw Exception('Failed to rate tip: $e');
    }
  }

  // Get tip categories - NEW IMPLEMENTATION
  Future<List<String>> getTipCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.tipsCollection)
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
      return ['all', ...sortedCategories];
    } catch (e) {
      return ['all', 'planting', 'watering', 'pest control', 'harvesting', 'soil care'];
    }
  }

  // Search tips - NEW IMPLEMENTATION
  Future<List<Map<String, dynamic>>> searchTips(String query) async {
    try {
      if (query.isEmpty) return [];

      final searchTerms = query.toLowerCase().split(' ');
      final results = await FirebaseFirestore.instance
          .collection(AppConfig.tipsCollection)
          .where('isActive', isEqualTo: true)
          .where('searchTerms', arrayContainsAny: searchTerms)
          .limit(20)
          .get();

      return results.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Initialize default tips if database is empty - NEW IMPLEMENTATION
  Future<void> initializeDefaultTips() async {
    try {
      final tipsCount = await FirebaseFirestore.instance
          .collection(AppConfig.tipsCollection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      if (tipsCount.count == 0) {
        await _createDefaultTips();
      }
    } catch (e) {
      print('Failed to initialize default tips: $e');
    }
  }

  // Increment tip view count - NEW IMPLEMENTATION
  Future<void> incrementViewCount(String tipId) async {
    try {
      await _firebaseService.updateTip(tipId, {
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // View count increment failure shouldn't block the app
      print('Failed to increment view count: $e');
    }
  }

  // Get user tip stats - NEW IMPLEMENTATION
  Future<Map<String, int>> getUserTipStats(String userId) async {
    try {
      final savedTipsSnapshot = await FirebaseFirestore.instance
          .collection('saved_tips')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return {
        'savedTips': savedTipsSnapshot.count ?? 0,
        'likedTips': 0, // TODO: Implement if needed
      };
    } catch (e) {
      return {
        'savedTips': 0,
        'likedTips': 0,
      };
    }
  }

  // Get tips history - UPDATED to use Firebase
  Future<List<Map<String, dynamic>>> getTipsHistory() async {
    try {
      final snapshot = await _firebaseService.getTips();
      final tips = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        tips.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'category': data['category'] ?? 'General',
          'date': data['date'] ?? '',
          'author': data['author'] ?? 'AgriCH Team',
          'title': data['title'] ?? '',
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }

      return tips;
    } catch (e) {
      return [];
    }
  }

  // Private helper methods
  Future<Map<String, dynamic>?> _getTodaysFeaturedTip() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.tipsCollection)
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .where('featuredDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('featuredDate', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return _formatTipData(snapshot.docs.first.id, data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getRandomTip() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.tipsCollection)
          .where('isActive', isEqualTo: true)
          .where('priority', isGreaterThan: 7)
          .limit(10)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final randomIndex = DateTime.now().day % snapshot.docs.length;
        final doc = snapshot.docs[randomIndex];
        return _formatTipData(doc.id, doc.data());
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _createDefaultTip() async {
    final _ = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final defaultTipData = {
      'title': 'Start Your Farming Journey',
      'content': 'Welcome to AgriCH! Check soil moisture before watering your plants. Overwatering is one of the most common mistakes new gardeners make.',
      'category': 'watering',
      'priority': 8,
      'difficulty': 'beginner',
      'estimatedTime': '5 minutes',
      'tools': ['Soil moisture meter', 'Watering can'],
      'benefits': ['Healthy plant growth', 'Water conservation'],
      'tags': ['watering', 'beginner', 'soil'],
      'searchTerms': ['watering', 'soil', 'moisture', 'beginner', 'plants'],
      'author': 'AgriCH Team',
      'authorId': 'system',
      'authorAvatar': null,
      'imageUrl': null,
      'videoUrl': null,
      'likesCount': 0,
      'likedBy': <String>[],
      'saveCount': 0,
      'ratingCount': 0,
      'averageRating': 0.0,
      'viewCount': 0,
      'isFeatured': true,
      'featuredDate': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    // Save to Firebase
    try {
      final docRef = await _firebaseService.createTip(defaultTipData);
      return _formatTipData(docRef.id, defaultTipData);
    } catch (e) {
      return _getDefaultTipData();
    }
  }

  Future<void> _createDefaultTips() async {
    final defaultTips = [
      {
        'title': 'Test Your Soil pH',
        'content': 'Most vegetables prefer slightly acidic to neutral soil (pH 6.0-7.0). Test your soil pH regularly and amend with lime to raise pH or sulfur to lower it.',
        'category': 'soil care',
        'priority': 9,
        'difficulty': 'intermediate',
        'estimatedTime': '30 minutes',
        'tools': ['pH test kit', 'Lime or sulfur'],
        'benefits': ['Better nutrient uptake', 'Improved plant health'],
        'tags': ['soil', 'pH', 'testing'],
      },
      {
        'title': 'Companion Planting Basics',
        'content': 'Plant basil near tomatoes to improve flavor and repel pests. Marigolds planted throughout the garden help deter harmful insects.',
        'category': 'planting',
        'priority': 8,
        'difficulty': 'beginner',
        'estimatedTime': '15 minutes',
        'tools': ['Seeds', 'Garden tools'],
        'benefits': ['Natural pest control', 'Better yields'],
        'tags': ['companion planting', 'organic', 'pest control'],
      },
      {
        'title': 'Water Early Morning',
        'content': 'Water your plants early in the morning (6-8 AM) to reduce evaporation and give plants time to dry before evening, preventing fungal diseases.',
        'category': 'watering',
        'priority': 7,
        'difficulty': 'beginner',
        'estimatedTime': '10 minutes',
        'tools': ['Watering can', 'Hose'],
        'benefits': ['Better water absorption', 'Disease prevention'],
        'tags': ['watering', 'timing', 'disease prevention'],
      },
      {
        'title': 'Mulch for Moisture Retention',
        'content': 'Apply 2-3 inches of organic mulch around plants to retain soil moisture, suppress weeds, and regulate soil temperature.',
        'category': 'soil care',
        'priority': 8,
        'difficulty': 'beginner',
        'estimatedTime': '20 minutes',
        'tools': ['Mulch', 'Rake'],
        'benefits': ['Water conservation', 'Weed suppression', 'Soil health'],
        'tags': ['mulch', 'water conservation', 'organic'],
      },
      {
        'title': 'Harvest at the Right Time',
        'content': 'Pick tomatoes when they start to turn color and ripen them indoors to prevent cracking. Harvest lettuce in the morning when leaves are crisp.',
        'category': 'harvesting',
        'priority': 9,
        'difficulty': 'intermediate',
        'estimatedTime': '15 minutes',
        'tools': ['Pruning shears', 'Harvest basket'],
        'benefits': ['Better flavor', 'Longer storage life'],
        'tags': ['harvesting', 'timing', 'quality'],
      },
      {
        'title': 'Natural Pest Control',
        'content': 'Spray neem oil solution (1-2 tablespoons per quart of water) on plants in the evening to control aphids, whiteflies, and other soft-bodied insects.',
        'category': 'pest control',
        'priority': 8,
        'difficulty': 'intermediate',
        'estimatedTime': '20 minutes',
        'tools': ['Neem oil', 'Spray bottle', 'Measuring spoons'],
        'benefits': ['Organic pest control', 'Safe for beneficial insects'],
        'tags': ['organic', 'pest control', 'neem oil'],
      },
      {
        'title': 'Crop Rotation Benefits',
        'content': 'Rotate plant families each season. Follow heavy feeders (tomatoes) with light feeders (beans) to maintain soil health and prevent pest buildup.',
        'category': 'planting',
        'priority': 7,
        'difficulty': 'advanced',
        'estimatedTime': 'Planning time',
        'tools': ['Garden plan', 'Notebook'],
        'benefits': ['Soil health', 'Pest prevention', 'Better yields'],
        'tags': ['crop rotation', 'planning', 'soil health'],
      },
      {
        'title': 'Composting Kitchen Scraps',
        'content': 'Create nutrient-rich compost by layering green materials (kitchen scraps) with brown materials (dry leaves) in a 1:3 ratio. Turn weekly.',
        'category': 'soil care',
        'priority': 6,
        'difficulty': 'intermediate',
        'estimatedTime': '30 minutes weekly',
        'tools': ['Compost bin', 'Pitchfork', 'Kitchen scraps'],
        'benefits': ['Free fertilizer', 'Waste reduction', 'Soil improvement'],
        'tags': ['composting', 'organic', 'sustainability'],
      },
    ];

    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < defaultTips.length; i++) {
      final tipData = defaultTips[i];

      // Generate search terms
      final tags = tipData['tags'] as List<dynamic>? ?? [];
      final tagsString = tags.map((tag) => tag.toString()).join(' ');
      final searchTerms = _generateSearchTerms(
        '${tipData['title']} ${tipData['content']} $tagsString',
      );

      final enhancedTipData = {
        ...tipData,
        'searchTerms': searchTerms,
        'author': 'AgriCH Team',
        'authorId': 'system',
        'authorAvatar': null,
        'imageUrl': null,
        'videoUrl': null,
        'likesCount': 0,
        'likedBy': <String>[],
        'saveCount': 0,
        'ratingCount': 0,
        'averageRating': 0.0,
        'viewCount': 0,
        'isFeatured': i == 0,
        'featuredDate': i == 0 ? FieldValue.serverTimestamp() : null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final tipRef = FirebaseFirestore.instance
          .collection(AppConfig.tipsCollection)
          .doc('default_tip_${i + 1}');
      batch.set(tipRef, enhancedTipData);
    }

    await batch.commit();
  }

  Map<String, dynamic> _formatTipData(String id, Map<String, dynamic> data) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return {
      'id': id,
      'title': data['title'] ?? 'Daily Tip',
      'content': data['content'] ?? 'No content available',
      'category': data['category'] ?? 'General',
      'priority': data['priority'] ?? 5,
      'difficulty': data['difficulty'] ?? 'beginner',
      'estimatedTime': data['estimatedTime'] ?? '5 minutes',
      'tools': List<String>.from(data['tools'] ?? []),
      'benefits': List<String>.from(data['benefits'] ?? []),
      'tags': List<String>.from(data['tags'] ?? []),
      'author': data['author'] ?? 'AgriCH Team',
      'date': today,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    };
  }

  Map<String, dynamic> _getDefaultTipData() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return {
      'id': 'default_tip',
      'title': 'Start Your Farming Journey',
      'content': 'Welcome to AgriCH! Check soil moisture before watering your plants. Overwatering is one of the most common mistakes new gardeners make.',
      'category': 'watering',
      'priority': 8,
      'difficulty': 'beginner',
      'estimatedTime': '5 minutes',
      'tools': ['Soil moisture meter', 'Watering can'],
      'benefits': ['Healthy plant growth', 'Water conservation'],
      'tags': ['watering', 'beginner', 'soil'],
      'author': 'AgriCH Team',
      'date': today,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  List<Map<String, dynamic>> _getDefaultTips() {
    return [
      {
        'id': 'default_1',
        'title': 'Check Soil Moisture',
        'content': 'Always check soil moisture before watering. Stick your finger 2 inches deep into the soil.',
        'category': 'watering',
        'priority': 8,
        'difficulty': 'beginner',
        'estimatedTime': '2 minutes',
        'tools': ['Your finger', 'Soil moisture meter'],
        'benefits': ['Prevent overwatering', 'Healthy root development'],
        'tags': ['watering', 'soil', 'beginner'],
        'author': 'AgriCH Team',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'id': 'default_2',
        'title': 'Morning Watering',
        'content': 'Water your plants early in the morning when evaporation is minimal and plants can absorb water effectively.',
        'category': 'watering',
        'priority': 7,
        'difficulty': 'beginner',
        'estimatedTime': '5 minutes',
        'tools': ['Watering can', 'Hose'],
        'benefits': ['Better water absorption', 'Disease prevention'],
        'tags': ['watering', 'timing', 'morning'],
        'author': 'AgriCH Team',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
    ];
  }

  List<String> _generateSearchTerms(String text) {
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.isNotEmpty && word.length > 2)
        .toSet()
        .toList();

    final searchTerms = <String>{};

    for (final word in words) {
      searchTerms.add(word);
      // Add partial matches for longer words
      if (word.length > 4) {
        for (int i = 3; i <= word.length; i++) {
          searchTerms.add(word.substring(0, i));
        }
      }
    }

    return searchTerms.toList();
  }

  Future<void> _incrementTipSaveCount(String tipId) async {
    try {
      await _firebaseService.updateTip(tipId, {
        'saveCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Save count increment failure shouldn't block the app
    }
  }

  Future<void> _updateTipAverageRating(String tipId) async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection(AppConfig.tipsCollection)
          .doc(tipId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (final doc in ratingsSnapshot.docs) {
          final data = doc.data();
          totalRating += (data['rating'] as num).toDouble();
        }

        final averageRating = totalRating / ratingsSnapshot.docs.length;

        await _firebaseService.updateTip(tipId, {
          'averageRating': averageRating,
          'ratingCount': ratingsSnapshot.docs.length,
        });
      }
    } catch (e) {
      print('Failed to update tip average rating: $e');
    }
  }
}