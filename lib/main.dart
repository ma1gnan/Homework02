import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/profile_gate.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';
import 'screens/board_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MessageBoardApp());
}

class MessageBoardApp extends StatelessWidget {
  const MessageBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Message Board Vault Hunt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF101827),
      ),
      home: const FirebaseStartupScreen(),
    );
  }
}

class FirebaseStartupScreen extends StatefulWidget {
  const FirebaseStartupScreen({super.key});

  @override
  State<FirebaseStartupScreen> createState() => _FirebaseStartupScreenState();
}

class _FirebaseStartupScreenState extends State<FirebaseStartupScreen> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeFirebase();
  }

  Future<FirebaseApp> _initializeFirebase() async {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _retryInitialization() {
    setState(() {
      _initialization = _initializeFirebase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FirebaseErrorScreen(onRetry: _retryInitialization);
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        return const AuthGate();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_rounded, size: 100, color: Colors.lightBlueAccent),
            SizedBox(height: 24),
            Text(
              'MESSAGE BOARD',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'VAULT HUNT',
              style: TextStyle(
                fontSize: 20,
                color: Colors.lightBlueAccent,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 35),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Firebase...'),
          ],
        ),
      ),
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const FirebaseErrorScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Firebase Initialization Failed',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to initialize Firebase. '
                'Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Authentication error')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          return ProfileGate(user: snapshot.data!, board: const BoardScreen());
        }

        return const LoginScreen();
      },
    );
  }
}

class LoginPlaceholderScreen extends StatelessWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.lightBlueAccent),
            SizedBox(height: 20),
            Text(
              'Welcome to Message Board',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text('Please sign in to continue.'),
          ],
        ),
      ),
    );
  }
}
