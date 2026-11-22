import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await _authService.register(
        email: _email.text,
        password: _password.text,
      );

      final user = credential.user;

      if (user == null) {
        throw StateError('Registration did not return a user.');
      }

      await _userService.saveUserRecord(
        uid: user.uid,
        firstName: _firstName.text,
        lastName: _lastName.text,
      );

      // The profile has been saved successfully.
      // AuthGate will handle the signed-in destination.
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' => 'An account already uses this email.',
          'weak-password' => 'Please choose a stronger password.',
          'invalid-email' => 'Enter a valid email address.',
          'network-request-failed' => 'Network error. Check your connection.',
          _ => 'Registration failed. Please try again.',
        };
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'Registration could not be completed. '
            'Please check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 70,
                    color: Colors.lightBlueAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Join Message Board',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'First name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Last name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(email)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Register'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
