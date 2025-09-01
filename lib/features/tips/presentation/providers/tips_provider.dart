import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

final dailyTipProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  return await tipsRepository.getDailyTip();
});

final tipsHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  return await tipsRepository.getTipsHistory();
});

final tipsByCategoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final tipsRepository = ref.watch(tipsRepositoryProvider);
  return await tipsRepository.getTipsByCategory(category);
});