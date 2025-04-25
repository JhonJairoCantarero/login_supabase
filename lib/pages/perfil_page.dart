import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ylapp/auth/auth_service.dart';
import 'package:ylapp/pages/login_page.dart';
import 'package:ylapp/models/app_user.dart';
import 'package:ylapp/services/theme_service.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perfil: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfile() async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) {
        _nameController.text = _currentUser?.fullName ?? '';
        return AlertDialog(
          title: const Text('Actualizar perfil'),
          content: Form(
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _nameController.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (updatedName != null && updatedName != _currentUser?.fullName && mounted) {
      try {
        await _authService.updateProfile(
          context: context,
          fullName: updatedName,
        );
        await _loadCurrentUser();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar perfil: ${e.toString()}')),
        );
      }
    }
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
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? const Color(0xFFFFD700) : Colors.blue;

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
                  iconColor: iconColor,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Miembro desde',
                  value: _formatDateString(_currentUser?.createdAt),
                  iconColor: iconColor,
                ),
                if (_currentUser?.lastSignInAt?.isNotEmpty ?? false) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.login,
                    label: 'Último acceso',
                    value: _formatDateString(_currentUser?.lastSignInAt),
                    iconColor: iconColor,
                  ),
                ],
                const Divider(height: 24),
                ListTile(
                  leading: Icon(
                    themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: iconColor,
                  ),
                  title: Text(
                    themeService.isDarkMode ? 'Modo Oscuro' : 'Modo Claro',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: Switch(
                    value: themeService.isDarkMode,
                    onChanged: (value) {
                      themeService.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    activeColor: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String label, 
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: iconColor),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: _buildProfileInfo(),
            ),
    );
  }
}