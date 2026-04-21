import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;
  final bool isMe;

  const AudioPlayerWidget({
    super.key,
    this.audioUrl,
    this.isMe = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playing = false;
  bool _ready = false;
  Duration _pos = Duration.zero;
  Duration _total = const Duration(seconds: 30);
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _player.openPlayer().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _toggle() async {
    if (!_ready) return;
    if (_playing) {
      await _player.pausePlayer();
      setState(() => _playing = false);
    } else {
      await _player.startPlayer(
        fromURI: widget.audioUrl,
        whenFinished: () {
          if (mounted) {
            setState(() {
              _playing = false;
              _pos = Duration.zero;
            });
          }
        },
      );
      _sub = _player.onProgress?.listen((e) {
        if (mounted) {
          setState(() {
            _pos = e.position;
            _total = e.duration;
          });
        }
      });
      setState(() => _playing = true);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _total.inMilliseconds.toDouble() > 0
        ? _total.inMilliseconds.toDouble()
        : 1.0;
    final posMs = _pos.inMilliseconds.toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: const BoxConstraints(minWidth: 200),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF00A884).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: widget.isMe ? Colors.white : const Color(0xFF00A884),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor:
                    widget.isMe ? Colors.white : const Color(0xFF00A884),
                inactiveTrackColor: widget.isMe
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFF2A3942),
                thumbColor:
                    widget.isMe ? Colors.white : const Color(0xFF00A884),
              ),
              child: Slider(
                value: posMs > totalMs ? totalMs : posMs,
                max: totalMs,
                onChanged: _ready
                    ? (v) =>
                        _player.seekToPlayer(Duration(milliseconds: v.toInt()))
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _playing ? _fmt(_pos) : _fmt(_total),
            style: TextStyle(
              color: widget.isMe
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF8696A0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
