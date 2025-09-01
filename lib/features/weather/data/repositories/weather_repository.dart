import '../../../../core/services/weather_service.dart';
import '../../../../core/services/local_storage_service.dart';

class WeatherRepository {
  final WeatherService _weatherService;
  final LocalStorageService _localStorageService;

  WeatherRepository(this._weatherService, this._localStorageService);

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // Check if cached data is still valid
      if (!_localStorageService.isWeatherDataExpired()) {
        final cachedWeather = _localStorageService.getWeatherData();
        if (cachedWeather != null) {
          return cachedWeather;
        }
      }

      // Fetch fresh weather data
      final position = await _weatherService.getCurrentLocation();
      final weatherData = await _weatherService.getCurrentWeather(
        lat: position.latitude,
        lon: position.longitude,
      );

      // Cache the data
      await _localStorageService.setWeatherData(weatherData);
      await _localStorageService.setLastWeatherUpdate(DateTime.now());

      return weatherData;
    } catch (e) {
      // Return cached data if available, even if expired
      final cachedWeather = _localStorageService.getWeatherData();
      if (cachedWeather != null) {
        return cachedWeather;
      }

      // Return default weather data
      return _getDefaultWeatherData();
    }
  }

  Future<List<Map<String, dynamic>>> getWeatherForecast({int days = 5}) async {
    try {
      final position = await _weatherService.getCurrentLocation();
      return await _weatherService.getWeatherForecast(
        lat: position.latitude,
        lon: position.longitude,
        days: days,
      );
    } catch (e) {
      return [];
    }
  }

  Future<String> getFarmingAdvice() async {
    try {
      final weatherData = await getCurrentWeather();
      return _weatherService.getFarmingAdvice(weatherData);
    } catch (e) {
      return 'Unable to provide farming advice at the moment.';
    }
  }

  Map<String, dynamic> _getDefaultWeatherData() {
    return {
      'temperature': 25.0,
      'feelsLike': 27.0,
      'humidity': 60,
      'pressure': 1013,
      'visibility': 10000,
      'description': 'Clear sky',
      'main': 'Clear',
      'icon': '01d',
      'windSpeed': 3.5,
      'windDirection': 180,
      'cloudiness': 0,
      'timestamp': DateTime.now(),
      'city': 'Accra',
      'country': 'GH',
      'sunrise': DateTime.now().subtract(const Duration(hours: 2)),
      'sunset': DateTime.now().add(const Duration(hours: 6)),
    };
  }
}