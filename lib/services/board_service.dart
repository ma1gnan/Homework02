import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/board_message.dart';

class BoardService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BoardService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection('messages');

  User _requireUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    return user;
  }

  String _validateText(String text) {
    final cleaned = text.trim();

    if (cleaned.isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }

    if (cleaned.length > 500) {
      throw ArgumentError('Message cannot exceed 500 characters.');
    }

    return cleaned;
  }

  // CREATE
  Future<void> createMessage(String text) async {
    final user = _requireUser();
    final cleaned = _validateText(text);

    final profile = await _firestore.collection('users').doc(user.uid).get();

    if (!profile.exists) {
      throw StateError('Your user profile is missing.');
    }

    final data = profile.data()!;

    final firstName = data['firstName'] as String;
    final lastName = data['lastName'] as String;
    final authorName = '$firstName $lastName'.trim();

    await _messages.add({
      'text': cleaned,
      'authorId': user.uid,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // READ: live Firestore stream
  Stream<List<BoardMessage>> watchMessages() {
    _requireUser();

    return _messages
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(BoardMessage.fromFirestore).toList(),
        );
  }

  // UPDATE
  Future<void> updateMessage({
    required String messageId,
    required String newText,
  }) async {
    final user = _requireUser();
    final cleaned = _validateText(newText);

    final reference = _messages.doc(messageId);
    final document = await reference.get();

    if (!document.exists) {
      throw StateError('Message not found.');
    }

    if (document.data()?['authorId'] != user.uid) {
      throw StateError('You can only edit your own messages.');
    }

    await reference.update({
      'text': cleaned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // DELETE
  Future<void> deleteMessage(String messageId) async {
    final user = _requireUser();

    final reference = _messages.doc(messageId);
    final document = await reference.get();

    if (!document.exists) {
      throw StateError('Message not found.');
    }

    if (document.data()?['authorId'] != user.uid) {
      throw StateError('You can only delete your own messages.');
    }

    await reference.delete();
  }
}
