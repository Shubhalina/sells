import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sells/services/profile_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://rjqavgdehdvrrjxovlqt.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqcWF2Z2RlaGR2cnJqeG92bHF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYxODQ2MjUsImV4cCI6MjA2MTc2MDYyNX0.NHRzW-ubHkacGvbQnp4hbxdSi5ZA2VdgUa-i-6GX1Z4',
    );
  }

  // Sign Up User
  Future<Map<String, dynamic>> signup({
    required String name,
    required String contact,
    required String address,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      // Validate input
      if (password != passwordConfirmation) {
        return {
          'error': true,
          'message': 'Passwords do not match',
        };
      }

      if (password.length < 6) {
        return {
          'error': true,
          'message': 'Password must be at least 6 characters long',
        };
      }

      if (name.trim().isEmpty) {
        return {
          'error': true,
          'message': 'Name is required',
        };
      }

      // Register user with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {
          'error': true,
          'message': 'Failed to create account. Please try again.',
        };
      }

      // Store additional user data in the users table
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'contact': contact.trim().isEmpty ? null : contact.trim(),
        'address': address.trim().isEmpty ? null : address.trim(),
      });

      return {
        'error': false,
        'message': 'Account created successfully!',
        'user': response.user,
      };
    } catch (e) {
      debugPrint('Signup error: $e');
      
      if (e is AuthException) {
        String message = e.message;
        
        // Handle common Supabase auth errors
        if (message.contains('already registered')) {
          message = 'An account with this email already exists';
        } else if (message.contains('invalid email')) {
          message = 'Please enter a valid email address';
        } else if (message.contains('weak password')) {
          message = 'Password is too weak. Please choose a stronger password';
        }
        
        return {
          'error': true,
          'message': message,
        };
      }
      
      // Handle PostgrestException (database errors)
      if (e is PostgrestException) {
        String message = 'Database error occurred';
        
        if (e.message.contains('duplicate key')) {
          message = 'An account with this email already exists';
        }
        
        return {
          'error': true,
          'message': message,
        };
      }
      
      return {
        'error': true,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Sign In User
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.trim().isEmpty || password.trim().isEmpty) {
        return {
          'error': true,
          'message': 'Email and password are required',
        };
      }

final response = await _supabase.auth.signInWithPassword(
  email: email,
  password: password,
);


      if (response.user == null) {
        return {
          'error': true,
          'message': 'Invalid email or password',
        };
      }

      return {
        'error': false,
        'message': 'Login successful',
        'user': response.user,
      };
    } catch (e) {
      debugPrint('Login error: $e');
      
      if (e is AuthException) {
        String message = e.message;
        
        // Handle common login errors
        if (message.contains('Invalid login credentials')) {
          message = 'Invalid email or password';
        } else if (message.contains('Email not confirmed')) {
          message = 'Please check your email and confirm your account';
        } else if (message.contains('too many requests')) {
          message = 'Too many login attempts. Please try again later';
        }
        
        return {
          'error': true,
          'message': message,
        };
      }
      
      return {
        'error': true,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Sign Out User
  Future<Map<String, dynamic>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return {
        'error': false,
        'message': 'Signed out successfully',
      };
    } catch (e) {
      debugPrint('Sign out error: $e');
      return {
        'error': true,
        'message': 'Failed to sign out. Please try again.',
      };
    }
  }


  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Get user profile data from the users table
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  // Password Reset
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      if (email.trim().isEmpty) {
        return {
          'error': true,
          'message': 'Email is required',
        };
      }

      await _supabase.auth.resetPasswordForEmail(email.trim().toLowerCase());
      return {
        'error': false,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } catch (e) {
      debugPrint('Password reset error: $e');
      
      if (e is AuthException) {
        return {
          'error': true,
          'message': e.message,
        };
      }
      
      return {
        'error': true,
        'message': 'Failed to send password reset email. Please try again.',
      };
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}