import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';

class WeatherService {
  final Dio _dio = Dio();

  WeatherService() {
    _dio.options.baseUrl = AppConfig.weatherBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> getCurrentWeather({
    double? lat,
    double? lon,
    String? cityName,
  }) async {
    try {
      Map<String, dynamic> queryParameters = {
        'appid': AppConfig.weatherApiKey,
        'units': 'metric',
      };

      if (lat != null && lon != null) {
        queryParameters['lat'] = lat;
        queryParameters['lon'] = lon;
      } else if (cityName != null) {
        queryParameters['q'] = cityName;
      } else {
        throw Exception('Either coordinates or city name must be provided');
      }

      final response = await _dio.get('/weather', queryParameters: queryParameters);

      if (response.statusCode == 200) {
        return _formatWeatherData(response.data);
      } else {
        throw Exception('Failed to fetch weather data');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Location not found');
      } else {
        throw Exception('Failed to fetch weather data: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weather data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWeatherForecast({
    double? lat,
    double? lon,
    String? cityName,
    int days = 5,
  }) async {
    try {
      Map<String, dynamic> queryParameters = {
        'appid': AppConfig.weatherApiKey,
        'units': 'metric',
        'cnt': days * 8, // 8 forecasts per day (every 3 hours)
      };

      if (lat != null && lon != null) {
        queryParameters['lat'] = lat;
        queryParameters['lon'] = lon;
      } else if (cityName != null) {
        queryParameters['q'] = cityName;
      } else {
        throw Exception('Either coordinates or city name must be provided');
      }

      final response = await _dio.get('/forecast', queryParameters: queryParameters);

      if (response.statusCode == 200) {
        final List<dynamic> forecasts = response.data['list'];
        return forecasts.map((forecast) => _formatWeatherData(forecast)).toList();
      } else {
        throw Exception('Failed to fetch weather forecast');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Location not found');
      } else {
        throw Exception('Failed to fetch weather forecast: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weather forecast: $e');
    }
  }

  Map<String, dynamic> _formatWeatherData(Map<String, dynamic> data) {
    return {
      'temperature': data['main']['temp']?.toDouble() ?? 0.0,
      'feelsLike': data['main']['feels_like']?.toDouble() ?? 0.0,
      'humidity': data['main']['humidity']?.toInt() ?? 0,
      'pressure': data['main']['pressure']?.toInt() ?? 0,
      'visibility': data['visibility']?.toInt() ?? 0,
      'description': data['weather'][0]['description'] ?? '',
      'main': data['weather'][0]['main'] ?? '',
      'icon': data['weather'][0]['icon'] ?? '',
      'windSpeed': data['wind']?['speed']?.toDouble() ?? 0.0,
      'windDirection': data['wind']?['deg']?.toInt() ?? 0,
      'cloudiness': data['clouds']?['all']?.toInt() ?? 0,
      'timestamp': data['dt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dt'] * 1000)
          : DateTime.now(),
      'city': data['name'] ?? '',
      'country': data['sys']?['country'] ?? '',
      'sunrise': data['sys']?['sunrise'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000)
          : null,
      'sunset': data['sys']?['sunset'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000)
          : null,
    };
  }

  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  String getWeatherConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'sunny';
      case 'clouds':
        return 'cloudy';
      case 'rain':
      case 'drizzle':
        return 'rainy';
      case 'thunderstorm':
        return 'stormy';
      case 'snow':
        return 'snowy';
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return 'misty';
      default:
        return 'cloudy';
    }
  }

  bool isFarmingWeatherGood(Map<String, dynamic> weather) {
    final temperature = weather['temperature'] as double;
    final humidity = weather['humidity'] as int;
    final windSpeed = weather['windSpeed'] as double;
    final condition = weather['main'] as String;

    // Ideal farming conditions
    bool temperatureOk = temperature >= 15 && temperature <= 35;
    bool humidityOk = humidity >= 40 && humidity <= 80;
    bool windOk = windSpeed < 10; // Less than 10 m/s
    bool conditionOk = !['Thunderstorm', 'Snow'].contains(condition);

    return temperatureOk && humidityOk && windOk && conditionOk;
  }

  String getFarmingAdvice(Map<String, dynamic> weather) {
    final temperature = weather['temperature'] as double;
    final humidity = weather['humidity'] as int;
    final condition = weather['main'] as String;

    if (condition == 'Rain') {
      return 'Good time for natural watering. Avoid heavy machinery use.';
    } else if (condition == 'Thunderstorm') {
      return 'Stay indoors. Avoid all outdoor farming activities.';
    } else if (temperature > 35) {
      return 'Very hot. Best to work early morning or late evening.';
    } else if (temperature < 10) {
      return 'Cold weather. Protect sensitive crops from frost.';
    } else if (humidity < 30) {
      return 'Low humidity. Consider irrigation for crops.';
    } else if (humidity > 90) {
      return 'High humidity. Watch for fungal diseases in crops.';
    } else if (isFarmingWeatherGood(weather)) {
      return 'Excellent conditions for farming activities!';
    } else {
      return 'Moderate conditions. Proceed with caution.';
    }
  }
}