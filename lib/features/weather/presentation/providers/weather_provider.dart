import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/weather_repository.dart';

final currentWeatherProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  return await weatherRepository.getCurrentWeather();
});

final weatherForecastProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  return await weatherRepository.getWeatherForecast(days: days);
});

final farmingAdviceProvider = FutureProvider<String>((ref) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  return await weatherRepository.getFarmingAdvice();
});