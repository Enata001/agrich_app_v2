import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

// Daily Tip Provider - Single source of truth
final dailyTipProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // ref.keepAlive();
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  try {
    print("Trying here first");
    return await tipsRepository.getDailyTip();
  } catch (e) {
    return {
      'id': 'fallback_daily_tip',
      'title': 'Daily Farming Tip',
      'content': 'Water your plants early in the morning for better absorption and to prevent fungal diseases.',
      'category': 'watering',
      'author': 'AgriBot',
      'createdAt': DateTime.now(),
      'isActive': true,
      'likesCount': 0,
      'isSaved': false,
      'isLiked': false,
    };
  }
});

final allTipsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final networkService = ref.watch(networkServiceProvider);
  final tipsRepository = ref.watch(tipsRepositoryProvider);

  // Yield cached tips first
  final cachedTips = await tipsRepository.getCachedTips();
  if (cachedTips.isNotEmpty) {
    yield cachedTips;
  }

  // Check network connectivity
  final isConnected = await networkService.checkConnectivity();
  if (!isConnected) {
    if (cachedTips.isEmpty) {
      yield [];
    }
    return;
  }

  try {
    // Timeout only on first emission
    final firstTips = await tipsRepository.getAllTips().first.timeout(const Duration(seconds: 12));
    yield firstTips;

    // Continue streaming updates
    yield* tipsRepository.getAllTips();
  } catch (e) {
    print('Error loading tips: $e');
    final fallback = await tipsRepository.getCachedTips();
    yield fallback;
  }
});
// ✅ FIXED: Tips by Category Provider with auto-dispose
final tipsByCategoryProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, category) async* {
  final networkService = ref.watch(networkServiceProvider);
  final tipsRepository = ref.watch(tipsRepositoryProvider);

  // First yield cached data for this category
  final cachedTips = await tipsRepository.getCachedTipsByCategory(category);
  if (cachedTips.isNotEmpty) {
    yield cachedTips;
  }

  final isConnected = await networkService.checkConnectivity();
  if (!isConnected) {
    if (cachedTips.isEmpty) {
      yield [];
    }
    return;
  }

  try {
    if (category == 'all') {
      yield* tipsRepository.getAllTips().timeout(
        const Duration(seconds: 12),
        onTimeout: (sink) async {
          final cached = await tipsRepository.getCachedTips();
          sink.add(cached);
        },
      );
    } else {
      yield* tipsRepository.getTipsByCategory(category).timeout(
        const Duration(seconds: 12),
        onTimeout: (sink) async {
          final cached = await tipsRepository.getCachedTipsByCategory(category);
          sink.add(cached);
        },
      );
    }
  } catch (e) {
    print('Error loading tips for category $category: $e');
    final cached = await tipsRepository.getCachedTipsByCategory(category);
    yield cached;
  }
});

// ✅ Tips Categories Provider - Future provider since categories don't change often
final tipsCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final networkService = ref.watch(networkServiceProvider);
  final tipsRepository = ref.watch(tipsRepositoryProvider);

  try {
    if (await networkService.checkConnectivity()) {
      return await tipsRepository.getTipCategories().timeout(
        const Duration(seconds: 8),
      );
    } else {
      // Return default categories when offline
      return [
        'all',
        'planting',
        'watering',
        'pest control',
        'harvesting',
        'soil care',
        'fertilization',
        'crop rotation',
        'seasonal',
      ];
    }
  } catch (e) {
    // Return default categories if there's an error
    return [
      'all',
      'planting',
      'watering',
      'pest control',
      'harvesting',
      'soil care',
      'fertilization',
      'crop rotation',
      'seasonal',
    ];
  }
});
// Search Tips Provider
final searchTipsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final tipsRepository = ref.watch(tipsRepositoryProvider);
  try {
    return await tipsRepository.searchTips(query);
  } catch (e) {
    print('Error searching tips: $e');
    return [];
  }
});

// Saved Tips Provider
final savedTipsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  try {
    return await tipsRepository.getUserSavedTips(userId).first;
  } catch (e) {
    print('Error loading saved tips: $e');
    return [];
  }
});

// Popular Tips Provider (by likes)
final popularTipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  try {
    final allTips = await tipsRepository.getAllTips().last;

    // Sort by likes count
    final sortedTips = List<Map<String, dynamic>>.from(allTips);
    sortedTips.sort((a, b) {
      final aLikes = a['likesCount'] as int? ?? 0;
      final bLikes = b['likesCount'] as int? ?? 0;
      return bLikes.compareTo(aLikes);
    });

    return sortedTips.take(10).toList(); // Top 10 popular tips
  } catch (e) {
    print('Error loading popular tips: $e');
    return [];
  }
});

// Recent Tips Provider
final recentTipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  try {
    final allTips = await tipsRepository.getAllTips().last;

    // Sort by creation date
    final sortedTips = List<Map<String, dynamic>>.from(allTips);
    sortedTips.sort((a, b) {
      final aDate = a['createdAt'] as DateTime? ?? DateTime.now();
      final bDate = b['createdAt'] as DateTime? ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return sortedTips.take(5).toList(); // 5 most recent tips
  } catch (e) {
    print('Error loading recent tips: $e');
    return [];
  }
});

