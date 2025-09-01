import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

final recentVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.getRecentlyWatchedVideos();
});

final videosByCategoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.getVideosByCategory(category);
});

final allVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.getAllVideos();
});

final videoCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.getVideoCategories();
});

final searchVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  final videosRepository = ref.watch(videosRepositoryProvider);
  return await videosRepository.searchVideos(query);
});