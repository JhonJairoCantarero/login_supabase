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
  Map<String, List<String>> _userRoles = {}; // Map<userId, List<roleIds>>
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

      // Cargar asignaciones de roles
      final assignmentsResponse = await Supabase.instance.client
          .from('user_roles_assignment')
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

        // Inicializar el mapa de asignaciones
        _userRoles = {};
        for (var user in _users) {
          _userRoles[user.id] = [];
        }

        // Llenar el mapa con las asignaciones existentes
        for (var assignment in assignmentsResponse) {
          final userId = assignment['user_id'] as String;
          final roleId = assignment['role_id'] as String;
          if (_userRoles.containsKey(userId)) {
            _userRoles[userId]!.add(roleId);
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _assignRole(String userId, String roleId, bool assign) async {
    try {
      if (assign) {
        // Asignar rol
        await Supabase.instance.client
            .from('user_roles_assignment')
            .insert({
              'user_id': userId,
              'role_id': roleId,
            });
      } else {
        // Eliminar asignación
        await Supabase.instance.client
            .from('user_roles_assignment')
            .delete()
            .eq('user_id', userId)
            .eq('role_id', roleId);
      }

      setState(() {
        if (assign) {
          _userRoles[userId]!.add(roleId);
        } else {
          _userRoles[userId]!.remove(roleId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(assign ? 'Rol asignado exitosamente' : 'Rol removido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${assign ? 'asignar' : 'remover'} rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          final userRoles = _userRoles[user.id] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                user.email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.fullName != null && user.fullName!.isNotEmpty)
                    Text('Nombre: ${user.fullName}'),
                  Text('Roles asignados: ${userRoles.length}'),
                ],
              ),
              children: _roles.map((role) {
                final isAssigned = userRoles.contains(role.id);
                return CheckboxListTile(
                  title: Text(role.name),
                  subtitle: role.description != null ? Text(role.description!) : null,
                  value: isAssigned,
                  onChanged: (value) => _assignRole(user.id, role.id, value ?? false),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
} 