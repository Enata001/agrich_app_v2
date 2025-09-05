import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/weather_provider.dart';

class WeatherCard extends ConsumerStatefulWidget {
  const WeatherCard({super.key});

  @override
  ConsumerState<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends ConsumerState<WeatherCard> {
  bool _hasShownPermissionDialog = false;

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    final farmingAdviceAsync = ref.watch(farmingAdviceProvider);
    final isFarmingGood = ref.watch(isFarmingWeatherGoodProvider);

    return weatherAsync.when(
        data: (weather) {
          // Debug: Print the entire weather object to see its structure
          print('Full weather data: $weather');

          // Safe temperature extraction with proper type handling
          final temperature = _getTemperature(weather);
          print('Extracted temperature: $temperature');

          return _buildWeatherCard(context, weather, farmingAdviceAsync, isFarmingGood);
        },
        loading: () => _buildLoadingCard(),
        error: (error, stack) {
          print('Weather error: $error');
          if (error.toString().contains('permission') && !_hasShownPermissionDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _hasShownPermissionDialog = true;
              LocationService.showLocationPermissionDialog(context);
            });
          }
          return _buildErrorCard(context, error);
        }
    );
  }

  // Helper method to safely extract temperature
  double _getTemperature(Map<String, dynamic> weather) {
    final temp = weather['temperature'];
    if (temp == null) return 0.0;

    if (temp is double) return temp;
    if (temp is int) return temp.toDouble();
    if (temp is String) return double.tryParse(temp) ?? 0.0;

    return 0.0;
  }

  // Helper method to safely extract string values
  String _getString(Map<String, dynamic> weather, String key, [String defaultValue = '']) {
    final value = weather[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  // Helper method to safely extract integer values
  int _getInt(Map<String, dynamic> weather, String key, [int defaultValue = 0]) {
    final value = weather[key];
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  // Helper method to safely extract double values
  double _getDouble(Map<String, dynamic> weather, String key, [double defaultValue = 0.0]) {
    final value = weather[key];
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  Widget _buildWeatherCard(
      BuildContext context,
      Map<String, dynamic> weather,
      AsyncValue<String> farmingAdviceAsync,
      bool isFarmingGood,
      ) {

    // Safe data extraction
    final temperature = _getTemperature(weather);
    final description = _getString(weather, 'description', 'Weather data unavailable');
    final city = _getString(weather, 'city', 'Unknown Location');
    final country = _getString(weather, 'country', '');
    final humidity = _getInt(weather, 'humidity');
    final windSpeed = _getDouble(weather, 'windSpeed');
    final pressure = _getInt(weather, 'pressure');
    final icon = _getString(weather, 'icon');
    final main = _getString(weather, 'main', '');

    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with location and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${temperature.round()}°C',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (city.isNotEmpty && city != 'Unknown Location')
                      Text(
                        country.isNotEmpty ? '$city, $country' : city,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                Column(
                  children: [
                    // Weather icon
                    if (icon.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: 'https://openweathermap.org/img/wn/$icon@2x.png',
                        width: 60,
                        height: 60,
                        errorWidget: (context, url, error) => Icon(
                          _getWeatherIcon(main),
                          size: 60,
                          color: AppColors.primaryGreen,
                        ),
                      )
                    else
                      Icon(
                        _getWeatherIcon(main),
                        size: 60,
                        color: AppColors.primaryGreen,
                      ),
                    const SizedBox(height: 8),
                    // Farming status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFarmingGood ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isFarmingGood ? 'Good' : 'Caution',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weather details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  context,
                  Icons.water_drop,
                  'Humidity',
                  '$humidity%',
                ),
                _buildWeatherDetail(
                  context,
                  Icons.air,
                  'Wind',
                  '${windSpeed.toStringAsFixed(1)} m/s',
                ),
                _buildWeatherDetail(
                  context,
                  Icons.compress,
                  'Pressure',
                  '$pressure hPa',
                ),
              ],
            ),

            // Farming advice
            farmingAdviceAsync.when(
              data: (advice) => advice.isNotEmpty ? Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.agriculture,
                              color: AppColors.primaryGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Farming Advice',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          advice,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ) : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryGreen,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Weather Unavailable',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load weather data. Please check your connection.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // Refresh weather data
              ref.invalidate(currentWeatherProvider);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.wb_cloudy;
      case 'rain':
      case 'drizzle':
        return Icons.umbrella;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.cloud;
      default:
        return Icons.wb_sunny;
    }
  }
}