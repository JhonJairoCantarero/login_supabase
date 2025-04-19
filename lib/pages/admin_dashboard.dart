import 'package:flutter/material.dart';
import 'package:ylapp/auth/auth_service.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/pages/home_page.dart';
import 'package:ylapp/pages/perfil_page.dart';
import 'package:ylapp/models/app_user.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  List<AppUser> _users = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String _selectedRole = 'user';
  AppUser? _currentUser;

  final List<Widget> _pages = [
    const HomePage(),
    const ProfilePage(),
    // El contenido del admin será renderizado condicionalmente
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() => _currentUser = user);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error al cargar perfil: ${e.toString()}');
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
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error al cerrar sesión: ${e.toString()}');
    }
  }

  Future<void> _editUserRole(AppUser user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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