class Module {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? routePath;
  final bool isActive;
  final DateTime createdAt;

  Module({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.routePath,
    required this.isActive,
    required this.createdAt,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      routePath: json['route_path'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'route_path': routePath,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 