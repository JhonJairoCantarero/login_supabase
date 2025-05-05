import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ylapp/models/module.dart';
import 'package:ylapp/models/user_role.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<UserRole> _roles = [];
  List<Module> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Cargar roles
      final rolesResponse = await Supabase.instance.client
          .from('user_roles')
          .select('*, role_module_access(module_id)');
      
      // Cargar módulos
      final modulesResponse = await Supabase.instance.client
          .from('modules')
          .select('*');

      setState(() {
        _roles = rolesResponse.map<UserRole>((role) {
          final moduleIds = (role['role_module_access'] as List)
              .map<String>((access) => access['module_id'] as String)
              .toList();
          
          return UserRole(
            id: role['id'] as String,
            name: role['name'] as String,
            description: role['description'] as String?,
            isDefault: role['is_default'] as bool? ?? false,
            moduleIds: moduleIds,
          );
        }).toList();

        _modules = modulesResponse.map<Module>((module) {
          return Module.fromJson(module);
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

  Future<void> _createRole() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final newRole = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'is_default': false,
      };

      final response = await Supabase.instance.client
          .from('user_roles')
          .insert(newRole)
          .select()
          .single();

      setState(() {
        _roles.add(UserRole(
          id: response['id'] as String,
          name: response['name'] as String,
          description: response['description'] as String?,
          isDefault: response['is_default'] as bool? ?? false,
          moduleIds: [],
        ));
      });

      Navigator.pop(context);
      _nameController.clear();
      _descriptionController.clear();

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Rol creado',
        desc: 'El rol ${response['name']} ha sido creado exitosamente',
        btnOkOnPress: () {},
        btnOkColor: Colors.green,
        autoHide: const Duration(seconds: 3),
      ).show();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear rol: $e')),
      );
    }
  }

  Future<void> _updateRoleModules(UserRole role, List<String> selectedModuleIds) async {
    try {
      // Eliminar accesos existentes
      await Supabase.instance.client
          .from('role_module_access')
          .delete()
          .eq('role_id', role.id);

      // Insertar nuevos accesos
      if (selectedModuleIds.isNotEmpty) {
        await Supabase.instance.client
            .from('role_module_access')
            .insert(
              selectedModuleIds.map((moduleId) => {
                'role_id': role.id,
                'module_id': moduleId,
                'can_view': true,
                'can_edit': false,
              }).toList(),
            );
      }

      setState(() {
        final index = _roles.indexWhere((r) => r.id == role.id);
        if (index != -1) {
          _roles[index] = UserRole(
            id: role.id,
            name: role.name,
            description: role.description,
            isDefault: role.isDefault,
            moduleIds: selectedModuleIds,
          );
        }
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Módulos actualizados',
        desc: 'Los módulos para el rol ${role.name} han sido actualizados exitosamente',
        btnOkOnPress: () {},
        btnOkColor: Colors.green,
        autoHide: const Duration(seconds: 3),
      ).show();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar módulos: $e')),
      );
    }
  }

  void _showRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Rol'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _createRole,
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showModuleSelectionDialog(UserRole role) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Módulos para ${role.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_modules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay módulos disponibles'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _modules.length,
                    itemBuilder: (context, index) {
                      final module = _modules[index];
                      final isSelected = role.moduleIds.contains(module.id);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: CheckboxListTile(
                          title: Text(
                            module.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (module.description != null && module.description!.isNotEmpty)
                                Text(module.description!),
                              if (module.routePath != null)
                                Text(
                                  'Ruta: ${module.routePath}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          secondary: module.icon != null
                              ? Image.network(
                                  module.icon!,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                )
                              : const Icon(Icons.widgets),
                          value: isSelected,
                          onChanged: (value) async {
                            setState(() {
                              if (value == true) {
                                role.moduleIds.add(module.id);
                              } else {
                                role.moduleIds.remove(module.id);
                              }
                            });

                            try {
                              await _updateRoleModules(role, role.moduleIds);
                            } catch (e) {
                              setState(() {
                                if (value == true) {
                                  role.moduleIds.remove(module.id);
                                } else {
                                  role.moduleIds.add(module.id);
                                }
                              });
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
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoleDialog(UserRole role) {
    _nameController.text = role.name;
    _descriptionController.text = role.description ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Rol'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await Supabase.instance.client
                      .from('user_roles')
                      .update({
                        'name': _nameController.text,
                        'description': _descriptionController.text,
                      })
                      .eq('id', role.id);

                  setState(() {
                    final index = _roles.indexWhere((r) => r.id == role.id);
                    if (index != -1) {
                      _roles[index] = UserRole(
                        id: role.id,
                        name: _nameController.text,
                        description: _descriptionController.text,
                        isDefault: role.isDefault,
                        moduleIds: role.moduleIds,
                      );
                    }
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rol "${_nameController.text}" actualizado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar el rol: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoleDialog(UserRole role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rol'),
        content: Text('¿Estás seguro de eliminar el rol "${role.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Primero eliminar los accesos a módulos
                await Supabase.instance.client
                    .from('role_module_access')
                    .delete()
                    .eq('role_id', role.id);

                // Luego eliminar el rol
                await Supabase.instance.client
                    .from('user_roles')
                    .delete()
                    .eq('id', role.id);

                setState(() {
                  _roles.removeWhere((r) => r.id == role.id);
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rol "${role.name}" eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar el rol: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
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
        title: const Text('Gestión de Roles'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final role = _roles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(
                role.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (role.description != null && role.description!.isNotEmpty)
                    Text(role.description!),
                  const SizedBox(height: 4),
                  Text(
                    'Módulos asignados: ${role.moduleIds.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditRoleDialog(role),
                    tooltip: 'Editar rol',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteRoleDialog(role),
                    tooltip: 'Eliminar rol',
                  ),
                  IconButton(
                    icon: const Icon(Icons.widgets),
                    onPressed: () => _showModuleSelectionDialog(role),
                    tooltip: 'Asignar módulos',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRoleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 