import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/weather_provider.dart';

class WeatherCard extends ConsumerStatefulWidget {
  const WeatherCard({super.key});

  @override
  ConsumerState<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends ConsumerState<WeatherCard> {
  bool _hasShownPermissionDialog = false;
  bool _isRequestingLocation = false;

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    final farmingAdviceAsync = ref.watch(farmingAdviceProvider);
    final isFarmingGood = ref.watch(isFarmingWeatherGoodProvider);
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (isOnline) => weatherAsync.when(
        data: (weather) => _buildWeatherCard(
          context,
          weather,
          farmingAdviceAsync,
          isFarmingGood,
          isOnline,
        ),
        loading: () => _buildLoadingCard(),
        error: (error, stack) {
          print('Weather error: $error');
          return _handleWeatherError(context, error, isOnline);
        },
      ),
      error: (error, stackTrace) => _buildErrorCard(context, error),
      loading: () => _buildLoadingCard(),
    );
  }

  Widget _buildWeatherCard(
      BuildContext context,
      Map<String, dynamic> weather,
      AsyncValue<String> farmingAdviceAsync,
      AsyncValue<bool> isFarmingGood,
      bool isOnline,
      ) {
    final temperature = _getTemperature(weather);
    final location = _getString(weather, 'city', 'Unknown Location');
    final description = _getString(weather, 'description', 'No description');
    final humidity = _getInt(weather, 'humidity', 0);
    final windSpeed = (weather['windSpeed'] as num?)?.toDouble() ?? 0.0;
    final icon = _getString(weather, 'icon', '01d');

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        // margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.3),
                AppColors.primaryGreen.withValues(alpha: 0.6),
                Colors.blueGrey.withValues(alpha: 0.1),
                AppColors.primaryGreen.withValues(alpha: 0.4),
                AppColors.primaryGreen.withValues(alpha: 0.6),
                AppColors.primaryGreen.withValues(alpha: 0.6),
                Colors.green.withValues(alpha: 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with location and refresh
            Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Weather - $location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isOnline)
                  Icon(
                    Icons.offline_bolt,
                    color: Colors.orange.withOpacity(0.8),
                    size: 16,
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isRequestingLocation ? null : _requestLocationAndRefresh,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isRequestingLocation
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Icon(
                      Icons.my_location,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Main weather info
            Row(
              children: [
                // Temperature
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${temperature.toStringAsFixed(0)}°C',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                      Text(
                        description.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Weather icon
                Expanded(
                  child: Column(
                    children: [
                      Image.network(
                        'https://openweathermap.org/img/wn/$icon@2x.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.wb_sunny,
                            size: 80,
                            color: Colors.white.withOpacity(0.8),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Weather details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '$humidity%',
                ),
                _buildWeatherDetail(
                  icon: Icons.air,
                  label: 'Wind',
                  value: '${windSpeed.toStringAsFixed(1)} m/s',
                ),
                _buildWeatherDetail(
                  icon: farmingAdviceAsync.when(
                    data: (advice) => isFarmingGood.when(
                      data: (isGood) => isGood ? Icons.check_circle : Icons.warning,
                      loading: () => Icons.hourglass_empty,
                      error: (_, __) => Icons.help_outline,
                    ),
                    loading: () => Icons.hourglass_empty,
                    error: (_, __) => Icons.help_outline,
                  ),
                  label: 'Farming',
                  value: isFarmingGood.when(
                    data: (isGood) => isGood ? 'Good' : 'Caution',
                    loading: () => '...',
                    error: (_, __) => 'Unknown',
                  ),
                ),
              ],
            ),

            // Farming advice
            const SizedBox(height: 16),
            farmingAdviceAsync.when(
              data: (advice) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => _buildAdviceShimmer(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Tap for more details
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/weather-details'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tap for detailed forecast →',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handleWeatherError(BuildContext context, Object error, bool isOnline) {
    String errorMessage = error.toString();

    // Handle location permission errors
    if (errorMessage.contains('permission') && !_hasShownPermissionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasShownPermissionDialog = true;
        _showLocationPermissionDialog();
      });
    }

    return _buildErrorCard(context, error);
  }

  Future<void> _requestLocationAndRefresh() async {
    if (_isRequestingLocation) return;

    setState(() {
      _isRequestingLocation = true;
    });

    try {
      final permissionResult = await LocationService.requestLocationPermission();

      switch (permissionResult) {
        case LocationPermissionResult.granted:
        // Refresh weather data
          ref.invalidate(currentWeatherProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Location updated! Refreshing weather...'),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;

        case LocationPermissionResult.denied:
        case LocationPermissionResult.deniedForever:
          await _showLocationPermissionDialog();
          break;

        case LocationPermissionResult.serviceDisabled:
          await _showLocationServiceDialog();
          break;

        case LocationPermissionResult.error:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to access location. Please try again.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingLocation = false;
        });
      }
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    await LocationService.showLocationPermissionDialog(context);
  }

  Future<void> _showLocationServiceDialog() async {
    await LocationService.showLocationServiceDialog(context);
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceShimmer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.white.withOpacity(0.8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Getting weather data...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withOpacity(0.3),
              Colors.red.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weather Unavailable',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to get weather data. Using default location (Accra).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _requestLocationAndRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for safe data extraction
  double _getTemperature(Map<String, dynamic> weather) {
    final temp = weather['temperature'];
    if (temp == null) return 25.0;
    if (temp is int) return temp.toDouble();
    if (temp is double) return temp;
    if (temp is String) return double.tryParse(temp) ?? 25.0;
    return 25.0;
  }

  String _getString(Map<String, dynamic> weather, String key, [String defaultValue = '']) {
    final value = weather[key];
    return value?.toString() ?? defaultValue;
  }

  int _getInt(Map<String, dynamic> weather, String key, [int defaultValue = 0]) {
    final value = weather[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}