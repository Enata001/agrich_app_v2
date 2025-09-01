import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../shared/widgets/loading_indicator.dart';
import '../providers/weather_provider.dart';


class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherData = ref.watch(currentWeatherProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
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
      child: weatherData.when(
        data: (weather) => _buildWeatherContent(context, weather),
        loading: () => const Center(
          child: LoadingIndicator(
            size: LoadingSize.small,
            color: Colors.white,
          ),
        ),
        error: (error, stack) => _buildErrorContent(context, error),
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context, Map<String, dynamic> weather) {
    final temperature = weather['temperature']?.toInt() ?? 0;
    final description = weather['description'] ?? '';
    final city = weather['city'] ?? '';
    final icon = weather['icon'] ?? '';
    final humidity = weather['humidity'] ?? 0;
    final windSpeed = weather['windSpeed']?.toStringAsFixed(1) ?? '0.0';

    return Column(
      children: [
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
                        Icons.location_on_outlined,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$temperature°C',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    description.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (icon.isNotEmpty)
              CachedNetworkImage(
                imageUrl: 'https://openweathermap.org/img/wn/$icon@2x.png',
                width: 80,
                height: 80,
                placeholder: (context, url) => const SizedBox(
                  width: 80,
                  height: 80,
                  child: LoadingIndicator(size: LoadingSize.small),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(
                context,
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '$humidity%',
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildWeatherDetail(
                context,
                icon: Icons.air,
                label: 'Wind',
                value: '$windSpeed m/s',
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildWeatherDetail(
                context,
                icon: _getFarmingIcon(weather),
                label: 'Farming',
                value: _getFarmingStatus(weather),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, Object error) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.white.withValues(alpha: 0.7),
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'Weather data unavailable',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to retry',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  IconData _getFarmingIcon(Map<String, dynamic> weather) {
    final isFarmingGood = _isFarmingWeatherGood(weather);
    return isFarmingGood ? Icons.check_circle_outline : Icons.warning_outlined;
  }

  String _getFarmingStatus(Map<String, dynamic> weather) {
    final isFarmingGood = _isFarmingWeatherGood(weather);
    return isFarmingGood ? 'Good' : 'Caution';
  }

  bool _isFarmingWeatherGood(Map<String, dynamic> weather) {
    final temperature = weather['temperature'] as double? ?? 0.0;
    final humidity = weather['humidity'] as int? ?? 0;
    final windSpeed = weather['windSpeed'] as double? ?? 0.0;
    final condition = weather['main'] as String? ?? '';

    // Ideal farming conditions
    bool temperatureOk = temperature >= 15 && temperature <= 35;
    bool humidityOk = humidity >= 40 && humidity <= 80;
    bool windOk = windSpeed < 10;
    bool conditionOk = !['Thunderstorm', 'Snow'].contains(condition);

    return temperatureOk && humidityOk && windOk && conditionOk;
  }
}