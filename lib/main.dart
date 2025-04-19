import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ylapp/auth/auth_gate.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/pages/perfil_page.dart';
import 'package:ylapp/pages/register_page.dart';
import 'package:ylapp/pages/admin_dashboard.dart';
import 'package:ylapp/pages/user_dashboard.dart';
import 'package:ylapp/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://frcjxppunygebtaygxyr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyY2p4cHB1bnlnZWJ0YXlneHlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMzk5MDAsImV4cCI6MjA1NzkxNTkwMH0.nYQmhel7Enq05X8GpS1pJgxaICEFl1WMGxvXOqCdHZw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tu Aplicación',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthGate(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/admin': (context) => const AdminDashboardPage(),
        '/user': (context) => const UserDashboardPage(),
        '/perfil': (context) => const ProfilePage(),
      },
      // Opcional: Manejo de rutas no definidas
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Página no encontrada')),
          ),
        );
      },
    );
  }
}