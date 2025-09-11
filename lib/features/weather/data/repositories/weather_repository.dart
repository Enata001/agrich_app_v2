import '../../../../core/services/network_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/services/local_storage_service.dart';

class WeatherRepository {
  final WeatherService _weatherService;
  final LocalStorageService _localStorageService;
  final NetworkService _networkService;

  WeatherRepository(
    this._weatherService,
    this._localStorageService,
    this._networkService,
  );

  Future<Map<String, dynamic>> getCurrentWeatherWithFallback() async {
    print('🌤️ Starting weather fetch process...');

    try {
      if (!await _networkService.checkConnectivity()) {
        print('📱 Device is offline, checking cache...');
        final cachedWeather = _localStorageService.getWeatherData();
        if (cachedWeather != null && !_isWeatherDataExpired()) {
          print('✅ Using cached weather data');
          return _deserializeWeatherData(cachedWeather);
        } else {
          print('❌ No valid cached weather data, using default');
          return _weatherService.getDefaultWeatherData();
        }
      }

      if (!_isWeatherDataExpired()) {
        final cachedWeather = _localStorageService.getWeatherData();
        if (cachedWeather != null) {
          print('✅ Using valid cached weather data');
          return _deserializeWeatherData(cachedWeather);
        }
      }

      print('🔄 Fetching fresh weather data...');

      try {
        print('📍 Getting current location...');
        final position = await _weatherService.getCurrentLocation();
        print(
          '📍 Location obtained: ${position.latitude}, ${position.longitude}',
        );

        final weatherData = await _weatherService.getCurrentWeather(
          lat: position.latitude,
          lon: position.longitude,
        );

        print('✅ Weather data fetched successfully with location');
        await _cacheWeatherData(weatherData);
        return weatherData;
      } catch (locationError) {
        print('❌ Location failed: $locationError');
        print('🏙️ Falling back to default location (Accra)...');

        try {
          final weatherData = await _weatherService.getCurrentWeather(
            cityName: 'Accra,GH',
          );

          print('✅ Weather data fetched successfully for Accra');
          await _cacheWeatherData(weatherData);
          return weatherData;
        } catch (accraError) {
          print('❌ Accra weather failed: $accraError');

          try {
            final weatherData = await _weatherService.getCurrentWeather(
              lat: 5.6037,
              lon: -0.1870,
            );

            print('✅ Weather data fetched successfully for Accra coordinates');
            await _cacheWeatherData(weatherData);
            return weatherData;
          } catch (coordinatesError) {
            print('❌ All weather fetch attempts failed: $coordinatesError');

            final cachedWeather = _localStorageService.getWeatherData();
            if (cachedWeather != null) {
              print('⚠️ Using expired cached weather data');
              final data = _deserializeWeatherData(cachedWeather);
              data['isExpired'] = true;
              return data;
            }

            print('📋 Using default weather data as final fallback');
            return _weatherService.getDefaultWeatherData();
          }
        }
      }
    } catch (e) {
      print('❌ Unexpected error in weather fetch: $e');

      final cachedWeather = _localStorageService.getWeatherData();
      if (cachedWeather != null) {
        print('⚠️ Using cached weather data due to error');
        final data = _deserializeWeatherData(cachedWeather);
        data['hasError'] = true;
        return data;
      }

      print('📋 Using default weather data due to error');
      return _weatherService.getDefaultWeatherData();
    }
  }

  Future<void> _cacheWeatherData(Map<String, dynamic> weatherData) async {
    try {
      final serializableData = _serializeWeatherData(weatherData);
      await _localStorageService.setWeatherData(serializableData);
      await _localStorageService.setLastWeatherUpdate(DateTime.now());
      print('💾 Weather data cached successfully');
    } catch (e) {
      print('❌ Failed to cache weather data: $e');
    }
  }

  bool _isWeatherDataExpired() {
    final lastUpdate = _localStorageService.getLastWeatherUpdate();
    if (lastUpdate == null) {
      print('📅 No last update time, data considered expired');
      return true;
    }

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    final isExpired = difference.inMinutes > 30;

    print('📅 Last update: $lastUpdate, Now: $now, Expired: $isExpired');
    return isExpired;
  }

