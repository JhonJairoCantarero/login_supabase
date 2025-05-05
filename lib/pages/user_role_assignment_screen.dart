import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ylapp/models/user_role.dart';
import 'package:ylapp/models/app_user.dart';

class UserRoleAssignmentScreen extends StatefulWidget {
  const UserRoleAssignmentScreen({super.key});

  @override
  State<UserRoleAssignmentScreen> createState() => _UserRoleAssignmentScreenState();
}

class _UserRoleAssignmentScreenState extends State<UserRoleAssignmentScreen> {
  List<AppUser> _users = [];
  List<UserRole> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Cargar usuarios
      final usersResponse = await Supabase.instance.client
          .from('profiles')
          .select('*, users(email, created_at, last_sign_in_at)');

      // Cargar roles
      final rolesResponse = await Supabase.instance.client
          .from('user_roles')
          .select('*');

      setState(() {
        _users = usersResponse.map<AppUser>((user) {
          return AppUser.fromJson({
            'id': user['user_id'],
            'email': user['users']['email'],
            'full_name': user['full_name'],
            'role': user['role'],
            'created_at': user['users']['created_at'],
            'last_sign_in_at': user['users']['last_sign_in_at'],
          });
        }).toList();

        _roles = rolesResponse.map<UserRole>((role) {
          return UserRole(
            id: role['id'] as String,
            name: role['name'] as String,
            description: role['description'] as String?,
            isDefault: role['is_default'] as bool? ?? false,
            moduleIds: [],
          );
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _assignRoleToUser(AppUser user, String roleId) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': roleId})
          .eq('user_id', user.id);

      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = AppUser(
            id: user.id,
            email: user.email,
            fullName: user.fullName,
            role: roleId,
            createdAt: user.createdAt,
            lastSignInAt: user.lastSignInAt,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol asignado exitosamente a ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRoleAssignmentDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar rol a ${user.email}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_roles.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay roles disponibles'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = user.role == role.id;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: RadioListTile<String>(
                        title: Text(
                          role.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: role.description != null && role.description!.isNotEmpty
                            ? Text(role.description!)
                            : null,
                        value: role.id,
                        groupValue: user.role,
                        onChanged: (value) async {
                          if (value != null) {
                            await _assignRoleToUser(user, value);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignación de Roles'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final userRole = _roles.firstWhere(
            (role) => role.id == user.role,
            orElse: () => UserRole(
              id: '',
              name: 'Sin rol',
              isDefault: false,
              moduleIds: [],
            ),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(user.email[0].toUpperCase()),
              ),
              title: Text(
                user.email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.fullName != null && user.fullName!.isNotEmpty)
                    Text('Nombre: ${user.fullName}'),
                  Text('Rol actual: ${userRole.name}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showRoleAssignmentDialog(user),
                tooltip: 'Asignar rol',
              ),
            ),
          );
        },
      ),
    );
  }
} 