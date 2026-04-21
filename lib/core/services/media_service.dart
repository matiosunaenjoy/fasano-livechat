import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/message_model.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;

  Future<bool> _requestCamera() async {
    final s = await Permission.camera.request();
    return s.isGranted;
  }

  Future<bool> _requestMic() async {
    final s = await Permission.microphone.request();
    return s.isGranted;
  }

  Future<File?> takePhoto() async {
    if (!await _requestCamera()) return null;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 90,
    );
    if (picked == null) return null;
    return _compressImage(File(picked.path));
  }

  Future<List<File>> pickImages() async {
    final picked = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 90,
    );
    final files = <File>[];
    for (final img in picked) {
      files.add(await _compressImage(File(img.path)));
    }
    return files;
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final target = path.join(
      dir.path,
      'cmp_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      quality: 70,
      minWidth: 1024,
      minHeight: 768,
    );
    return result != null ? File(result.path) : file;
  }

  Future<File?> recordVideo() async {
    if (!await _requestCamera()) return null;
    final picked = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<File?> pickVideo() async {
    final picked = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<void> initRecorder() async {
    if (_recorderInitialized) return;
    if (!await _requestMic()) throw Exception('Sin permiso de micrófono');
    await _recorder.openRecorder();
    _recorderInitialized = true;
  }

  Future<void> startRecording() async {
    await initRecorder();
    final dir = await getTemporaryDirectory();
    _recordingPath = path.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.aac',
    );
    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacADTS,
      bitRate: 128000,
      sampleRate: 44100,
    );
    _isRecording = true;
  }

  Future<File?> stopRecording() async {
    if (!_isRecording) return null;
    await _recorder.stopRecorder();
    _isRecording = false;
    if (_recordingPath != null) return File(_recordingPath!);
    return null;
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stopRecorder();
      _isRecording = false;
      if (_recordingPath != null) {
        final f = File(_recordingPath!);
        if (await f.exists()) await f.delete();
      }
      _recordingPath = null;
    }
  }

  bool get isRecording => _isRecording;

  Future<File?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'xls', 'xlsx',
        'ppt', 'pptx', 'txt', 'csv', 'zip',
      ],
    );
    if (result == null || result.files.isEmpty) return null;
    return File(result.files.first.path!);
  }

  MessageType getMessageType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      return MessageType.image;
    }
    if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) {
      return MessageType.video;
    }
    if (['.mp3', '.aac', '.m4a', '.wav'].contains(ext)) {
      return MessageType.audio;
    }
    return MessageType.document;
  }

  void dispose() {
    if (_recorderInitialized) _recorder.closeRecorder();
  }
}

final mediaService = MediaService();
