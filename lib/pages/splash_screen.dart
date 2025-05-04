import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ylapp/utils/lottie_utils.dart';
import 'package:ylapp/auth/auth_service.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/pages/admin_dashboard.dart';
import 'package:ylapp/pages/user_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AuthService _authService = AuthService();
  String _animationPath = '';

  @override
  void initState() {
    super.initState();
    _animationPath = LottieUtils.getRandomAnimation();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simular un tiempo de carga mínimo de 5 segundos
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    if (_authService.isLoggedIn) {
      try {
        final userProfile = await _authService.getCurrentUserProfile();
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => userProfile.role.toLowerCase() == 'admin'
                ? const AdminDashboardPage()
                : const UserDashboardPage(),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'lib/assets/images/logoferre.png',
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 32),
            
            // Animación Lottie
            Lottie.asset(
              _animationPath,
              controller: _controller,
              height: 250,
              width: 250,
              fit: BoxFit.contain,
              repeat: true,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..forward()
                  ..repeat();
              },
            ),
            const SizedBox(height: 32),
            // Texto de carga
            Text(
              'Cargando...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}