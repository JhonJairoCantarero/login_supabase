import 'package:flutter/material.dart';
import 'package:ylapp/models/module.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _routePathController = TextEditingController();
  File? _selectedIcon;
  String? _icon;
  bool _isUploading = false;

  List<Module> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('modules')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _modules = response.map<Module>((module) {
          return Module.fromJson(module);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar módulos: $e')),
      );
    }
  }

  Future<void> _pickIcon() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image != null) {
      setState(() {
        _selectedIcon = File(image.path);
      });
    }
  }

  Future<String?> _uploadIcon() async {
    if (_selectedIcon == null) return null;

    setState(() => _isUploading = true);

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'uploads/$fileName';

      await Supabase.instance.client.storage
          .from('images')
          .upload(path, _selectedIcon!);

      final String publicUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(path);

      setState(() => _isUploading = false);
      return publicUrl;
    } catch (e) {
      print('Error al subir el icono: $e');
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir el icono: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Módulos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _modules.isEmpty
              ? const Center(
                  child: Text('No hay módulos creados'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _modules.length,
                  itemBuilder: (context, index) {
                    final module = _modules[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: module.icon != null
                            ? Image.network(
                                module.icon!,
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error),
                              )
                            : const Icon(Icons.error),
                        title: Text(module.name),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditModuleDialog(context, module),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _showDeleteConfirmation(context, module),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModuleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddModuleDialog(BuildContext context) {
    _nameController.clear();
    _descriptionController.clear();
    _routePathController.clear();
    _selectedIcon = null;
    _icon = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Módulo'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickIcon,
                  icon: const Icon(Icons.image),
                  label: const Text('Seleccionar Icono'),
                ),
                if (_selectedIcon != null) ...[
                  const SizedBox(height: 8),
                  Image.file(
                    _selectedIcon!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ],
                TextFormField(
                  controller: _routePathController,
                  decoration: const InputDecoration(
                    labelText: 'Ruta',
                    helperText: 'Ejemplo: /home, /profile',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una ruta';
                    }
                    return null;
                  },
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
          ElevatedButton(
            onPressed: _isUploading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedIcon == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor seleccione un icono'),
                          ),
                        );
                        return;
                      }

                      final iconUrl = await _uploadIcon();
                      if (iconUrl == null) return;

                      final newModule = Module(
                        id: const Uuid().v4(),
                        name: _nameController.text,
                        description: _descriptionController.text,
                        icon: iconUrl,
                        routePath: _routePathController.text,
                        isActive: true,
                        createdAt: DateTime.now(),
                      );

                      try {
                        // Guardar en Supabase
                        await Supabase.instance.client
                            .from('modules')
                            .insert({
                              'id': newModule.id,
                              'name': newModule.name,
                              'description': newModule.description,
                              'icon': newModule.icon,
                              'route_path': newModule.routePath,
                              'is_active': newModule.isActive,
                              'created_at': newModule.createdAt.toIso8601String(),
                            });

                        setState(() {
                          _modules.add(newModule);
                        });
                        Navigator.pop(context);

                        if (mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Módulo creado'),
                                ],
                              ),
                              content: Text('El módulo ${newModule.name} ha sido creado exitosamente'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al guardar el módulo: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditModuleDialog(BuildContext context, Module module) {
    _nameController.text = module.name;
    _descriptionController.text = module.description ?? '';
    _routePathController.text = module.routePath ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Módulo'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                TextFormField(
                  controller: _routePathController,
                  decoration: const InputDecoration(
                    labelText: 'Ruta',
                    helperText: 'Ejemplo: /home, /profile',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una ruta';
                    }
                    return null;
                  },
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
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final updatedModule = Module(
                    id: module.id,
                    name: _nameController.text,
                    description: _descriptionController.text,
                    icon: module.icon,
                    routePath: _routePathController.text,
                    isActive: module.isActive,
                    createdAt: module.createdAt,
                  );

                  // Actualizar en la base de datos
                  await Supabase.instance.client
                      .from('modules')
                      .update({
                        'name': updatedModule.name,
                        'description': updatedModule.description,
                        'route_path': updatedModule.routePath,
                      })
                      .eq('id', module.id);

                  // Actualizar en la lista local
                  setState(() {
                    final index = _modules.indexWhere((m) => m.id == module.id);
                    if (index != -1) {
                      _modules[index] = updatedModule;
                    }
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Módulo "${updatedModule.name}" actualizado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar el módulo: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Module module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Módulo'),
        content: Text('¿Estás seguro de eliminar el módulo "${module.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Eliminar de la base de datos
                final response = await Supabase.instance.client
                    .from('modules')
                    .delete()
                    .eq('id', module.id)
                    .select();

                if (response != null && response.isNotEmpty) {
                  // Eliminar de la lista local
                  setState(() {
                    _modules.removeWhere((m) => m.id == module.id);
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Módulo "${module.name}" eliminado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo eliminar el módulo. Intente nuevamente.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Error al eliminar módulo: $e'); // Para debugging
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar el módulo: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              Navigator.pop(context);
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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _routePathController.dispose();
    super.dispose();
  }
} 