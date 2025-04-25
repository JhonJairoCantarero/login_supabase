import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:ylapp/models/app_user.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Método para mostrar diálogo de éxito
  void _showSuccessDialog(BuildContext context, String title, String message, {VoidCallback? onOk}) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: onOk,
      btnOkColor: Colors.green,
      autoHide: const Duration(seconds: 3),
    ).show();
  }

  // Método para mostrar diálogo de error
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // ==================== REGISTRO ====================
  Future<AuthResponse> registerWithEmailPassword({
    required BuildContext context,
    required String email,
    required String password,
    String? fullName,
    String? avatarUrl,
    String role = 'user',
  }) async {
    try {
      // 1. Registrar usuario en Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'avatar_url': avatarUrl,
          'email_verified': false,
        },
        emailRedirectTo: kIsWeb ? null : 'tu-app://verify-email',
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception("Error al registrar usuario en autenticación");
      }

      // 2. Actualizar perfil del usuario ya insertado automáticamente por el trigger
      final updateResponse = await _supabase
          .from('profiles')
          .update({
            'full_name': fullName,
            'avatar_url': avatarUrl,
            'preferences': {'theme': 'light', 'language': 'es'},
            'role': role,
          })
          .eq('user_id', user.id);

      // Verificar si la actualización fue exitosa
      if (updateResponse == null) {
        print('Warning: La actualización del perfil podría no haberse completado');
      }

      _showSuccessDialog(
        context,
        'Registro exitoso',
        'Se ha enviado un correo de verificación a $email',
      );

      return authResponse;
    } catch (e) {
      // Si el error es específico de Supabase, lo propagamos
      if (e is AuthException) {
        _showErrorDialog(context, 'Error en el registro', e.message);
        throw Exception(e.message);
      }
      // Para otros errores, los propagamos con un mensaje más descriptivo
      _showErrorDialog(context, 'Error en el registro', e.toString());
      throw Exception('Error durante el registro: ${e.toString()}');
    }
  }

  // ==================== INICIO DE SESIÓN ====================
  Future<AuthResponse> signInWithEmailPassword({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception("Credenciales incorrectas");
      }

      _showSuccessDialog(
        context,
        'Inicio de sesión exitoso',
        'Bienvenido ${response.user?.email}',
      );

      return response;
    } catch (e) {
      _showErrorDialog(context, 'Error en inicio de sesión', e.toString());
      throw Exception('Error en inicio de sesión: ${e.toString()}');
    }
  }

  // ==================== OBTENER ROL ====================
  Future<String> getUserRole() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .single();

      return response['role'] as String;
    } catch (e) {
      throw Exception('Error al obtener rol: ${e.toString()}');
    }
  }

  // ==================== LISTA DE USUARIOS (ADMIN) ====================
  Future<List<AppUser>> getUsersList() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            user_id,
            full_name,
            role,
            avatar_url,
            preferences,
            user:users(
              email,
              created_at,
              last_sign_in_at
            )
          ''')
          .order('user_id', ascending: false);

      if (response == null) {
        throw Exception('La respuesta de la consulta fue nula');
      }

      return response.map<AppUser>((profile) {
        final userData = profile['user'] as Map<String, dynamic>? ?? {};
        
        // Conversión segura de fechas
        DateTime? parseDate(dynamic date) {
          if (date == null) return null;
          if (date is DateTime) return date;
          if (date is String) return DateTime.tryParse(date);
          return null;
        }

        // Validación esencial de campos requeridos
        final userId = profile['user_id']?.toString();
        final email = userData['email']?.toString();
        
        if (userId == null || userId.isEmpty || email == null) {
          throw Exception('Datos de usuario incompletos');
        }

        return AppUser.fromJson({
          'id': userId,
          'email': email,
          'full_name': profile['full_name']?.toString(),
          'role': profile['role']?.toString() ?? 'user',
          'avatar_url': profile['avatar_url']?.toString(),
          'created_at': parseDate(userData['created_at'])?.toIso8601String(),
          'last_sign_in_at': parseDate(userData['last_sign_in_at'])?.toIso8601String(),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error en getUsersList: $e');
      throw Exception('Error al obtener usuarios: ${e.toString()}');
    }
  }

  // ==================== ACTUALIZAR ROL (ADMIN) ====================
  Future<void> updateUserRole(BuildContext context, String userId, String newRole) async {
    try {
      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('user_id', userId);
      
      _showSuccessDialog(
        context,
        'Rol actualizado',
        'El rol ha sido actualizado exitosamente',
      );
    } catch (e) {
      _showErrorDialog(context, 'Error al actualizar rol', e.toString());
      throw 'Error: ${e.toString().replaceFirst('Exception: ', '')}';
    }
  }

  // ==================== OBTENER PERFIL ACTUAL ====================
  Future<AppUser> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('profiles')
          .select('''
            *, 
            users(
              email, 
              created_at,
              last_sign_in_at
            )
          ''')
          .eq('user_id', userId)
          .single();

      return AppUser.fromJson({
        'id': userId,
        'email': response['users']['email'] ?? '',
        'full_name': response['full_name'],
        'role': response['role']?.toString().toLowerCase() ?? 'user',
        'avatar_url': response['avatar_url'],
        'created_at': response['users']['created_at'],
        'last_sign_in_at': response['users']['last_sign_in_at'],
      });
    } catch (e) {
      debugPrint('Error en getCurrentUserProfile: $e');
      throw Exception('Error al obtener perfil: ${e.toString()}');
    }
  }

  // ==================== ACTUALIZAR PERFIL ====================
  Future<void> updateProfile({
    required BuildContext context,
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (preferences != null) updates['preferences'] = preferences;

      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('user_id', userId);

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      _showSuccessDialog(
        context,
        'Perfil actualizado',
        'Tu perfil ha sido actualizado exitosamente',
      );
    } catch (e) {
      _showErrorDialog(context, 'Error al actualizar perfil', e.toString());
      throw Exception('Error al actualizar perfil: ${e.toString()}');
    }
  }

  // ==================== VERIFICAR EMAIL ====================
  Future<void> sendEmailVerification(BuildContext context) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.emailConfirmedAt != null) return;

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
        emailRedirectTo: kIsWeb ? null : 'tu-app://verify-email',
      );

      _showSuccessDialog(
        context,
        'Email enviado',
        'Se ha enviado un correo de verificación a ${user.email}',
      );
    } catch (e) {
      _showErrorDialog(context, 'Error al enviar verificación', e.toString());
      throw Exception("Error al enviar verificación: ${e.toString()}");
    }
  }

  // ==================== CERRAR SESIÓN ====================
  Future<void> signOut(BuildContext context) async {
    try {
      await _supabase.auth.signOut();
      _showSuccessDialog(
        context,
        'Sesión cerrada',
        'Has cerrado sesión exitosamente',
      );
    } catch (e) {
      _showErrorDialog(context, 'Error al cerrar sesión', e.toString());
      throw Exception("Error al cerrar sesión: ${e.toString()}");
    }
  }

  // ==================== PROPIEDADES ====================
  String? get currentUserEmail => _supabase.auth.currentUser?.email;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  bool get isLoggedIn => _supabase.auth.currentSession != null;
  bool get isEmailVerified => _supabase.auth.currentUser?.emailConfirmedAt != null;

  // ==================== STREAM DE CAMBIOS DE AUTENTICACIÓN ====================
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}