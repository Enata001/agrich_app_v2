import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

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
final weatherByCityProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, cityName) async {
  final weatherRepository = ref.read(weatherRepositoryProvider);
  return await weatherRepository.getWeatherByCity(cityName);
});

final weatherAlertsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final weatherRepository = ref.read(weatherRepositoryProvider);
  return await weatherRepository.getWeatherAlerts();
});

final cropRecommendationsProvider = FutureProvider.family<List<String>, String>((ref, cropType) async {
  final weatherRepository = ref.read(weatherRepositoryProvider);
  return await weatherRepository.getCropRecommendations(cropType);
});

final locationServiceAvailableProvider = FutureProvider<bool>((ref) async {
  final weatherRepository = ref.read(weatherRepositoryProvider);
  return await weatherRepository.isLocationServiceAvailable();
});

final isFarmingWeatherGoodProvider = Provider<bool>((ref) {
  final weatherAsync = ref.watch(currentWeatherProvider);
  final weatherService = ref.read(weatherServiceProvider);

  return weatherAsync.when(
    data: (weather) => weatherService.isFarmingWeatherGood(weather),
    loading: () => false,
    error: (_, _) => false,
  );
});