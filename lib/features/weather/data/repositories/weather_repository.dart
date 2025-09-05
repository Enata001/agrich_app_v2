import 'dart:convert';

import '../../../../core/services/weather_service.dart';
import '../../../../core/services/local_storage_service.dart';

class WeatherRepository {
  final WeatherService _weatherService;
  final LocalStorageService _localStorageService;

  WeatherRepository(this._weatherService, this._localStorageService);

  // Get current weather - ENHANCED with better error handling
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // Check if cached data is still valid (within 30 minutes)
      if (!_localStorageService.isWeatherDataExpired()) {
        final cachedWeather = _localStorageService.getWeatherData();
        if (cachedWeather != null) {
          return cachedWeather;
        }
      }

      // Fetch fresh weather data using GPS location
      final position = await _weatherService.getCurrentLocation();
      final weatherData = await _weatherService.getCurrentWeather(
        lat: position.latitude,
        lon: position.longitude,
      );

      // Cache the data with timestamp
      await _localStorageService.setWeatherData(weatherData);
      await _localStorageService.setLastWeatherUpdate(DateTime.now());

      return weatherData;
    } catch (e) {
      // Try to return cached data even if expired
      final cachedWeather = _localStorageService.getWeatherData();
      if (cachedWeather != null) {
        // Add an indicator that data might be stale
        cachedWeather['isStale'] = true;
        cachedWeather['error'] = e.toString();
        return cachedWeather;
      }

      // If no cached data available, return error with default structure
      return _getErrorWeatherData(e.toString());
    }
  }

  Future<Map<String, dynamic>> getCurrentWeatherWithFallback() async {
    try {
      // Check if cached data is still valid
      if (!_localStorageService.isWeatherDataExpired()) {
        final cachedWeather = _localStorageService.getWeatherData();
        if (cachedWeather != null) {
          return cachedWeather;
        }
      }

      // Try to get location-based weather
      try {
        final position = await _weatherService.getCurrentLocation();
        final weatherData = await _weatherService.getCurrentWeather(
          lat: position.latitude,
          lon: position.longitude,
        );

        // Cache the data
        await _localStorageService.setWeatherData(weatherData);
        await _localStorageService.setLastWeatherUpdate(DateTime.now());

        return weatherData;
      } catch (locationError) {
        // If location fails, try to get weather for Accra (default location)
        print('Location failed, using default location: $locationError');

        final weatherData = await _weatherService.getCurrentWeather(
          cityName: 'Accra,GH',
        );

        // Cache the data
        await _localStorageService.setWeatherData(weatherData);
        await _localStorageService.setLastWeatherUpdate(DateTime.now());

        return weatherData;
      }
    } catch (e) {
      // Return cached data if available, even if expired
      final cachedWeather = _localStorageService.getWeatherData();
      if (cachedWeather != null) {
        return cachedWeather;
      }

      // Return default weather data as last resort
      return _getErrorWeatherData(e.toString());
    }
  }


  Future<List<Map<String, dynamic>>> getWeatherForecast({int days = 5}) async {
    try {
      final position = await _weatherService.getCurrentLocation();
      final forecast = await _weatherService.getWeatherForecast(
        lat: position.latitude,
        lon: position.longitude,
        days: days,
      );

      // ✅ PROPER JSON ENCODING
      await _localStorageService.setString(
        'weather_forecast',
        jsonEncode(forecast),
      );

      return forecast;
    } catch (e) {
      // ✅ PROPER PARSING OF CACHED DATA
      final cachedForecast = _localStorageService.getString('weather_forecast');
      if (cachedForecast != null) {
        try {
          final decoded = jsonDecode(cachedForecast) as List;
          return decoded.cast<Map<String, dynamic>>();
        } catch (parseError) {
          print('Failed to parse cached forecast: $parseError');
        }
      }

      return []; // Return empty only as last resort
    }
  }
  // Get weather by city name - NEW METHOD
  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      final weatherData = await _weatherService.getCurrentWeather(
        cityName: cityName,
      );

      return weatherData;
    } catch (e) {
      return _getErrorWeatherData(e.toString());
    }
  }

  // Get farming advice based on weather - ENHANCED implementation
  Future<String> getFarmingAdvice() async {
    try {
      final weatherData = await getCurrentWeather();

      if (weatherData.containsKey('error')) {
        return 'Unable to provide farming advice due to weather data unavailability.';
      }

      return _weatherService.getFarmingAdvice(weatherData);
    } catch (e) {
      return 'Unable to provide farming advice at the moment. Please try again later.';
    }
  }

  // Get weather alerts - NEW METHOD
  Future<List<Map<String, dynamic>>> getWeatherAlerts() async {
    try {
      final position = await _weatherService.getCurrentLocation();
      // This would require a weather service method for alerts
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }

  // Check if location services are available - NEW METHOD
  Future<bool> isLocationServiceAvailable() async {
    try {
      await _weatherService.getCurrentLocation();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get weather recommendations for specific crops - NEW METHOD
  Future<List<String>> getCropRecommendations(String cropType) async {
    try {
      final weatherData = await getCurrentWeather();

      if (weatherData.containsKey('error')) {
        return ['Weather data unavailable for crop recommendations'];
      }

      return _generateCropSpecificAdvice(cropType, weatherData);
    } catch (e) {
      return ['Unable to generate crop recommendations at this time'];
    }
  }

  // Clear weather cache - NEW METHOD
  Future<void> clearWeatherCache() async {
    await _localStorageService.remove('weatherData');
    await _localStorageService.remove('lastWeatherUpdate');
    await _localStorageService.remove('weather_forecast');
  }

  // Helper method for error weather data
  Map<String, dynamic> _getErrorWeatherData(String error) {
    return {
      'error': error,
      'temperature': 0.0,
      'feelsLike': 0.0,
      'humidity': 0,
      'pressure': 0,
      'visibility': 0,
      'description': 'Weather data unavailable',
      'main': 'Unknown',
      'icon': '01d',
      'windSpeed': 0.0,
      'windDirection': 0,
      'cloudiness': 0,
      'timestamp': DateTime.now(),
      'city': 'Unknown Location',
      'country': '',
      'sunrise': DateTime.now(),
      'sunset': DateTime.now(),
      'isError': true,
    };
  }

  // Helper method for crop-specific advice
  List<String> _generateCropSpecificAdvice(String cropType, Map<String, dynamic> weather) {
    final temp = weather['temperature'] as double? ?? 0.0;
    final humidity = weather['humidity'] as int? ?? 0;
    final description = weather['description'] as String? ?? '';

    final List<String> advice = [];

    switch (cropType.toLowerCase()) {
      case 'tomatoes':
        if (temp > 30) {
          advice.add('Provide shade for tomato plants during hot weather');
        }
        if (humidity > 80) {
          advice.add('Watch for blight and fungal diseases in high humidity');
        }
        if (description.contains('rain')) {
          advice.add('Cover tomato plants to prevent fruit cracking');
        }
        break;

      case 'lettuce':
        if (temp > 25) {
          advice.add('Lettuce may bolt in hot weather - harvest early');
        }
        if (description.contains('sun')) {
          advice.add('Provide afternoon shade for lettuce');
        }
        break;

      case 'corn':
        if (description.contains('rain')) {
          advice.add('Good growing conditions for corn');
        }
        if (temp < 10) {
          advice.add('Wait for warmer weather before planting corn');
        }
        break;

      default:
        advice.add('Monitor weather conditions for optimal crop growth');
        if (temp > 35) {
          advice.add('Provide extra water and shade during extreme heat');
        }
        if (temp < 5) {
          advice.add('Protect crops from potential frost damage');
        }
    }

    return advice.isEmpty ? ['No specific advice available for this crop'] : advice;
  }
}