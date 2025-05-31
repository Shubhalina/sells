import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sells/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final contactController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
  emailController.dispose();
  passwordController.dispose();
  confirmPasswordController.dispose();
  nameController.dispose();
  addressController.dispose();
  contactController.dispose();
  super.dispose();
}

DateTime? _lastSignUpAttempt; // Add this to your state class
bool _isSigningUp = false; // Add this to your state class

void signUp() async {
  final now = DateTime.now();
  
  // Check if enough time has passed since last attempt
  if (_lastSignUpAttempt != null && 
      now.difference(_lastSignUpAttempt!).inSeconds < 60) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please wait a minute before trying again")),
    );
    return;
  }

  _lastSignUpAttempt = now;
  if (_isSigningUp) return; // Prevent multiple clicks
  
  setState(() => _isSigningUp = true);
  
  final email = emailController.text.trim();
  final password = passwordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();
  final name = nameController.text.trim();
  final address = addressController.text.trim();
  final contact = contactController.text.trim();

  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwords do not match")),
    );
    return;
  }

  try {
    final authService = AuthService(); // Create an instance of AuthService

    await authService.signUpWithEmail(
      email: email,
      password: password,
      name: nameController.text.trim(),
      address: addressController.text.trim(),
      contact: contactController.text.trim(),
    );
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Check your email to confirm sign up")),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Signup failed: ${e.toString()}")),
    );
  } finally {
    if (mounted) {
      setState(() => _isSigningUp = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: ListView(
          children: [
            const SizedBox(height: 60),
            const Text("Create Account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Sign up to get started",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                hintText: 'Address (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(
                hintText: 'Contact Number (Optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSigningUp ? null : signUp,
              child: _isSigningUp 
                  ? const CircularProgressIndicator()
                  : const Text("Sign Up"),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Back to login screen
                  },
                  child: const Text(
                    "Sign In",
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
