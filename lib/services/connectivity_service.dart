import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  final _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<void> initialize() async {
    // Verificar el estado inicial
    final result = await _connectivity.checkConnectivity();
    _connectivityController.add(_isConnected(result));

    // Suscribirse a los cambios de conectividad
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _connectivityController.add(_isConnected(result));
    });
  }

  bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
} 