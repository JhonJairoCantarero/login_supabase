import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ylapp/services/theme_service.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/pages/perfil_page.dart';
import 'package:ylapp/pages/register_page.dart';
import 'package:ylapp/pages/admin_dashboard.dart';
import 'package:ylapp/pages/user_dashboard.dart';
import 'package:ylapp/pages/splash_screen.dart';
import 'package:ylapp/services/connectivity_service.dart';
import 'package:ylapp/widgets/connectivity_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://frcjxppunygebtaygxyr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyY2p4cHB1bnlnZWJ0YXlneHlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMzk5MDAsImV4cCI6MjA1NzkxNTkwMH0.nYQmhel7Enq05X8GpS1pJgxaICEFl1WMGxvXOqCdHZw',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'YL App',
          theme: ThemeData(
            primarySwatch: Colors.orange,
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: themeService.themeMode,
          home: ConnectivityWidget(
            connectivityService: _connectivityService,
            child: const SplashScreen(),
          ),
        );
      },
    );
  }
}