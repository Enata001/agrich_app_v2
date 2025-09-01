import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

final communityPostsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return await communityRepository.getPosts();
});

final postDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, postId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return await communityRepository.getPostDetails(postId);
});

final postCommentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, postId) async {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return await communityRepository.getPostComments(postId);
});