import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // AuthGate handles navigation automatically.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = switch (e.code) {
          'invalid-email' => 'Enter a valid email address.',
          'invalid-credential' ||
          'wrong-password' ||
          'user-not-found' => 'Incorrect email or password.',
          'too-many-requests' => 'Too many attempts. Please try again later.',
          'network-request-failed' => 'Network error. Check your connection.',
          _ => 'Sign-in failed. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred.';
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
      appBar: AppBar(title: const Text('Message Board Login')),
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
                    Icons.forum_rounded,
                    size: 80,
                    color: Colors.lightBlueAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(email)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text("Don't have an account? Register"),
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