// Tips Stats Provider
final tipsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  try {
    final allTips = await tipsRepository.getAllTips().last;
    final categories = await tipsRepository.getTipCategories();

    final totalTips = allTips.length;
    final totalLikes = allTips.fold<int>(0, (sum, tip) => sum + (tip['likesCount'] as int? ?? 0));
    final averageLikes = totalTips > 0 ? totalLikes / totalTips : 0.0;

    // Category distribution
    final categoryCount = <String, int>{};
    for (final tip in allTips) {
      final category = tip['category'] as String? ?? 'other';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    return {
      'totalTips': totalTips,
      'totalLikes': totalLikes,
      'averageLikes': averageLikes,
      'totalCategories': categories.length,
      'categoryDistribution': categoryCount,
      'mostPopularCategory': categoryCount.entries.isNotEmpty
          ? categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'none',
    };
  } catch (e) {
    return {
      'totalTips': 0,
      'totalLikes': 0,
      'averageLikes': 0.0,
      'totalCategories': 0,
      'categoryDistribution': <String, int>{},
      'mostPopularCategory': 'none',
    };
  }
});


final tipDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, tipId) async {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  try {
    return await tipsRepository.getTipDetails(tipId);
  } catch (e) {
    print('Error loading tip details for $tipId: $e');
    return null;
  }
});

// User Tip Interaction Provider (for checking if user liked/saved a tip)
final userTipInteractionProvider = FutureProvider.family<Map<String, bool>, Map<String, String>>((ref, params) async {
  final tipId = params['tipId']!;
  final userId = params['userId']!;
  final tipsRepository = ref.watch(tipsRepositoryProvider);

  try {
    final isLiked = await tipsRepository.isTipLiked(tipId, userId);
    final isSaved = await tipsRepository.isTipSaved(tipId, userId);

    return {
      'isLiked': isLiked,
      'isSaved': isSaved,
    };
  } catch (e) {
    return {
      'isLiked': false,
      'isSaved': false,
    };
  }
});

// Tips Filter State Provider
class TipsFilterState {
  final String category;
  final String sortBy; // 'recent', 'popular', 'alphabetical'
  final bool showSavedOnly;

  TipsFilterState({
    this.category = 'all',
    this.sortBy = 'recent',
    this.showSavedOnly = false,
  });

  TipsFilterState copyWith({
    String? category,
    String? sortBy,
    bool? showSavedOnly,
  }) {
    return TipsFilterState(
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      showSavedOnly: showSavedOnly ?? this.showSavedOnly,
    );
  }
}

final tipsFilterProvider = StateProvider<TipsFilterState>((ref) => TipsFilterState());

// Filtered Tips Provider (combines all filters)
final filteredTipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref)async  {
  final filter = ref.watch(tipsFilterProvider);
  final tipsRepository = ref.watch(tipsRepositoryProvider);

  try {
    List<Map<String, dynamic>> tips;

    // Get tips by category
    if (filter.category == 'all') {
      tips = await tipsRepository.getAllTips().last;
    } else {
      tips = await tipsRepository.getTipsByCategory(filter.category).last;
    }

    // Filter saved only if requested
    if (filter.showSavedOnly) {
      tips = tips.where((tip) => tip['isSaved'] == true).toList();
    }

    // Sort tips
    switch (filter.sortBy) {
      case 'popular':
        tips.sort((a, b) {
          final aLikes = a['likesCount'] as int? ?? 0;
          final bLikes = b['likesCount'] as int? ?? 0;
          return bLikes.compareTo(aLikes);
        });
        break;
      case 'alphabetical':
        tips.sort((a, b) {
          final aTitle = a['title'] as String? ?? '';
          final bTitle = b['title'] as String? ?? '';
          return aTitle.compareTo(bTitle);
        });
        break;
      case 'recent':
      default:
        tips.sort((a, b) {
          final aDate = a['createdAt'] as DateTime? ?? DateTime.now();
          final bDate = b['createdAt'] as DateTime? ?? DateTime.now();
          return bDate.compareTo(aDate);
        });
        break;
    }

    return tips;
  } catch (e) {
    print('Error filtering tips: $e');
    return [];
  }
});

// Tips Actions (for user interactions)
final tipsActionsProvider = Provider<TipsActions>((ref) {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  return TipsActions(tipsRepository, ref);
});

class TipsActions {
  final dynamic tipsRepository; // TipsRepository
  final Ref ref;

  TipsActions(this.tipsRepository, this.ref);

  Future<void> likeTip(String tipId, String userId) async {
    try {
      await tipsRepository.likeTip(tipId, userId);
      // Invalidate relevant providers to refresh data
      ref.invalidate(allTipsProvider);
      ref.invalidate(tipDetailsProvider(tipId));
      ref.invalidate(userTipInteractionProvider);
    } catch (e) {
      print('Error liking tip: $e');
      rethrow;
    }
  }

  Future<void> saveTip(String tipId, String userId) async {
    try {
      await tipsRepository.saveTip(tipId, userId);
      // Invalidate relevant providers
      ref.invalidate(savedTipsProvider(userId));
      ref.invalidate(userTipInteractionProvider);
    } catch (e) {
      print('Error saving tip: $e');
      rethrow;
    }
  }

  Future<void> rateTip(String tipId, int rating, String userId) async {
    try {
      await tipsRepository.rateTip(tipId, rating, userId);
      ref.invalidate(tipDetailsProvider(tipId));
    } catch (e) {
      print('Error rating tip: $e');
      rethrow;
    }
  }

  Future<void> incrementViewCount(String tipId) async {
    try {
      await tipsRepository.incrementViewCount(tipId);
    } catch (e) {
      // Don't rethrow as view count is not critical
    }
  }
}