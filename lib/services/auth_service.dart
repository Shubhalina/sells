import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email and password, then store user data in 'users' table
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? address,
    String? contact,
  }) async {
    try {
      // 1. Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('User registration failed');
      }

      // 2. Store additional user data in 'users' table
      final response = await _supabase.from('users').insert({
        'id': authResponse.user!.id,
        'email': email,
        'name': name,
        'address': address,
        'contact': contact,
      });

      if (response.status != 201) {
      throw Exception('Failed to store user data: ${response.status}');
    }
  } catch (e) {
    throw Exception('Failed to sign up: $e');
  }
}

  // Get current user's data from 'users' table
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Update user data in 'users' table
  Future<void> updateUserData({
    required String userId,
    String? name,
    String? address,
    String? contact,
  }) async {
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (address != null) updateData['address'] = address;
    if (contact != null) updateData['contact'] = contact;

    if (updateData.isEmpty) return;

    try {
      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }
}