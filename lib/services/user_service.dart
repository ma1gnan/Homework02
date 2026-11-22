import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveUserRecord({
    required String uid,
    required String firstName,
    required String lastName,
  }) async {
    final first = firstName.trim();
    final last = lastName.trim();

    if (uid.isEmpty || first.isEmpty || last.isEmpty) {
      throw ArgumentError('User information is incomplete.');
    }

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'firstName': first,
      'lastName': last,
      'role': 'member',
      'registeredAt': FieldValue.serverTimestamp(),
    });
  }
}