  Map<String, dynamic> _serializeWeatherData(Map<String, dynamic> weather) {
    return {
      'temperature': weather['temperature'],
      'feelsLike': weather['feelsLike'],
      'humidity': weather['humidity'],
      'pressure': weather['pressure'],
      'visibility': weather['visibility'],
      'description': weather['description'],
      'main': weather['main'],
      'icon': weather['icon'],
      'windSpeed': weather['windSpeed'],
      'windDirection': weather['windDirection'],
      'cloudiness': weather['cloudiness'],
      'city': weather['city'],
      'country': weather['country'],
      'timestamp': weather['timestamp']?.toIso8601String(),
      'sunrise': weather['sunrise']?.toIso8601String(),
      'sunset': weather['sunset']?.toIso8601String(),
    };
  }

  Map<String, dynamic> _deserializeWeatherData(Map<String, dynamic> data) {
    return {
      'temperature': data['temperature'] ?? 0.0,
      'feelsLike': data['feelsLike'] ?? 0.0,
      'humidity': data['humidity'] ?? 0,
      'pressure': data['pressure'] ?? 1013,
      'visibility': data['visibility'] ?? 10000,
      'description': data['description'] ?? '',
      'main': data['main'] ?? 'Unknown',
      'icon': data['icon'] ?? '01d',
      'windSpeed': data['windSpeed'] ?? 0.0,
      'windDirection': data['windDirection'] ?? 0,
      'cloudiness': data['cloudiness'] ?? 0,
      'city': data['city'] ?? '',
      'country': data['country'] ?? '',
      'timestamp': data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      'sunrise': data['sunrise'] != null
          ? DateTime.parse(data['sunrise'])
          : null,
      'sunset': data['sunset'] != null ? DateTime.parse(data['sunset']) : null,
      'isCached': true,
    };
  }

  Future<List<Map<String, dynamic>>> getDailyForecast({int days = 7}) async {
    try {
      try {
        final position = await _weatherService.getCurrentLocation();
        return await _weatherService.getDailyForecast(
          lat: position.latitude,
          lon: position.longitude,
          days: days,
        );
      } catch (locationError) {
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

  Future<Map<String, dynamic>> getWeatherByCoordinates(
    double lat,
    double lon,
  ) async {
    try {
      return await _weatherService.getCurrentWeather(lat: lat, lon: lon);
    } catch (e) {
      throw Exception('Failed to get weather for coordinates: $e');
    }
  }

  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      return await _weatherService.getCurrentWeather(cityName: cityName);
    } catch (e) {
      throw Exception('Failed to get weather for city: $e');
    }
  }

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

  Future<List<Map<String, dynamic>>> getWeatherForecast({int days = 5}) async {
    if (!await _networkService.checkConnectivity()) {
      return _getMockDailyForecast(days);
    }

    try {
      final position = await _weatherService.getCurrentLocation();
      return await _weatherService.getWeatherForecast(
        lat: position.latitude,
        lon: position.longitude,
        days: days,
      );
    } catch (locationError) {
      try {
        return await _weatherService.getWeatherForecast(
          cityName: 'Accra,GH',
          days: days,
        );
      } catch (e) {
        print('Error getting weather forecast: $e');
        return _getMockDailyForecast(days);
      }
    }
  }

  String getFarmingAdvice(Map<String, dynamic> weather) {
    return _weatherService.getFarmingAdvice(weather);
  }

  bool isWeatherSuitableForFarming(Map<String, dynamic> weather) {
    final temperature = weather['temperature'] as double? ?? 0.0;
    final humidity = weather['humidity'] as int? ?? 0;
    final windSpeed = weather['windSpeed'] as double? ?? 0.0;
    final condition = weather['main'] as String? ?? '';

    final isTemperatureGood = temperature >= 15 && temperature <= 35;
    final isHumidityGood = humidity >= 30 && humidity <= 80;
    final isWindGood = windSpeed < 20;
    final isConditionGood =
        !condition.toLowerCase().contains('thunderstorm') &&
        !condition.toLowerCase().contains('tornado') &&
        !condition.toLowerCase().contains('snow');

    return isTemperatureGood && isHumidityGood && isWindGood && isConditionGood;
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
        'description': i % 4 == 0
            ? 'light rain'
            : (i % 3 == 0 ? 'partly cloudy' : 'clear sky'),
        'icon': i % 4 == 0 ? '10d' : (i % 3 == 0 ? '02d' : '01d'),
        'timestamp': dateTime,
      });
    }

    return forecast;
  }
}
