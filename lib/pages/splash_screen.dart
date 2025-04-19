import 'package:flutter/material.dart';
import 'package:ylapp/auth/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = AuthService();
    await Future.delayed(const Duration(seconds: 2)); // Tiempo de splash

    if (mounted) {
      if (authService.isLoggedIn) {
        final role = await authService.getUserRole();
        Navigator.pushReplacementNamed(
          context, 
          role == 'admin' ? '/admin' : '/user'
        );
      } else {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: FlutterLogo(size: 100),
      ),
    );
  }
}