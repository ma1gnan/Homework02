import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileGate extends StatelessWidget {
  final User user;
  final Widget board;

  const ProfileGate({super.key, required this.user, required this.board});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to load your profile. '
                'Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final document = snapshot.data!;

        if (!document.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile Setup')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your account exists, but your '
                      'Firestore profile is not ready.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = document.data();

        if (data == null ||
            data['uid'] != user.uid ||
            data['firstName'] is! String ||
            data['lastName'] is! String ||
            data['role'] != 'member' ||
            data['registeredAt'] is! Timestamp) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Your profile is incomplete.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return board;
      },
    );
  }
}
