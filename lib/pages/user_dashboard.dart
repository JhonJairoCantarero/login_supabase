import 'package:flutter/material.dart';
import 'package:ylapp/auth/auth_service.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/models/app_user.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController(); // Nuevo controlador
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _nameController.dispose(); // Limpiar el controlador
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) {
        _nameController.text = _currentUser?.fullName ?? ''; // Inicializar con valor actual
        return AlertDialog(
          title: const Text('Actualizar perfil'),
          content: Form( // Widget Form agregado
            child: TextFormField(
              controller: _nameController, // Usar el controlador
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _nameController.text), // Obtener valor del controlador
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (updatedName != null && updatedName != _currentUser?.fullName) {
      try {
        await _authService.updateProfile(fullName: updatedName);
        _loadCurrentUser();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar perfil: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Text(
                        _currentUser?.fullName?[0] ?? 'U',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Nombre completo'),
                      subtitle: Text(_currentUser?.fullName ?? 'No especificado'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _updateProfile,
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(_currentUser?.email ?? ''),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.verified_user),
                      title: const Text('Rol'),
                      subtitle: Text(_currentUser?.role ?? 'user'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}