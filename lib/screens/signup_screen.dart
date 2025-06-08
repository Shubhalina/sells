import 'package:flutter/material.dart';
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
  final authService = AuthService();

  DateTime? _lastSignUpAttempt;
  bool _isSigningUp = false;

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

  bool _validateInputs() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email address");
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Please enter a valid email address");
      return false;
    }

    if (password.isEmpty) {
      _showSnackBar("Please enter a password");
      return false;
    }

    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters long");
      return false;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match");
      return false;
    }

    if (name.isEmpty) {
      _showSnackBar("Please enter your full name");
      return false;
    }

    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void signUp() async {
    final now = DateTime.now();
    
    // Rate limiting
    if (_lastSignUpAttempt != null && 
        now.difference(_lastSignUpAttempt!).inSeconds < 60) {
      _showSnackBar("Please wait a minute before trying again");
      return;
    }

    if (_isSigningUp) return;

    if (!_validateInputs()) return;

    _lastSignUpAttempt = now;
    setState(() => _isSigningUp = true);
    
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();
    final address = addressController.text.trim();
    final contact = contactController.text.trim();

    try {
      final result = await authService.signup(
        email: email,
        password: password,
        passwordConfirmation: confirmPassword,
        name: name,
        address: address,
        contact: contact,
      );
      
      if (!mounted) return;
      
      if (result['error']) {
        _showSnackBar(result['message']);
      } else {
        _showSnackBar("Account created successfully! You can now sign in.");
        // Navigate back to login screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Signup failed: ${e.toString()}");
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
                hintText: 'Email address *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password (min 6 characters) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm Password *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Full Name *',
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
            const SizedBox(height: 8),
            
            const Text(
              '* Required fields',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isSigningUp ? null : signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isSigningUp 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Sign Up"),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Sign In",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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