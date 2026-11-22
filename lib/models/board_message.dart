import 'package:cloud_firestore/cloud_firestore.dart';

class BoardMessage {
  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const BoardMessage({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BoardMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Message document does not exist.');
    }

    return BoardMessage(
      id: document.id,
      text: data['text'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}
