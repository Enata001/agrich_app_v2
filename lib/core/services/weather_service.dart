import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import 'location_service.dart';

class WeatherService {
  final Dio _dio = Dio();

  WeatherService() {
    _dio.options.baseUrl = AppConfig.weatherBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Add interceptor for debugging (optional)
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => print('Weather API: $obj'),
    ));
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
      return _handleDioError(e);
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
      return _handleDioErrorForForecast(e);
    } catch (e) {
      throw Exception('Failed to fetch weather forecast: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDailyForecast({
    double? lat,
    double? lon,
    String? cityName,
    int days = 5,
  }) async {
    try {
      final hourlyForecast = await getWeatherForecast(
        lat: lat,
        lon: lon,
        cityName: cityName,
        days: days,
      );

      // Group by day and get daily averages
      Map<String, List<Map<String, dynamic>>> groupedByDay = {};

      for (final forecast in hourlyForecast) {
        final date = forecast['timestamp'] as DateTime;
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        if (!groupedByDay.containsKey(dayKey)) {
          groupedByDay[dayKey] = [];
        }
        groupedByDay[dayKey]!.add(forecast);
      }

      // Calculate daily averages
      List<Map<String, dynamic>> dailyForecast = [];

      for (final entry in groupedByDay.entries) {
        final dayForecasts = entry.value;
        if (dayForecasts.isNotEmpty) {
          dailyForecast.add(_calculateDailyAverage(dayForecasts));
        }
      }

      return dailyForecast.take(days).toList();
    } catch (e) {
      return _getMockDailyForecast(days);
    }
  }

  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    return await getCurrentWeather(cityName: cityName);
  }

  // Weather alerts (requires One Call API - different endpoint)
  Future<List<Map<String, dynamic>>> getWeatherAlerts({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _dio.get('/onecall', queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': AppConfig.weatherApiKey,
        'exclude': 'minutely,hourly,daily',
      });

      if (response.statusCode == 200) {
        final alerts = response.data['alerts'] as List<dynamic>?;
        if (alerts != null) {
          return alerts.map((alert) => _formatAlertData(alert)).toList();
        }
      }
      return [];
    } catch (e) {
      return []; // Return empty list if alerts can't be fetched
    }
  }

  Map<String, dynamic> _formatWeatherData(Map<String, dynamic> data) {
    try {
      print('Formatting weather data: $data'); // Debug log

      // Safely extract nested data with null checks
      final main = data['main'] as Map<String, dynamic>? ?? {};
      final weather = data['weather'] as List<dynamic>? ?? [];
      final wind = data['wind'] as Map<String, dynamic>? ?? {};
      final clouds = data['clouds'] as Map<String, dynamic>? ?? {};
      final sys = data['sys'] as Map<String, dynamic>? ?? {};

      // Get the first weather entry safely
      final weatherInfo = weather.isNotEmpty ? weather[0] as Map<String, dynamic>? ?? {} : {};

      final formattedData = {
        'temperature': (main['temp'] as num?)?.toDouble() ?? 0.0,
        'feelsLike': (main['feels_like'] as num?)?.toDouble() ?? 0.0,
        'humidity': (main['humidity'] as num?)?.toInt() ?? 0,
        'pressure': (main['pressure'] as num?)?.toInt() ?? 0,
        'visibility': (data['visibility'] as num?)?.toInt() ?? 10000,
        'description': (weatherInfo['description'] as String?) ?? '',
        'main': (weatherInfo['main'] as String?) ?? '',
        'icon': (weatherInfo['icon'] as String?) ?? '',
        'windSpeed': (wind['speed'] as num?)?.toDouble() ?? 0.0,
        'windDirection': (wind['deg'] as num?)?.toInt() ?? 0,
        'cloudiness': (clouds['all'] as num?)?.toInt() ?? 0,
        'timestamp': data['dt'] != null
            ? DateTime.fromMillisecondsSinceEpoch((data['dt'] as int) * 1000)
            : DateTime.now(),
        'city': (data['name'] as String?) ?? '',
        'country': (sys['country'] as String?) ?? '',
        'sunrise': sys['sunrise'] != null
            ? DateTime.fromMillisecondsSinceEpoch((sys['sunrise'] as int) * 1000)
            : DateTime.now().subtract(const Duration(hours: 2)),
        'sunset': sys['sunset'] != null
            ? DateTime.fromMillisecondsSinceEpoch((sys['sunset'] as int) * 1000)
            : DateTime.now().add(const Duration(hours: 6)),
        'uvIndex': 6.0, // Default UV index as it's not in basic weather API
      };

      print('Successfully formatted weather data: $formattedData'); // Debug log
      return formattedData;

    } catch (e, stackTrace) {
      print('Error formatting weather data: $e');
      print('Stack trace: $stackTrace');
      print('Raw data causing error: $data');

      // Return default weather data if formatting fails
      return {
        'temperature': 25.0,
        'feelsLike': 27.0,
        'humidity': 65,
        'pressure': 1013,
        'visibility': 10000,
        'description': 'Unable to format weather data',
        'main': 'Unknown',
        'icon': '01d',
        'windSpeed': 5.0,
        'windDirection': 180,
        'cloudiness': 40,
        'timestamp': DateTime.now(),
        'city': 'Location',
        'country': 'GH',
        'sunrise': DateTime.now().subtract(const Duration(hours: 2)),
        'sunset': DateTime.now().add(const Duration(hours: 6)),
        'uvIndex': 6.0,
        'error': 'Data formatting error: $e',
      };
    }
  }
  Map<String, dynamic> _formatAlertData(Map<String, dynamic> alert) {
    return {
      'title': alert['event'] ?? 'Weather Alert',
      'description': alert['description'] ?? '',
      'severity': alert['severity'] ?? 'minor',
      'start': DateTime.fromMillisecondsSinceEpoch(alert['start'] * 1000),
      'end': DateTime.fromMillisecondsSinceEpoch(alert['end'] * 1000),
    };
  }

  Map<String, dynamic> _calculateDailyAverage(List<Map<String, dynamic>> hourlyData) {
    double tempSum = 0;
    double humiditySum = 0;
    double windSpeedSum = 0;
    double pressureSum = 0;
    String mostCommonCondition = '';
    String mostCommonIcon = '';

    Map<String, int> conditionCount = {};
    Map<String, int> iconCount = {};

    for (final data in hourlyData) {
      tempSum += data['temperature'] as double;
      humiditySum += data['humidity'] as int;
      windSpeedSum += data['windSpeed'] as double;
      pressureSum += data['pressure'] as int;

      final condition = data['main'] as String;
      final icon = data['icon'] as String;

      conditionCount[condition] = (conditionCount[condition] ?? 0) + 1;
      iconCount[icon] = (iconCount[icon] ?? 0) + 1;
    }

    // Find most common condition and icon
    mostCommonCondition = conditionCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    mostCommonIcon = iconCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final count = hourlyData.length;
    final firstData = hourlyData.first;

    return {
      'temperature': tempSum / count,
      'humidity': (humiditySum / count).round(),
      'windSpeed': windSpeedSum / count,
      'pressure': (pressureSum / count).round(),
      'main': mostCommonCondition,
      'icon': mostCommonIcon,
      'description': firstData['description'],
      'timestamp': firstData['timestamp'],
      'city': firstData['city'],
      'country': firstData['country'],
      'cloudiness': (hourlyData.map((d) => d['cloudiness'] as int).reduce((a, b) => a + b) / count).round(),
    };
  }

  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  String getWeatherConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '#FFD700'; // Gold
      case 'clouds':
        return '#87CEEB'; // Sky Blue
      case 'rain':
      case 'drizzle':
        return '#4682B4'; // Steel Blue
      case 'thunderstorm':
        return '#2F4F4F'; // Dark Slate Gray
      case 'snow':
        return '#F0F8FF'; // Alice Blue
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return '#D3D3D3'; // Light Gray
      default:
        return '#87CEEB'; // Sky Blue
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
    final windSpeed = weather['windSpeed'] as double;

    List<String> advice = [];

    // Temperature-based advice
    if (temperature > 35) {
      advice.add('Very hot weather - work during early morning or late evening');
    } else if (temperature < 5) {
      advice.add('Frost risk - protect sensitive crops');
    } else if (temperature >= 20 && temperature <= 30) {
      advice.add('Optimal temperature for most farming activities');
    }

    // Weather condition advice
    switch (condition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        advice.add('Good natural watering - avoid heavy machinery use');
        break;
      case 'thunderstorm':
        advice.add('Dangerous conditions - stay indoors and avoid all outdoor work');
        break;
      case 'snow':
        advice.add('Protect crops from snow damage and ensure livestock have shelter');
        break;
      case 'clear':
        advice.add('Excellent visibility for harvesting and outdoor work');
        break;
    }

    // Humidity advice
    if (humidity < 30) {
      advice.add('Low humidity - increase irrigation frequency');
    } else if (humidity > 90) {
      advice.add('High humidity - monitor for fungal diseases');
    }

    // Wind advice
    if (windSpeed > 15) {
      advice.add('Strong winds - secure equipment and avoid spraying');
    } else if (windSpeed < 3) {
      advice.add('Calm conditions - good for spraying applications');
    }

    return advice.isNotEmpty
        ? '${advice.join('. ')}.'
        : 'Moderate conditions - proceed with normal farming activities.';
  }

  List<String> getFarmingRecommendations(Map<String, dynamic> weather) {
    final temperature = weather['temperature'] as double;
    final humidity = weather['humidity'] as int;
    final condition = weather['main'] as String;
    final windSpeed = weather['windSpeed'] as double;

    List<String> recommendations = [];

    // Temperature recommendations
    if (temperature < 5) {
      recommendations.add('Use frost protection methods');
      recommendations.add('Delay sensitive plantings');
    } else if (temperature > 35) {
      recommendations.add('Provide shade for livestock');
      recommendations.add('Increase watering frequency');
    } else if (temperature >= 15 && temperature <= 25) {
      recommendations.add('Ideal for seed germination');
      recommendations.add('Good time for transplanting');
    }

    // Condition-specific recommendations
    if (condition.toLowerCase().contains('rain')) {
      recommendations.add('Collect rainwater for future use');
      recommendations.add('Check drainage systems');
    } else if (condition.toLowerCase() == 'clear') {
      recommendations.add('Excellent for harvesting');
      recommendations.add('Good drying conditions for hay');
    }

    // Humidity recommendations
    if (humidity > 80) {
      recommendations.add('Monitor for plant diseases');
      recommendations.add('Ensure good air circulation');
    } else if (humidity < 40) {
      recommendations.add('Consider mulching to retain moisture');
    }

    // Wind recommendations
    if (windSpeed > 10) {
      recommendations.add('Avoid pesticide application');
      recommendations.add('Secure loose materials');
    }

    // Seasonal recommendations
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) { // Spring
      recommendations.add('Prepare soil for planting season');
    } else if (month >= 6 && month <= 8) { // Summer
      recommendations.add('Monitor irrigation needs');
    } else if (month >= 9 && month <= 11) { // Fall
      recommendations.add('Harvest mature crops');
    } else { // Winter
      recommendations.add('Plan for next growing season');
    }

    return recommendations.take(3).toList();
  }

  // Error handling
  Map<String, dynamic> _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      return _getDefaultWeatherData('Invalid API key');
    } else if (e.response?.statusCode == 404) {
      return _getDefaultWeatherData('Location not found');
    } else {
      return _getDefaultWeatherData('Network error');
    }
  }

  List<Map<String, dynamic>> _handleDioErrorForForecast(DioException e) {
    return _getMockForecast();
  }

  // Fallback data
  Map<String, dynamic> _getDefaultWeatherData([String? error]) {
    return {
      'temperature': 25.0,
      'feelsLike': 27.0,
      'humidity': 65,
      'pressure': 1013,
      'visibility': 10000,
      'description': error ?? 'Partly cloudy',
      'main': 'Clouds',
      'icon': '02d',
      'windSpeed': 5.0,
      'windDirection': 180,
      'cloudiness': 40,
      'timestamp': DateTime.now(),
      'city': 'Accra',
      'country': 'GH',
      'sunrise': DateTime.now().subtract(const Duration(hours: 2)),
      'sunset': DateTime.now().add(const Duration(hours: 6)),
      'uvIndex': 6.0,
    };
  }

  List<Map<String, dynamic>> _getMockForecast() {
    final List<Map<String, dynamic>> forecast = [];
    final now = DateTime.now();

    for (int i = 0; i < 5; i++) {
      forecast.add({
        'temperature': 25.0 + (i * 2),
        'feelsLike': 27.0 + (i * 2),
        'humidity': 60 + (i * 5),
        'pressure': 1013,
        'visibility': 10000,
        'description': 'Partly cloudy',
        'main': 'Clouds',
        'icon': '02d',
        'windSpeed': 5.0,
        'windDirection': 180,
        'cloudiness': 40,
        'timestamp': now.add(Duration(days: i)),
        'city': 'Accra',
        'country': 'GH',
        'uvIndex': 6.0,
      });
    }

    return forecast;
  }

  List<Map<String, dynamic>> _getMockDailyForecast(int days) {
    final List<Map<String, dynamic>> forecast = [];
    final now = DateTime.now();
    final conditions = ['Clear', 'Clouds', 'Rain', 'Clouds', 'Clear'];
    final temps = [28.0, 25.0, 22.0, 26.0, 30.0];

    for (int i = 0; i < days; i++) {
      forecast.add({
        'temperature': temps[i % temps.length],
        'humidity': 60 + (i * 5),
        'windSpeed': 5.0 + i,
        'pressure': 1013,
        'main': conditions[i % conditions.length],
        'icon': '02d',
        'description': 'Partly cloudy',
        'timestamp': now.add(Duration(days: i)),
        'city': 'Accra',
        'country': 'GH',
        'cloudiness': 40,
      });
    }

    return forecast;
  }

  Future<Position> getCurrentLocation() async {
    final permissionResult = await LocationService.requestLocationPermission();

    switch (permissionResult) {
      case LocationPermissionResult.granted:
        return await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(

          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
          ),
        );
      case LocationPermissionResult.denied:
        throw Exception('Location permission denied. Please grant permission to get weather for your location.');
      case LocationPermissionResult.deniedForever:
        throw Exception('Location permission permanently denied. Please enable in settings to use location features.');
      case LocationPermissionResult.serviceDisabled:
        throw Exception('Location services are disabled. Please enable location services.');
      case LocationPermissionResult.error:
        throw Exception('Failed to get location permission.');
    }
  }
}