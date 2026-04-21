import 'package:flutter/material.dart';
import '../../core/models/message_model.dart';

class UploadProgressWidget extends StatelessWidget {
  final double progress;
  final String fileName;
  final MessageType type;
  final VoidCallback? onCancel;

  const UploadProgressWidget({
    super.key,
    required this.progress,
    required this.fileName,
    required this.type,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF202C33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  backgroundColor: _color().withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(_color()),
                ),
                Icon(_icon(), color: _color(), size: 20),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    style: const TextStyle(
                        color: Color(0xFFE9EDEF), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${(progress * 100).toInt()}% subido',
                    style: const TextStyle(
                        color: Color(0xFF8696A0), fontSize: 12)),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close,
                  color: Color(0xFF8696A0), size: 20),
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (type) {
      case MessageType.image:
        return Icons.image;
      case MessageType.video:
        return Icons.videocam;
      case MessageType.audio:
        return Icons.headphones;
      case MessageType.document:
        return Icons.insert_drive_file;
      default:
        return Icons.file_present;
    }
  }

  Color _color() {
    switch (type) {
      case MessageType.image:
        return const Color(0xFFC06BF5);
      case MessageType.video:
        return const Color(0xFFFF9F43);
      case MessageType.audio:
        return const Color(0xFF1DD1A1);
      case MessageType.document:
        return const Color(0xFF54A0FF);
      default:
        return const Color(0xFF8696A0);
    }
  }
}
