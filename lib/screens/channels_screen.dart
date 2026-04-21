import 'package:flutter/material.dart';
import '../core/models/chat_model.dart';
import '../core/models/user_model.dart';
import '../core/services/service_locator.dart';
import '../theme.dart';
import 'chat_screen.dart';

class ChannelsScreen extends StatelessWidget {
  final UserModel currentUser;
  const ChannelsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatModel>>(
      stream: services.chatRepository.getChannels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00A884)),
          );
        }

        final channels = snapshot.data ?? [];

        if (channels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tag,
                    size: 64, color: const Color(0xFF8696A0).withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No hay canales',
                    style: TextStyle(color: Color(0xFF8696A0), fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, i) {
            final ch = channels[i];
            final unread = ch.unreadCounts[currentUser.uid] ?? 0;
            final color = DeptColors.forDepartment(ch.department);

            return ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chat: ch,
                    currentUser: currentUser,
                  ),
                ),
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ch.onlyAdminsCanPost ? Icons.campaign : Icons.tag,
                  color: color,
                  size: 24,
                ),
              ),
              title: Text(ch.name,
                  style:
                      const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16)),
              subtitle: Text(
                ch.lastMessageText.isNotEmpty
                    ? ch.lastMessageText
                    : ch.description.isNotEmpty
                        ? ch.description
                        : '${ch.participantIds.length} miembros',
                style: const TextStyle(color: Color(0xFF8696A0), fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: unread > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A884),
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Center(
                        child: Text(
                          unread > 99 ? '99+' : unread.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
