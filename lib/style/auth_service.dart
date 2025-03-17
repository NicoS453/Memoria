import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        return response; // Return if login is successful
      } else {
        throw Exception("Email atau password salah.");
      }
    } catch (e) {
      rethrow; // Rethrow error to be caught in login screen
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmailPassword(String email, String password, String username) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // Insert ke tabel profile
      try {
        final profileInsertResponse = await Supabase.instance.client
            .from('profile')
            .insert({
          'id': response.user?.id,
          'email': email,
          'username': username,
        })
            .select();

      } catch (e) {
        debugPrint('Error saat menyimpan profile: $e');
        return AuthResult.error('Terjadi kesalahan saat menyimpan profile.');
      }

      return AuthResult.success(response);
    } on AuthException catch (e) {
      debugPrint('Sign-up gagal: ${e.message}');
      return AuthResult.error(e.message ?? 'Kesalahan autentikasi.');
    } catch (e) {
      debugPrint('Kesalahan tidak terduga: $e');
      return AuthResult.error('Kesalahan tidak terduga. Coba lagi.');
    }
  }


  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }

  /// Get the current user's email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}

/// Helper class to return results
class AuthResult {
  final bool success;
  final dynamic data;
  final String? error;

  AuthResult._({required this.success, this.data, this.error});

  factory AuthResult.success(dynamic data) => AuthResult._(success: true, data: data);
  factory AuthResult.error(String error) => AuthResult._(success: false, error: error);
}
