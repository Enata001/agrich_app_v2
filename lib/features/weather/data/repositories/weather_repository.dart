import '../../../../core/services/weather_service.dart';
import '../../../../core/services/local_storage_service.dart';

class WeatherRepository {
  final WeatherService _weatherService;
  final LocalStorageService _localStorageService;

  WeatherRepository(this._weatherService, this._localStorageService);

  // Existing method with enhancements
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
        final deserializedData = _deserializeWeatherData(cachedWeather);
        deserializedData['cached'] = true;
        deserializedData['error'] = e.toString();
        return deserializedData;
      }

      // If no cached data available, return error with default structure
      return _getErrorWeatherData(e.toString());
    }
  }

  // NEW: Get weather forecast (5-day, 3-hour intervals)
  Future<List<Map<String, dynamic>>> getWeatherForecast({int days = 5}) async {
    try {
      // Try to get location-based forecast
      try {
        final position = await _weatherService.getCurrentLocation();
        return await _weatherService.getWeatherForecast(
          lat: position.latitude,
          lon: position.longitude,
          days: days,
        );
      } catch (locationError) {
        // If location fails, use default location (Accra)
        return await _weatherService.getWeatherForecast(
          cityName: 'Accra,GH',
          days: days,
        );
      }
    } catch (e) {
      print('Error getting weather forecast: $e');
      return _getMockForecast(days);
    }
  }

  // NEW: Get daily forecast (7-day)
  Future<List<Map<String, dynamic>>> getDailyForecast({int days = 7}) async {
    try {
      // Try to get location-based daily forecast
      try {
        final position = await _weatherService.getCurrentLocation();
        return await _weatherService.getDailyForecast(
          lat: position.latitude,
          lon: position.longitude,
          days: days,
        );
      } catch (locationError) {
        // If location fails, use default location (Accra)
        return await _weatherService.getDailyForecast(
          cityName: 'Accra,GH',
          days: days,
        );
      }
    } catch (e) {
      print('Error getting daily forecast: $e');
      return _getMockDailyForecast(days);
    }
  }

  // NEW: Get weather by coordinates
  Future<Map<String, dynamic>> getWeatherByCoordinates(double lat, double lon) async {
    try {
      return await _weatherService.getCurrentWeather(lat: lat, lon: lon);
    } catch (e) {
      throw Exception('Failed to get weather for coordinates: $e');
    }
  }

  // NEW: Get weather by city name
  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      return await _weatherService.getCurrentWeather(cityName: cityName);
    } catch (e) {
      throw Exception('Failed to get weather for city: $e');
    }
  }

  // NEW: Get weather alerts (requires OneCall API)
  Future<List<Map<String, dynamic>>> getWeatherAlerts() async {
    try {
      final position = await _weatherService.getCurrentLocation();
      return await _weatherService.getWeatherAlerts(
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (e) {
      print('Error getting weather alerts: $e');
      return [];
    }
  }

  // Enhanced farming advice method
  String getFarmingAdvice(Map<String, dynamic> weather) {
    return _weatherService.getFarmingAdvice(weather);
  }

  // NEW: Check if weather is suitable for farming
  bool isWeatherSuitableForFarming(Map<String, dynamic> weather) {
    final temperature = weather['temperature'] as double? ?? 0.0;
    final humidity = weather['humidity'] as int? ?? 0;
    final windSpeed = weather['windSpeed'] as double? ?? 0.0;
    final condition = weather['main'] as String? ?? '';

    // Define suitable farming conditions
    final isTemperatureGood = temperature >= 15 && temperature <= 35;
    final isHumidityGood = humidity >= 30 && humidity <= 80;
    final isWindGood = windSpeed < 20; // Less than 20 m/s
    final isConditionGood = !condition.toLowerCase().contains('thunderstorm') &&
        !condition.toLowerCase().contains('tornado') &&
        !condition.toLowerCase().contains('snow');

    return isTemperatureGood && isHumidityGood && isWindGood && isConditionGood;
  }

  // Helper methods for data serialization
  Map<String, dynamic> _serializeWeatherData(Map<String, dynamic> weatherData) {
    final serializable = Map<String, dynamic>.from(weatherData);

    // Convert DateTime objects to ISO strings for storage
    if (serializable['timestamp'] is DateTime) {
      serializable['timestamp'] = (serializable['timestamp'] as DateTime).toIso8601String();
    }
    if (serializable['sunrise'] is DateTime) {
      serializable['sunrise'] = (serializable['sunrise'] as DateTime).millisecondsSinceEpoch ~/ 1000;
    }
    if (serializable['sunset'] is DateTime) {
      serializable['sunset'] = (serializable['sunset'] as DateTime).millisecondsSinceEpoch ~/ 1000;
    }

    return serializable;
  }

  Map<String, dynamic> _deserializeWeatherData(Map<String, dynamic> weatherData) {
    final deserialized = Map<String, dynamic>.from(weatherData);

    // Convert ISO strings back to DateTime objects
    if (deserialized['timestamp'] is String) {
      try {
        deserialized['timestamp'] = DateTime.parse(deserialized['timestamp']);
      } catch (e) {
        deserialized['timestamp'] = DateTime.now();
      }
    }

    return deserialized;
  }

  Map<String, dynamic> _getErrorWeatherData(String error) {
    return {
      'temperature': 25.0,
      'feelsLike': 27.0,
      'humidity': 60,
      'pressure': 1013,
      'windSpeed': 3.0,
      'windDeg': 180,
      'visibility': 10,
      'clouds': 25,
      'main': 'Clear',
      'description': 'clear sky',
      'icon': '01d',
      'name': 'Accra',
      'country': 'GH',
      'sunrise': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000,
      'sunset': DateTime.now().add(const Duration(hours: 6)).millisecondsSinceEpoch ~/ 1000,
      'timestamp': DateTime.now(),
      'error': true,
      'errorMessage': error,
    };
  }

  List<Map<String, dynamic>> _getMockForecast(int days) {
    final forecast = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < days * 8; i++) { // 8 forecasts per day (every 3 hours)
      final dateTime = now.add(Duration(hours: i * 3));
      forecast.add({
        'temperature': 25.0 + (i % 10) - 5, // Varying temperature
        'feelsLike': 27.0 + (i % 10) - 5,
        'humidity': 60 + (i % 20) - 10,
        'pressure': 1013 + (i % 20) - 10,
        'windSpeed': 3.0 + (i % 5),
        'main': i % 3 == 0 ? 'Clouds' : 'Clear',
        'description': i % 3 == 0 ? 'scattered clouds' : 'clear sky',
        'icon': i % 3 == 0 ? '03d' : '01d',
        'timestamp': dateTime,
      });
    }

    return forecast;
  }

  List<Map<String, dynamic>> _getMockDailyForecast(int days) {
    final forecast = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final dateTime = now.add(Duration(days: i));
      forecast.add({
        'maxTemp': 30.0 + (i % 8) - 4,
        'minTemp': 20.0 + (i % 6) - 3,
        'temperature': 25.0 + (i % 7) - 3,
        'humidity': 65 + (i % 15) - 7,
        'pressure': 1013 + (i % 10) - 5,
        'windSpeed': 4.0 + (i % 4),
        'main': i % 4 == 0 ? 'Rain' : (i % 3 == 0 ? 'Clouds' : 'Clear'),
        'description': i % 4 == 0 ? 'light rain' : (i % 3 == 0 ? 'partly cloudy' : 'clear sky'),
        'icon': i % 4 == 0 ? '10d' : (i % 3 == 0 ? '02d' : '01d'),
        'timestamp': dateTime,
      });
    }

    return forecast;
  }
}