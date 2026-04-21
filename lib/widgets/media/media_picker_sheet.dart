import 'package:flutter/material.dart';

class MediaPickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onVideo;
  final VoidCallback onDocument;
  final VoidCallback onAudio;
  final VoidCallback onLocation;

  const MediaPickerSheet({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onVideo,
    required this.onDocument,
    required this.onAudio,
    required this.onLocation,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required VoidCallback onVideo,
    required VoidCallback onDocument,
    required VoidCallback onAudio,
    required VoidCallback onLocation,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MediaPickerSheet(
        onCamera: onCamera,
        onGallery: onGallery,
        onVideo: onVideo,
        onDocument: onDocument,
        onAudio: onAudio,
        onLocation: onLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF8696A0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btn(Icons.camera_alt, 'Cámara',
                    const Color(0xFFFF6B6B), () {
                  Navigator.pop(context);
                  onCamera();
                }),
                _btn(Icons.photo_library, 'Galería',
                    const Color(0xFFC06BF5), () {
                  Navigator.pop(context);
                  onGallery();
                }),
                _btn(Icons.videocam, 'Video',
                    const Color(0xFFFF9F43), () {
                  Navigator.pop(context);
                  onVideo();
                }),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btn(Icons.insert_drive_file, 'Documento',
                    const Color(0xFF54A0FF), () {
                  Navigator.pop(context);
                  onDocument();
                }),
                _btn(Icons.headphones, 'Audio',
                    const Color(0xFF1DD1A1), () {
                  Navigator.pop(context);
                  onAudio();
                }),
                _btn(Icons.location_on, 'Ubicación',
                    const Color(0xFFFF6348), () {
                  Navigator.pop(context);
                  onLocation();
                }),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _btn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8696A0), fontSize: 12)),
        ],
      ),
    );
  }
}
