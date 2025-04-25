import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:ylapp/auth/auth_service.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/pages/home_page.dart';
import 'package:ylapp/pages/perfil_page.dart';
import 'package:ylapp/models/app_user.dart';
import 'dart:async';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<AppUser> _users = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  AppUser? _currentUser;
  Timer? _refreshTimer;

  final List<Widget> _pages = [
    const HomePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUsers();
    // Iniciar el timer para actualización automática
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // Cancelar el timer cuando el widget se destruye
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Actualizar cada 10 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _currentIndex == 2) { // Solo actualizar si estamos en la pestaña de admin
        _loadUsers();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() => _currentUser = user);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error al cargar perfil', e.toString());
    }
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
      _showErrorDialog('Error al cargar usuarios', e.toString());
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error al cerrar sesión', e.toString());
    }
  }

  Future<void> _editUserRole(AppUser user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) {
        String selectedRole = user.role;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Cambiar rol para ${user.email}'),
            content: DropdownButtonFormField<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                DropdownMenuItem(value: 'user', child: Text('Usuario regular')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedRole = value);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selectedRole),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );

    if (newRole != null && newRole != user.role && mounted) {
      try {
        await _authService.updateUserRole(user.id, newRole);
        _showSuccessDialog('Rol actualizado', 'El rol de ${user.email} ha sido cambiado a $newRole');
        await _loadUsers();
      } catch (e) {
        _showErrorDialog('Error al actualizar rol', e.toString());
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final fullNameController = TextEditingController();
    String selectedRole = 'user';
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    bool isLoading = false;

    try {
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              final formKey = GlobalKey<FormState>();
              return AlertDialog(
                title: const Text('Agregar nuevo usuario'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa tu email';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                          obscureText: obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                            if (value.length < 8) return 'Mínimo 8 caracteres';
                            if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Debe contener mayúscula';
                            if (!RegExp(r'[0-9]').hasMatch(value)) return 'Debe contener un número';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                            ),
                          ),
                          obscureText: obscureConfirmPassword,
                          validator: (value) {
                            if (value != passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          items: const [
                            DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                            DropdownMenuItem(value: 'user', child: Text('Usuario regular')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedRole = value);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            prefixIcon: Icon(Icons.security),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        setState(() => isLoading = true);
                        try {
                          // Guardamos los valores antes de cerrar el diálogo
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();
                          final fullName = fullNameController.text.trim();

                          // No cerramos el diálogo inmediatamente
                          // Navigator.pop(context);

                          try {
                            await _authService.registerWithEmailPassword(
                              email: email,
                              password: password,
                              fullName: fullName,
                              role: selectedRole,
                            );
                            
                            // Solo cerramos el diálogo si el registro fue exitoso
                            if (mounted) {
                              Navigator.pop(context);
                              _showSuccessDialog(
                                'Usuario creado', 
                                'El usuario $email ha sido registrado exitosamente',
                                onOk: () => _loadUsers(),
                              );
                            }
                          } catch (e, stackTrace) {
                            debugPrint('Error en registerWithEmailPassword: $e');
                            debugPrint('Stack trace: $stackTrace');
                            throw e;
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => isLoading = false);
                            final errorMessage = e.toString().replaceAll('Exception: ', '');
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                title: const Text('Error al crear usuario'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(errorMessage),
                                      const SizedBox(height: 16),
                                      const Text('Detalles técnicos:'),
                                      Text(e.toString()),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear usuario'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // Aseguramos que los controladores se eliminen incluso si hay un error
      emailController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
      fullNameController.dispose();
    }
  }

  void _showSuccessDialog(String title, String message, {VoidCallback? onOk}) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: onOk,
      btnOkColor: Colors.green,
      autoHide: const Duration(seconds: 3),
    ).show();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('No hay usuarios registrados'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(user.email[0].toUpperCase()),
                            ),
                            title: Text(user.email),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user.fullName != null && user.fullName!.isNotEmpty) 
                                  Text('Nombre: ${user.fullName}'),
                                Text('Rol: ${user.role}'),
                                if (user.createdAt != null)
                                  Text(
                                    'Registrado: ${user.createdAt.toString().substring(0, 10)}',
                                  ),
                                if (user.lastSignInAt != null)
                                  Text(
                                    'Último acceso: ${user.lastSignInAt.toString().substring(0, 10)}',
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editUserRole(user),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUser?.fullName ?? 'Administrador'),
            accountEmail: Text(_currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _currentUser?.email[0].toUpperCase() ?? 'A',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Gestión de Usuarios'),
            onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Inicio' :
          _currentIndex == 1 ? 'Perfil' : 'Panel de Administración',
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: _currentIndex == 2 ? [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ] : null,
      ),
      drawer: _buildDrawer(),
      body: _currentIndex == 2 ? _buildAdminContent() : _pages[_currentIndex],
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              onPressed: _showAddUserDialog,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}