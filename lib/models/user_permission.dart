class UserPermission {
  final String id;
  final String name;
  final String? description;
  final String moduleId;

  UserPermission({
    required this.id,
    required this.name,
    this.description,
    required this.moduleId,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      moduleId: json['module_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'module_id': moduleId,
    };
  }
} 