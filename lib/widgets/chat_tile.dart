import 'package:flutter/material.dart';
import '../core/models/chat_model.dart';
import '../theme.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCounts[currentUserId] ?? 0;
    final isPinned = chat.pinnedBy[currentUserId] == true;
    final isMuted = chat.mutedBy[currentUserId] == true;
    final color = DeptColors.forDepartment(
        chat.department.isNotEmpty ? chat.department : 'general');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: chat.isDirect
                  ? color
                  : color.withOpacity(0.15),
              child: chat.isDirect
                  ? Text(_initials(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600))
                  : Icon(chat.typeIcon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name.isNotEmpty ? chat.name : 'Chat',
                    style: const TextStyle(
                      color: Color(0xFFE9EDEF),
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (chat.lastMessageSenderName.isNotEmpty &&
                          !chat.isDirect)
                        Text(
                          '${chat.lastMessageSenderName}: ',
                          style: const TextStyle(
                              color: Color(0xFF8696A0),
                              fontSize: 13),
                        ),
                      if (chat.lastMessageIsFile)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.attach_file,
                              size: 14,
                              color: Color(0xFF8696A0)),
                        ),
                      Expanded(
                        child: Text(
                          chat.lastMessageText,
                          style: const TextStyle(
                              color: Color(0xFF8696A0),
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _time(chat.lastMessageTime),
                  style: TextStyle(
                    color: unread > 0
                        ? const Color(0xFF00A884)
                        : const Color(0xFF8696A0),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMuted)
                      const Icon(Icons.volume_off,
                          size: 14, color: Color(0xFF8696A0)),
                    if (isPinned)
                      const Icon(Icons.push_pin,
                          size: 14, color: Color(0xFF8696A0)),
                    if (unread > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A884),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            unread > 99
                                ? '99+'
                                : unread.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials() {
    final name = chat.participantNames.values
        .where((n) => n.isNotEmpty)
        .firstOrNull ?? '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _time(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      const d = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return d[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}
