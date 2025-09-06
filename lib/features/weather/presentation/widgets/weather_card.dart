import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

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

        return _buildWeatherCard(
          context,
          weather,
          farmingAdviceAsync,
          isFarmingGood,
        );
      },
      loading: () => _buildLoadingCard(),
      error: (error, stack) {
        print('Weather error: $error');
        if (error.toString().contains('permission') &&
            !_hasShownPermissionDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _hasShownPermissionDialog = true;
            LocationService.showLocationPermissionDialog(context);
          });
        }
        return _buildErrorCard(context, error);
      },
    );
  }

  Widget _buildWeatherCard(
    BuildContext context,
    Map<String, dynamic> weather,
    AsyncValue<String> farmingAdviceAsync,
    AsyncValue<bool> isFarmingGood,
  ) {
    final temperature = _getTemperature(weather);
    final location = _getString(weather, 'name', 'Current Location');
    final description = _getString(weather, 'description');
    final humidity = _getInt(weather, 'humidity');
    final windSpeed = weather['windSpeed'] ?? 0.0;
    final pressure = _getInt(weather, 'pressure');
    final iconCode = _getString(weather, 'icon', '01d');

    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: GestureDetector(
        onTap: () => _navigateToWeatherDetails(context),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen.withValues(alpha: 0.6),
                Colors.grey.withValues(alpha: 0.2),
                Colors.black26.withValues(alpha: 0.1),
                AppColors.primaryGreen.withValues(alpha: 0.2),
                AppColors.primaryGreen.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.borderDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),



              // Main content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location and weather icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${temperature.toInt()}°C',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 48,
                                      height: 1.0,
                                    ),
                              ),
                              Text(
                                description.isNotEmpty
                                    ? description[0].toUpperCase() +
                                          description.substring(1)
                                    : 'Clear Sky',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.network(
                            'https://openweathermap.org/img/wn/$iconCode@2x.png',
                            width: 80,
                            height: 80,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.wb_sunny,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Weather details row
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
                          Icons.speed,
                          'Pressure',
                          '$pressure hPa',
                        ),
                      ],
                    ),

                    // Farming advice section
                    farmingAdviceAsync.when(
                      data: (advice) => advice.isNotEmpty
                          ? Column(
                              children: [
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: isFarmingGood.when(
                                                data: (isGood) => isGood
                                                    ? AppColors.success
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )
                                                    : AppColors.warning
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                loading: () => Colors.white
                                                    .withValues(alpha: 0.2),
                                                error: (_, _) => Colors.white
                                                    .withValues(alpha: 0.2),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.agriculture,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Farming Advice',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        advice,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen.withValues(alpha: 0.6),
              AppColors.primaryGreen.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Getting weather data...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.error.withValues(alpha: 0.7),
              AppColors.error.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Weather data unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to retry',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
  String _getString(
    Map<String, dynamic> weather,
    String key, [
    String defaultValue = '',
  ]) {
    final value = weather[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  // Helper method to safely extract integer values
  int _getInt(
    Map<String, dynamic> weather,
    String key, [
    int defaultValue = 0,
  ]) {
    final value = weather[key];
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  // Navigation method
  void _navigateToWeatherDetails(BuildContext context) {
    context.push('/weather-details');
  }
}
