class UserRole {
  final String id;
  final String name;
  final String? description;
  final bool isDefault;
  final List<String> moduleIds; // IDs de los módulos a los que tiene acceso

  UserRole({
    required this.id,
    required this.name,
    this.description,
    required this.isDefault,
    required this.moduleIds,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      moduleIds: (json['module_ids'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_default': isDefault,
      'module_ids': moduleIds,
    };
  }
} 