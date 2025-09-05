import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/weather_service.dart';

class WeatherRepository {
  final WeatherService _weatherService;
  final LocalStorageService _localStorageService;

  WeatherRepository(this._weatherService, this._localStorageService);

  // Get current weather - FIXED with proper DateTime handling
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // Check if cached data is still valid (within 30 minutes)
      if (!_localStorageService.isWeatherDataExpired()) {
        final cachedWeather = _localStorageService.getWeatherData();
        if (cachedWeather != null) {
          // Convert DateTime strings back to DateTime objects
          return _deserializeWeatherData(cachedWeather);
        }
      }

      // Fetch fresh weather data using GPS location
      final position = await _weatherService.getCurrentLocation();
      final weatherData = await _weatherService.getCurrentWeather(
        lat: position.latitude,
        lon: position.longitude,
      );

      print('Fresh weather data before caching: $weatherData');

      // Serialize DateTime objects for storage, then cache
      final serializableData = _serializeWeatherData(weatherData);
      await _localStorageService.setWeatherData(serializableData);
      await _localStorageService.setLastWeatherUpdate(DateTime.now());

      print('Successfully cached weather data');
      return weatherData; // Return original data with DateTime objects
    } catch (e) {
      print('Error in getCurrentWeather: $e');

      // Try to return cached data even if expired
      final cachedWeather = _localStorageService.getWeatherData();
      if (cachedWeather != null) {
        // Add an indicator that data might be stale
        final deserializedData = _deserializeWeatherData(cachedWeather);
        deserializedData['isStale'] = true;
        deserializedData['error'] = e.toString();
        return deserializedData;
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
          return _deserializeWeatherData(cachedWeather);
        }
      }

      // Try to get location-based weather
      try {
        final position = await _weatherService.getCurrentLocation();
        final weatherData = await _weatherService.getCurrentWeather(
          lat: position.latitude,
          lon: position.longitude,
        );

        // Serialize for storage
        final serializableData = _serializeWeatherData(weatherData);
        await _localStorageService.setWeatherData(serializableData);
        await _localStorageService.setLastWeatherUpdate(DateTime.now());

        return weatherData;
      } catch (locationError) {
        // If location fails, try to get weather for Accra (default location)
        print('Location failed, using default location: $locationError');

        final weatherData = await _weatherService.getCurrentWeather(
          cityName: 'Accra,GH',
        );

        // Serialize for storage
        final serializableData = _serializeWeatherData(weatherData);
        await _localStorageService.setWeatherData(serializableData);
        await _localStorageService.setLastWeatherUpdate(DateTime.now());

        return weatherData;
      }
    } catch (e) {
      print('Error in getCurrentWeatherWithFallback: $e');

      // Return cached data if available, even if expired
      final cachedWeather = _localStorageService.getWeatherData();
      if (cachedWeather != null) {
        return _deserializeWeatherData(cachedWeather);
      }

      // Return default weather data as last resort
      return _getErrorWeatherData(e.toString());
    }
  }

  // NEW: Serialize weather data for storage (convert DateTime to ISO strings)
  Map<String, dynamic> _serializeWeatherData(Map<String, dynamic> weatherData) {
    final serializable = Map<String, dynamic>.from(weatherData);

    // Convert DateTime objects to ISO strings
    if (serializable['timestamp'] is DateTime) {
      serializable['timestamp'] = (serializable['timestamp'] as DateTime).toIso8601String();
    }
    if (serializable['sunrise'] is DateTime) {
      serializable['sunrise'] = (serializable['sunrise'] as DateTime).toIso8601String();
    }
    if (serializable['sunset'] is DateTime) {
      serializable['sunset'] = (serializable['sunset'] as DateTime).toIso8601String();
    }

    return serializable;
  }

  // NEW: Deserialize weather data from storage (convert ISO strings back to DateTime)
  Map<String, dynamic> _deserializeWeatherData(Map<String, dynamic> cachedData) {
    final deserialized = Map<String, dynamic>.from(cachedData);

    // Convert ISO strings back to DateTime objects
    if (deserialized['timestamp'] is String) {
      try {
        deserialized['timestamp'] = DateTime.parse(deserialized['timestamp']);
      } catch (e) {
        deserialized['timestamp'] = DateTime.now();
      }
    }
    if (deserialized['sunrise'] is String) {
      try {
        deserialized['sunrise'] = DateTime.parse(deserialized['sunrise']);
      } catch (e) {
        deserialized['sunrise'] = DateTime.now();
      }
    }
    if (deserialized['sunset'] is String) {
      try {
        deserialized['sunset'] = DateTime.parse(deserialized['sunset']);
      } catch (e) {
        deserialized['sunset'] = DateTime.now();
      }
    }

    return deserialized;
  }

  Future<List<Map<String, dynamic>>> getWeatherForecast({int days = 5}) async {
    try {
      final position = await _weatherService.getCurrentLocation();
      final forecast = await _weatherService.getWeatherForecast(
        lat: position.latitude,
        lon: position.longitude,
        days: days,
      );

      // Serialize forecast data for storage
      final serializableForecast = forecast.map((dailyWeather) =>
          _serializeWeatherData(dailyWeather)
      ).toList();

      await _localStorageService.setString(
        'weather_forecast',
        jsonEncode(serializableForecast),
      );

      return forecast;
    } catch (e) {
      print('Error in getWeatherForecast: $e');

      final cachedForecast = _localStorageService.getString('weather_forecast');
      if (cachedForecast != null) {
        try {
          final decoded = jsonDecode(cachedForecast) as List;
          // Deserialize each forecast item
          return decoded.map<Map<String, dynamic>>((item) =>
              _deserializeWeatherData(item as Map<String, dynamic>)
          ).toList();
        } catch (parseError) {
          print('Failed to parse cached forecast: $parseError');
        }
      }

      return []; // Return empty only as last resort
    }
  }

  // Get weather by city name - Fixed
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

  // Get farming advice based on weather - Fixed
  Future<String> getFarmingAdvice() async {
    try {
      final weatherData = await getCurrentWeather();

      if (weatherData.containsKey('error') || weatherData['isError'] == true) {
        return 'Unable to provide farming advice due to weather data unavailability.';
      }

      return _weatherService.getFarmingAdvice(weatherData);
    } catch (e) {
      return 'Unable to provide farming advice at the moment. Please try again later.';
    }
  }

  // Get weather alerts
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

  // Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    try {
      await _weatherService.getCurrentLocation();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get weather recommendations for specific crops
  Future<List<String>> getCropRecommendations(String cropType) async {
    try {
      final weatherData = await getCurrentWeather();

      if (weatherData.containsKey('error') || weatherData['isError'] == true) {
        return ['Weather data unavailable for crop recommendations'];
      }

      return _generateCropSpecificAdvice(cropType, weatherData);
    } catch (e) {
      return ['Unable to generate crop recommendations at this time'];
    }
  }

  // Clear weather cache
  Future<void> clearWeatherCache() async {
    await _localStorageService.remove('weatherData');
    await _localStorageService.remove('lastWeatherUpdate');
    await _localStorageService.remove('weather_forecast');
  }

  // Helper method for error weather data - FIXED with proper DateTime objects
  Map<String, dynamic> _getErrorWeatherData(String error) {
    final now = DateTime.now();
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
      'timestamp': now, // DateTime object, not string
      'city': 'Unknown Location',
      'country': '',
      'sunrise': now, // DateTime object, not string
      'sunset': now, // DateTime object, not string
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