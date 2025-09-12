import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {
  // Enhanced permission request with multiple fallbacks
  static Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult.serviceDisabled;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        // If still denied after request
        if (permission == LocationPermission.denied) {
          return LocationPermissionResult.denied;
        }
      }

      // Check if permission is permanently denied
      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionResult.deniedForever;
      }

      // Permission granted
      return LocationPermissionResult.granted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return LocationPermissionResult.error;
    }
  }

  // Enhanced location retrieval with multiple accuracy levels
  static Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration? timeLimit,
  }) async {
    try {
      final permissionResult = await requestLocationPermission();

      if (permissionResult != LocationPermissionResult.granted) {
        print('Location permission not granted: $permissionResult');
        return null;
      }

      // Try to get location with specified accuracy
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: accuracy,

            timeLimit: timeLimit ?? const Duration(seconds: 15),
          ),
        );
      } catch (e) {
        print('Failed to get precise location, trying with lower accuracy: $e');

        // Fallback to lower accuracy if high accuracy fails
        try {
          return await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: accuracy,

              timeLimit: const Duration(seconds: 10),
            ),
          );
        } catch (e2) {
          print('Failed to get location with low accuracy: $e2');

          // Last resort: get last known position
          return await Geolocator.getLastKnownPosition();
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Enhanced permission dialog with better messaging
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Location Permission'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AgriCH needs location access to provide you with:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Accurate weather information')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.tips_and_updates, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('Location-based farming tips')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Tag posts with your location')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Your location data is only used for these features and is never shared with third parties.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              // Open app settings
              Geolocator.openAppSettings();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    return result ?? false;
  }



  // Enhanced location service dialog
  static Future<bool> showLocationServiceDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Location Services Disabled'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enable location services in your device settings to use location-based features like weather and farming tips.',
            ),
            SizedBox(height: 16),
            Text(
              'This will help us provide more accurate and relevant information for your farming needs.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              // Open location settings
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Get location with user-friendly error handling
  static Future<LocationResult> getCurrentLocationWithResult() async {
    try {
      // Check services first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error('Location services are disabled');
      }

      // Check permissions
      if (!await hasLocationPermission()) {
        final permissionResult = await requestLocationPermission();
        if (permissionResult != LocationPermissionResult.granted) {
          return LocationResult.error('Location permission is required');
        }
      }

      // Get location
      final position = await getCurrentLocation();
      if (position != null) {
        return LocationResult.success(position);
      } else {
        return LocationResult.error('Unable to get current location');
      }
    } catch (e) {
      return LocationResult.error('Location error: $e');
    }
  }
}

enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

class LocationResult {
  final bool isSuccess;
  final Position? position;
  final String? error;

  LocationResult._({required this.isSuccess, this.position, this.error});

  factory LocationResult.success(Position position) {
    return LocationResult._(isSuccess: true, position: position);
  }

  factory LocationResult.error(String error) {
    return LocationResult._(isSuccess: false, error: error);
  }
}
