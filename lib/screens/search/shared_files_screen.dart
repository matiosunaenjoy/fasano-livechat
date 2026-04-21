import 'package:flutter/material.dart';
import '../../core/models/message_model.dart';
import '../../core/services/service_locator.dart';

class SharedFilesScreen extends StatelessWidget {
  final String chatId;
  final String chatName;

  const SharedFilesScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archivos de $chatName',
            style: const TextStyle(color: Color(0xFFE9EDEF))),
      ),
      body: FutureBuilder<List<MessageModel>>(
        future: services.messageRepository.getSharedFiles(chatId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF00A884)),
            );
          }
          final files = snapshot.data ?? [];
          if (files.isEmpty) {
            return const Center(
              child: Text('No hay archivos compartidos',
                  style: TextStyle(color: Color(0xFF8696A0))),
            );
          }
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, i) {
              final m = files[i];
              final a = m.attachment!;
              return ListTile(
                leading: Icon(a.icon, color: const Color(0xFF00A884)),
                title: Text(a.fileName,
                    style: const TextStyle(
                        color: Color(0xFFE9EDEF), fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    '${m.senderName} · ${a.sizeLabel}',
                    style: const TextStyle(
                        color: Color(0xFF8696A0), fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.download,
                      color: Color(0xFF00A884)),
                  onPressed: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
