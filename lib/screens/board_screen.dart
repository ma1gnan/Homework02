import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/board_message.dart';
import '../services/auth_service.dart';
import '../services/board_service.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final BoardService _boardService = BoardService();
  final AuthService _authService = AuthService();

  final TextEditingController _messageController = TextEditingController();

  late final Stream<List<BoardMessage>> _messageStream;

  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _messageStream = _boardService.watchMessages();
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to sign out: $error')));
    }
  }

  Future<void> _postMessage() async {
    if (_posting) return;

    final text = _messageController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message.')));
      return;
    }

    setState(() {
      _posting = true;
    });

    try {
      await _boardService.createMessage(text);

      if (!mounted) return;

      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message posted successfully!')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to post message: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
  }

  Future<void> _editMessage(BoardMessage message) async {
    final controller = TextEditingController(text: message.text);

    final updatedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!mounted || updatedText == null) return;

    try {
      await _boardService.updateMessage(
        messageId: message.id,
        newText: updatedText,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Message updated!')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $error')));
    }
  }

  Future<void> _deleteMessage(BoardMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await _boardService.deleteMessage(message.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Message deleted!')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Syncing...';
    }

    final date = timestamp.toDate().toLocal();

    return '${date.month}/${date.day}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<BoardMessage>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Firestore error:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 70,
                          color: Colors.lightBlueAccent,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Be the first to post a message!'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    final isOwner =
                        message.authorId ==
                        FirebaseAuth.instance.currentUser?.uid;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.account_circle,
                                  color: Colors.lightBlueAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    message.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isOwner) ...[
                                  IconButton(
                                    tooltip: 'Edit Message',
                                    onPressed: () => _editMessage(message),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete Message',
                                    onPressed: () => _deleteMessage(message),
                                    icon: const Icon(Icons.delete),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 12),
                            Text(
                              message.text,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatDate(message.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message composer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_posting,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _posting ? null : _postMessage,
                  child: _posting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
