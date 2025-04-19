class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String? avatarUrl;
  final String? createdAt; // Ahora como String
  final String? lastSignInAt; // Ahora como String

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.avatarUrl,
    this.createdAt,
    this.lastSignInAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] as String?,
      lastSignInAt: json['last_sign_in_at'] as String?,
    );
  }
}