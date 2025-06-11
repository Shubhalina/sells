import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService() : _supabase = Supabase.instance.client;

  // Get the current user's profile
  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle()
        .execute();

    if (response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    
    // Fallback to auth metadata if no profile exists
    return {
      'full_name': user.userMetadata?['full_name'],
      'email': user.email,
      'phone': user.userMetadata?['phone'],
    };
  }

  // Create or update a profile
  Future<void> upsertProfile({
    required String fullName,
    String? description,
    String? phone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Update auth metadata
    await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      ),
    );

    // Update profiles table
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'description': description,
      'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    }).execute();
  }

  // Create profile during signup
  Future<void> createProfileOnSignup({
    required String userId,
    required String fullName,
    required String email,
    String? phone,
  }) async {
    await _supabase.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    }).execute();
  }
}