import 'package:flutter/material.dart';
import 'package:ylapp/auth/auth_service.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/models/app_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error al cargar perfil: ${e.toString()}');
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

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _nameController.text = _currentUser?.fullName ?? '';
        _emailController.text = _currentUser?.email ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    try {
      await _authService.updateProfile(
        fullName: _nameController.text,
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      await _loadCurrentUser();
      _showSnackBar('Perfil actualizado correctamente');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error al actualizar perfil: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Fecha desconocida';
    
    try {
      final dateTime = DateTime.tryParse(dateString);
      if (dateTime != null) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      // Si falla el parsing, devuelve el string original
    }
    
    return dateString;
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blue[100],
          child: Text(
            _currentUser?.fullName?.isNotEmpty == true 
                ? _currentUser!.fullName![0].toUpperCase()
                : 'U',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _currentUser?.fullName ?? 'Nombre no especificado',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _currentUser?.email ?? '',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Rol',
                  value: (_currentUser?.role ?? 'user').toUpperCase(),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Miembro desde',
                  value: _formatDateString(_currentUser?.createdAt),
                ),
                if (_currentUser?.lastSignInAt?.isNotEmpty ?? false) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.login,
                    label: 'Último acceso',
                    value: _formatDateString(_currentUser?.lastSignInAt),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.person, size: 50, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.black12,
              enabled: false,
            ),
            readOnly: true,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _toggleEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Guardar Cambios'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Perfil' : 'Mi Perfil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing 
              ? _buildEditForm()
              : _buildProfileInfo(),
    );
  }
}