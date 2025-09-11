import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isConnected = false;

  // Stream controller for connectivity status
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {

    _isConnected = await checkConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged
        .expand((results) => results)
        .listen((result) async {
      final wasConnected = _isConnected;
      _isConnected = await checkConnectivity();
      if (wasConnected != _isConnected) {
        _connectivityController.add(_isConnected);
        if (kDebugMode) {
          print('🌐 Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}');
        }
      }
    });
  }

  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // Additional check to ensure actual internet connectivity
      try {
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (e) {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      return false;
    }
  }

  // Execute Firebase operation with connectivity check
  Future<T> executeWithConnectivity<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    String? operationName,
  }) async {
    if (!_isConnected) {
      final isConnected = await checkConnectivity();
      if (!isConnected) {
        if (kDebugMode) {
          print(
            '🚫 No connectivity for ${operationName ?? "Firebase operation"}',
          );
        }
        if (fallbackValue != null) {
          return fallbackValue;
        }
        throw NoConnectivityException('No internet connection available');
      }
    }

    try {
      return await operation();
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ Firebase operation failed: ${operationName ?? "Unknown"} - $e',
        );
      }
      if (fallbackValue != null) {
        return fallbackValue;
      }
      rethrow;
    }
  }

  // Execute Stream operation with connectivity check
  Stream<T> executeStreamWithConnectivity<T>(
    Stream<T> Function() streamOperation, {
    T? fallbackValue,
    String? operationName,
  }) async* {
    if (!_isConnected) {
      final isConnected = await checkConnectivity();
      if (!isConnected) {
        if (kDebugMode) {
          print(
            '🚫 No connectivity for stream ${operationName ?? "Firebase stream"}',
          );
        }
        if (fallbackValue != null) {
          yield fallbackValue;
        }
        return;
      }
    }

    try {
      yield* streamOperation();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase stream failed: ${operationName ?? "Unknown"} - $e');
      }
      if (fallbackValue != null) {
        yield fallbackValue;
      }
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}

// Custom exception for no connectivity
class NoConnectivityException implements Exception {
  final String message;

  NoConnectivityException(this.message);

  @override
  String toString() => 'NoConnectivityException: $message';
}

// Mixin for connectivity-aware operations
mixin ConnectivityAware {
  ConnectivityService get _connectivityService => ConnectivityService();

  Future<T> withConnectivity<T>(
    Future<T> Function() operation, {
    T? fallback,
    String? operationName,
  }) async {
    return await _connectivityService.executeWithConnectivity(
      operation,
      fallbackValue: fallback,
      operationName: operationName,
    );
  }

  Stream<T> streamWithConnectivity<T>(
    Stream<T> Function() streamOperation, {
    T? fallback,
    String? operationName,
  }) async* {
    yield* _connectivityService.executeStreamWithConnectivity(
      streamOperation,
      fallbackValue: fallback,
      operationName: operationName,
    );
  }
}
