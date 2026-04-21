import 'package:flutter/material.dart';
import '../core/models/chat_model.dart';
import '../core/models/user_model.dart';
import '../core/services/service_locator.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatelessWidget {
  final UserModel currentUser;
  const ChatsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatModel>>(
      stream:
          services.chatRepository.getUserChats(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF00A884)),
          );
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64,
                    color: const Color(0xFF8696A0)
                        .withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No hay conversaciones',
                    style: TextStyle(
                        color: Color(0xFF8696A0), fontSize: 16)),
                const SizedBox(height: 8),
                const Text(
                    'Inicia un chat desde el directorio',
                    style: TextStyle(
                        color: Color(0xFF8696A0), fontSize: 13)),
              ],
            ),
          );
        }

        final pinned = chats
            .where(
                (c) => c.pinnedBy[currentUser.uid] == true)
            .toList();
        final normal = chats
            .where(
                (c) => c.pinnedBy[currentUser.uid] != true)
            .toList();

        return ListView(
          children: [
            if (pinned.isNotEmpty) ...[
              const _Header(label: 'FIJADOS'),
              ...pinned.map((c) => ChatTile(
                    chat: c,
                    currentUserId: currentUser.uid,
                    onTap: () => _open(context, c),
                  )),
            ],
            ...normal.map((c) => ChatTile(
                  chat: c,
                  currentUserId: currentUser.uid,
                  onTap: () => _open(context, c),
                )),
          ],
        );
      },
    );
  }

  void _open(BuildContext context, ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chat: chat,
          currentUser: currentUser,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  const _Header({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(label,
          style: const TextStyle(
            color: Color(0xFF00A884),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          )),
    );
  }
}
