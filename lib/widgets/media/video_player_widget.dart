import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<VideoPlayerWidget> createState() =>
      _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _video;
  ChewieController? _chewie;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl));
    _video.initialize().then((_) {
      _chewie = ChewieController(
        videoPlayerController: _video,
        autoPlay: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF00A884),
          handleColor: const Color(0xFF00A884),
          backgroundColor: const Color(0xFF2A3942),
        ),
      );
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _video.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        width: 250,
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
              color: Color(0xFF00A884)),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _video.value.aspectRatio,
      child: Chewie(controller: _chewie!),
    );
  }
}

class VideoThumbnailWidget extends StatelessWidget {
  final String? thumbnailUrl;
  final VoidCallback onTap;

  const VideoThumbnailWidget({
    super.key,
    this.thumbnailUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF111B21),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox()),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
