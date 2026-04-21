import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/media_service.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(File, Duration) onSend;
  final VoidCallback onCancel;

  const AudioRecorderWidget({
    super.key,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<AudioRecorderWidget> createState() =>
      _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Duration _dur = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _start();
  }

  Future<void> _start() async {
    try {
      await mediaService.startRecording();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _dur += const Duration(seconds: 1));
      });
    } catch (_) {
      widget.onCancel();
    }
  }

  Future<void> _send() async {
    _timer?.cancel();
    final file = await mediaService.stopRecording();
    if (file != null) widget.onSend(file, _dur);
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await mediaService.cancelRecording();
    widget.onCancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancel,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFFF4444),
                          const Color(0xFFFF4444).withOpacity(0.3),
                          _pulse.value,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...List.generate(
                    20,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 3,
                      height: 8.0 + (i % 4) * 4.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A884),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_dur.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_dur.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: Color(0xFFE9EDEF), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF00A884),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
