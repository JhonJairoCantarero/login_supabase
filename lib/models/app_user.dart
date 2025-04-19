class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    this.lastSignInAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'] ?? 'user',
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      lastSignInAt: json['last_sign_in_at'] != null 
          ? DateTime.parse(json['last_sign_in_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'last_sign_in_at': lastSignInAt?.toIso8601String(),
  };
}