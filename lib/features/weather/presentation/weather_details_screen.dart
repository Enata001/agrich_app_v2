import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'providers/weather_provider.dart';

class WeatherDetailsScreen extends ConsumerStatefulWidget {
  const WeatherDetailsScreen({super.key});

  @override
  ConsumerState<WeatherDetailsScreen> createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends ConsumerState<WeatherDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWeather = ref.watch(currentWeatherProvider);
    final forecast = ref.watch(weatherForecastProvider);
    final dailyForecast = ref.watch(dailyWeatherForecastProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: currentWeather.when(
          data: (weather) => _buildWeatherDetails(
            context,
            weather,
            forecast,
            dailyForecast,
          ),
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: const Text(
        'Weather Details',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _refreshWeather(),
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildWeatherDetails(
      BuildContext context,
      Map<String, dynamic> currentWeather,
      AsyncValue<List<Map<String, dynamic>>> forecast,
      AsyncValue<List<Map<String, dynamic>>> dailyForecast,
      ) {
    return Column(
      children: [
        // Current Weather Header
        _buildCurrentWeatherHeader(context, currentWeather),

        // Tab Bar
        _buildTabBar(),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,

            children: [
              _buildTodayTab(currentWeather),
              _buildWeeklyTab(dailyForecast),
              _buildDetailsTab(currentWeather),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWeatherHeader(BuildContext context, Map<String, dynamic> weather) {
    final temperature = _getTemperature(weather);
    final location = weather['name'] ?? 'Current Location';
    final description = weather['description'] ?? '';
    final iconCode = weather['icon'] ?? '01d';

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              location,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/$iconCode@2x.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.wb_sunny,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${temperature.toInt()}°C',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 64,
                      ),
                    ),
                    Text(
                      description.isNotEmpty ?
                      description[0].toUpperCase() + description.substring(1) :
                      'Clear Sky',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Feels like ${_getTemperature(weather, 'feelsLike').toInt()}°C',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: AppColors.primaryGreen,
        indicatorSize: TabBarIndicatorSize.tab,
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Weekly'),
          Tab(text: 'Details'),
        ],
      ),
    );
  }

  Widget _buildTodayTab(Map<String, dynamic> weather) {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Hourly Forecast'),
            const SizedBox(height: 16),
            _buildHourlyForecast(),
            const SizedBox(height: 32),
            _buildSectionTitle('Weather Highlights'),
            const SizedBox(height: 16),
            _buildWeatherHighlights(weather),
            const SizedBox(height: 32),
            _buildSectionTitle('Farming Recommendations'),
            const SizedBox(height: 16),
            _buildFarmingRecommendations(weather),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTab(AsyncValue<List<Map<String, dynamic>>> dailyForecast) {
    return dailyForecast.when(
      data: (forecast) => FadeIn(
        duration: const Duration(milliseconds: 600),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: forecast.length,
          itemBuilder: (context, index) {
            final day = forecast[index];
            return _buildDailyForecastCard(day, index == 0);
          },
        ),
      ),
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorMessage('Failed to load weekly forecast'),
    );
  }

  Widget _buildDetailsTab(Map<String, dynamic> weather) {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailGrid(weather),
            const SizedBox(height: 32),
            _buildSunMoonTimes(weather),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 24, // 24 hours
        itemBuilder: (context, index) {
          return _buildHourlyItem(index);
        },
      ),
    );
  }

  Widget _buildHourlyItem(int hourOffset) {
    final time = DateTime.now().add(Duration(hours: hourOffset));
    final isNow = hourOffset == 0;

    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNow
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: isNow
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNow ? 'Now' : DateFormat('HH:mm').format(time),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(
            _getWeatherIcon(time.hour),
            color: Colors.white,
            size: 24,
          ),
          Text(
            '${(25 + (time.hour % 8) - 3)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherHighlights(Map<String, dynamic> weather) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildHighlightCard(
          'UV Index',
          '${weather['uvi'] ?? 5}',
          Icons.wb_sunny,
          _getUVDescription(weather['uvi'] ?? 5),
        ),
        _buildHighlightCard(
          'Wind Speed',
          '${weather['windSpeed'] ?? 0} m/s',
          Icons.air,
          _getWindDescription(weather['windSpeed'] ?? 0),
        ),
        _buildHighlightCard(
          'Humidity',
          '${weather['humidity'] ?? 0}%',
          Icons.water_drop,
          _getHumidityDescription(weather['humidity'] ?? 0),
        ),
        _buildHighlightCard(
          'Pressure',
          '${weather['pressure'] ?? 0} hPa',
          Icons.speed,
          _getPressureDescription(weather['pressure'] ?? 0),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(String title, String value, IconData icon, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingRecommendations(Map<String, dynamic> weather) {
    final recommendations = _generateFarmingRecommendations(weather);

    return Column(
      children: recommendations.map((recommendation) =>
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.agriculture,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ).toList(),
    );
  }

  Widget _buildDailyForecastCard(Map<String, dynamic> day, bool isToday) {
    final date = day['timestamp'] as DateTime? ?? DateTime.now();
    final maxTemp = _getTemperature(day, 'maxTemp');
    final minTemp = _getTemperature(day, 'minTemp');
    final description = day['description'] ?? '';
    final iconCode = day['icon'] ?? '01d';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? 'Today' : DateFormat('EEEE').format(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('MMM d').format(date),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Image.network(
            'https://openweathermap.org/img/wn/$iconCode.png',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.wb_sunny,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    '${maxTemp.toInt()}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${minTemp.toInt()}°',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(Map<String, dynamic> weather) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildDetailCard('Visibility', '${weather['visibility'] ?? 10} km', Icons.visibility),
        _buildDetailCard('Dew Point', '${weather['dewPoint'] ?? 15}°C', Icons.water),
        _buildDetailCard('Cloud Cover', '${weather['clouds'] ?? 0}%', Icons.cloud),
        _buildDetailCard('Wind Direction', '${weather['windDeg'] ?? 0}°', Icons.navigation),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunMoonTimes(Map<String, dynamic> weather) {
    final sunrise = DateTime.fromMillisecondsSinceEpoch((weather['sunrise'] ?? 0) * 1000);
    final sunset = DateTime.fromMillisecondsSinceEpoch((weather['sunset'] ?? 0) * 1000);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Sun & Moon',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSunMoonItem(
                'Sunrise',
                DateFormat('HH:mm').format(sunrise),
                Icons.wb_sunny,
              ),
              _buildSunMoonItem(
                'Sunset',
                DateFormat('HH:mm').format(sunset),
                Icons.wb_sunny_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunMoonItem(String title, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load weather details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _refreshWeather(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Helper Methods
  double _getTemperature(Map<String, dynamic> weather, [String key = 'temperature']) {
    final temp = weather[key];
    if (temp == null) return 0.0;
    if (temp is double) return temp;
    if (temp is int) return temp.toDouble();
    if (temp is String) return double.tryParse(temp) ?? 0.0;
    return 0.0;
  }

  IconData _getWeatherIcon(int hour) {
    if (hour >= 6 && hour < 18) {
      return Icons.wb_sunny;
    } else {
      return Icons.nights_stay;
    }
  }

  String _getUVDescription(int uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }

  String _getWindDescription(double windSpeed) {
    if (windSpeed < 2) return 'Calm';
    if (windSpeed < 6) return 'Light';
    if (windSpeed < 12) return 'Moderate';
    if (windSpeed < 20) return 'Strong';
    return 'Very Strong';
  }

  String _getHumidityDescription(int humidity) {
    if (humidity < 30) return 'Dry';
    if (humidity < 60) return 'Comfortable';
    if (humidity < 80) return 'Humid';
    return 'Very Humid';
  }

  String _getPressureDescription(int pressure) {
    if (pressure < 1013) return 'Low';
    if (pressure < 1023) return 'Normal';
    return 'High';
  }

  List<String> _generateFarmingRecommendations(Map<String, dynamic> weather) {
    final temp = _getTemperature(weather);
    final humidity = weather['humidity'] ?? 0;
    final windSpeed = weather['windSpeed'] ?? 0;

    List<String> recommendations = [];

    if (temp < 10) {
      recommendations.add('Protect crops from frost damage');
    } else if (temp > 30) {
      recommendations.add('Ensure adequate irrigation for crops');
    } else {
      recommendations.add('Good conditions for outdoor farming activities');
    }

    if (humidity > 80) {
      recommendations.add('Monitor crops for fungal diseases');
    } else if (humidity < 40) {
      recommendations.add('Consider additional watering');
    }

    if (windSpeed > 15) {
      recommendations.add('Avoid spraying pesticides or fertilizers');
    }

    return recommendations.take(3).toList();
  }

  void _refreshWeather() {
    ref.invalidate(currentWeatherProvider);
    ref.invalidate(weatherForecastProvider);
    ref.invalidate(dailyWeatherForecastProvider);
  }
}