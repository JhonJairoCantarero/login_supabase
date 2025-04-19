import 'package:flutter/material.dart';
import 'package:ylapp/auth/auth_service.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/models/app_user.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AuthService _authService = AuthService();
  List<AppUser> _users = [];
  bool _isLoading = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final users = await _authService.getUsersList();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error al cargar usuarios: ${e.toString()}');
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // Esto elimina completamente el stack de navegación
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error al cerrar sesión: ${e.toString()}');
    }
  }

  Future<void> _editUserRole(AppUser user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cambiar rol de ${user.email}'),
          content: DropdownButtonFormField<String>(
            value: user.role,
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              DropdownMenuItem(value: 'user', child: Text('Usuario regular')),
            ],
            onChanged: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, user.role),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newRole != null && newRole != user.role && mounted) {
      try {
        await _authService.updateUserRole(user.id, newRole);
        _showSnackBar('Rol de ${user.email} actualizado');
        await _loadUsers();
      } catch (e) {
        _showSnackBar('Error al actualizar rol: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: const Text('Agregar nuevo usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                    ),
                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Nombre completo'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                        DropdownMenuItem(value: 'user', child: Text('Usuario regular')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      try {
        await _authService.registerWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          role: _selectedRole,
        );
        
        _emailController.clear();
        _passwordController.clear();
        _fullNameController.clear();
        
        await _loadUsers();
        _showSnackBar('Usuario creado exitosamente');
      } catch (e) {
        _showSnackBar('Error al crear usuario: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        automaticallyImplyLeading: false, // Esto elimina el botón de retroceso
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No hay usuarios registrados'))
              : ListView.builder(
  itemCount: _users.length,
  itemBuilder: (context, index) {
    final user = _users[index];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.email[0].toUpperCase()),
        ),
        title: Text(user.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.fullName != null) 
              Text('Nombre: ${user.fullName}'),
            Text('Rol: ${user.role}'),
            // Eliminamos las líneas que mostraban las fechas
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editUserRole(user),
        ),
      ),
    );
  },
),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}