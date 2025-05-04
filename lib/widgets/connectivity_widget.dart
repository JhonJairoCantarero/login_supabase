import 'package:flutter/material.dart';
import 'package:ylapp/services/connectivity_service.dart';

class ConnectivityWidget extends StatefulWidget {
  final Widget child;
  final ConnectivityService connectivityService;

  const ConnectivityWidget({
    Key? key,
    required this.child,
    required this.connectivityService,
  }) : super(key: key);

  @override
  State<ConnectivityWidget> createState() => _ConnectivityWidgetState();
}

class _ConnectivityWidgetState extends State<ConnectivityWidget> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  void _initializeConnectivity() {
    widget.connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isConnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red,
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sin conexión a internet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConnected = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 