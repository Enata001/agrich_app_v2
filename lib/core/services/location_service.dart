
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {
  static Future<LocationPermissionResult> requestLocationPermission() async {
    try {

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult.serviceDisabled;
      }


      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationPermissionResult.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionResult.deniedForever;
      }

      return LocationPermissionResult.granted;
    } catch (e) {
      return LocationPermissionResult.error;
    }
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final permissionResult = await requestLocationPermission();

      if (permissionResult != LocationPermissionResult.granted) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> showLocationPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'AgriCH needs location access to:\n\n'
              '• Provide accurate weather information\n'
              '• Show location-based farming tips\n'
              '• Help you tag posts with your location\n\n'
              'Your location data is only used for these features and is not shared with third parties.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Future<void> showLocationServiceDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services in your device settings to use location-based features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}