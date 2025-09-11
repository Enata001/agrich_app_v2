import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<bool> _networkController = StreamController<bool>.broadcast();

  bool _isConnected = true;

  NetworkService() {
    _initNetworkListener();
  }

  void _initNetworkListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _checkNetworkStatus(result);
    });

    _connectivity.checkConnectivity().then(_checkNetworkStatus);
  }

  void _checkNetworkStatus(List<ConnectivityResult> result) async {
    bool wasConnected = _isConnected;

    if (result.contains(ConnectivityResult.none)) {
      _isConnected = false;
    } else {
      _isConnected = await _hasInternetConnection();
    }

    if (wasConnected != _isConnected) {
      _networkController.add(_isConnected);
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  bool get isConnected => _isConnected;

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      return false;
    }
    return await _hasInternetConnection();
  }

  Stream<bool> get networkStream => _networkController.stream;

  Future<T> executeWithTimeout<T>(
      Future<T> Function() operation, {
        Duration timeout = const Duration(seconds: 10),
        int retries = 2,
      }) async {
    if (!_isConnected) {
      throw NetworkException('No internet connection');
    }

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        return await operation().timeout(timeout);
      } catch (e) {
        if (attempt == retries) {
          if (e is TimeoutException) {
            throw NetworkException('Operation timed out after ${timeout.inSeconds} seconds');
          }
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    throw NetworkException('Max retries exceeded');
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _networkController.close();
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

final networkServiceProvider = Provider<NetworkService>((ref) {
  final service = NetworkService();
  ref.onDispose(() => service.dispose());
  return service;
});

final networkStatusProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final networkService = ref.watch(networkServiceProvider);
  yield networkService.isConnected;
  yield* networkService.networkStream;
});
