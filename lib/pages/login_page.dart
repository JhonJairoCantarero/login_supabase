import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ylapp/auth/auth_service.dart';
import 'package:ylapp/pages/admin_dashboard.dart';
import 'package:ylapp/pages/user_dashboard.dart';
import 'package:ylapp/pages/register_page.dart';
import 'package:ylapp/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loginError;
  bool _roleVerified = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    if (_authService.isLoggedIn) {
      setState(() => _isLoading = true);
      try {
        final userProfile = await _authService.getCurrentUserProfile();
        if (mounted) {
          _redirectBasedOnRole(userProfile.role);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loginError = 'Error al verificar sesión. Por favor, ingresa nuevamente.';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
      _roleVerified = false;
    });

    try {
      // 1. Autenticar al usuario
      final authResponse = await _authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        throw Exception('Usuario no encontrado');
      }

      // 2. Esperar breve momento para asegurar autenticación completa
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. Obtener el perfil completo del usuario
      final userProfile = await _authService.getCurrentUserProfile();
      if (kDebugMode) {
        debugPrint('Usuario autenticado: ${userProfile.email}');
        debugPrint('Rol del usuario: ${userProfile.role}');
      }

      // 4. Marcar que el rol ha sido verificado
      _roleVerified = true;

      // 5. Redirigir según el rol
      if (mounted) {
        _redirectBasedOnRole(userProfile.role);
      }

    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Credenciales incorrectas';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Por favor verifica tu email antes de iniciar sesión';
      } else {
        errorMessage = 'Error al iniciar sesión: ${e.toString().replaceAll('Exception: ', '')}';
      }

      if (mounted) {
        setState(() {
          _loginError = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  void _redirectBasedOnRole(String role) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (!_roleVerified) {
            return const HomePage(); // Página temporal mientras se verifica el rol
          }
          return role.toLowerCase() == 'admin'
              ? const AdminDashboardPage()
              : const UserDashboardPage();
        },
      ),
      (route) => false, // Elimina todas las rutas anteriores
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingrese un email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Elimina el botón de retroceso
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo de email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              // Campo de contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword 
                          ? Icons.visibility_off_outlined 
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: _validatePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 20),

              // Mostrar error de login
              if (_loginError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _loginError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Botón de inicio de sesión
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Enlace a registro
              TextButton(
                onPressed: _isLoading 
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        ),
                child: RichText(
                  text: TextSpan(
                    text: '¿No tienes una cuenta? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                        ),
                    children: const [
                      TextSpan(
                        text: 'Regístrate',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}