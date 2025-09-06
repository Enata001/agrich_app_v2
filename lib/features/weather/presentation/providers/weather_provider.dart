import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

// Current Weather Provider
final currentWeatherProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  return await weatherRepository.getCurrentWeatherWithFallback();
});

// Weather Forecast Provider (5 days, 3-hour intervals)
final weatherForecastProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  try {
    return await weatherRepository.getWeatherForecast(days: 5);
  } catch (e) {
    // Return empty list on error - the UI will handle this gracefully
    return <Map<String, dynamic>>[];
  }
});

// Daily Weather Forecast Provider (next 7 days)
final dailyWeatherForecastProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  try {
    return await weatherRepository.getDailyForecast(days: 7);
  } catch (e) {
    // Return empty list on error
    return <Map<String, dynamic>>[];
  }
});

// Farming Advice Provider
final farmingAdviceProvider = FutureProvider<String>((ref) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  final currentWeather = await ref.watch(currentWeatherProvider.future);

  try {
    return weatherRepository.getFarmingAdvice(currentWeather);
  } catch (e) {
    return 'Weather data unavailable for farming recommendations.';
  }
});

// Farming Weather Condition Provider
final isFarmingWeatherGoodProvider = FutureProvider<bool>((ref) async {
  final currentWeather = await ref.watch(currentWeatherProvider.future);

  try {
    final temperature = currentWeather['temperature'] as double? ?? 0.0;
    final humidity = currentWeather['humidity'] as int? ?? 0;
    final windSpeed = currentWeather['windSpeed'] as double? ?? 0.0;
    final condition = currentWeather['main'] as String? ?? '';

    // Define good farming conditions
    final isTemperatureGood = temperature >= 15 && temperature <= 30;
    final isHumidityGood = humidity >= 40 && humidity <= 70;
    final isWindGood = windSpeed < 15; // Less than 15 m/s
    final isConditionGood = !condition.toLowerCase().contains('thunderstorm') &&
        !condition.toLowerCase().contains('snow');

    return isTemperatureGood && isHumidityGood && isWindGood && isConditionGood;
  } catch (e) {
    return false;
  }
});

// Weather Alerts Provider (if using OneCall API)
final weatherAlertsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  try {
    return await weatherRepository.getWeatherAlerts();
  } catch (e) {
    return <Map<String, dynamic>>[];
  }
});

// Location-based Weather Provider
final locationWeatherProvider = FutureProvider.family<Map<String, dynamic>, Map<String, double>>((ref, coordinates) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  try {
    return await weatherRepository.getWeatherByCoordinates(
      coordinates['lat']!,
      coordinates['lon']!,
    );
  } catch (e) {
    throw Exception('Failed to get location-based weather: $e');
  }
});

// City-based Weather Provider
final cityWeatherProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, cityName) async {
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  try {
    return await weatherRepository.getWeatherByCity(cityName);
  } catch (e) {
    throw Exception('Failed to get city weather: $e');
  }
});