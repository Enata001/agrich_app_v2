import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/network_service.dart';

class NetworkErrorWidget extends ConsumerWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool showOfflineData;
  final Widget? offlineWidget;

  const NetworkErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.showOfflineData = false,
    this.offlineWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (isOnline) => isOnline
          ? _buildRetryWidget(context)
          : _buildOfflineWidget(context),
      loading: () => _buildRetryWidget(context),
      error: (_, _) => _buildRetryWidget(context),
    );
  }

  Widget _buildOfflineWidget(BuildContext context) {
    if (showOfflineData && offlineWidget != null) {
      return Column(
        children: [
          _buildOfflineBanner(context),
          Expanded(child: offlineWidget!),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: Colors.orange.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re Offline',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature requires an internet connection.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.orange.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.red.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.offline_bolt, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'Offline - Showing cached data',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Specific error widget for videos (strictly online)
class VideoNetworkErrorWidget extends ConsumerWidget {
  final VoidCallback? onRetry;

  const VideoNetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NetworkErrorWidget(
      title: 'Videos Unavailable',
      message: 'Videos require internet connection. Please check your network and try again.',
      onRetry: onRetry,
    );
  }
}

// ✅ Network status banner widget
class NetworkStatusBanner extends ConsumerWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (isOnline) => !isOnline
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.orange,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.offline_bolt, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'You\'re offline - Some features may be limited',
              style: TextStyle(
                color: Colors.white,
                fontSize: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}