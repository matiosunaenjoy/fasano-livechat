import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/models/chat_model.dart';
import '../core/models/message_model.dart';
import '../core/models/user_model.dart';
import '../core/services/service_locator.dart';
import '../core/services/media_service.dart';
import '../core/services/notification_service.dart';
import '../theme.dart';
import '../widgets/media/media_picker_sheet.dart';
import '../widgets/media/audio_recorder_widget.dart';
import '../widgets/media/image_preview_screen.dart';
import '../widgets/media/video_player_widget.dart';
import '../widgets/media/audio_player_widget.dart';
import '../widgets/media/upload_progress_widget.dart';
import 'search/chat_search_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  final UserModel currentUser;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  StreamSubscription<List<MessageModel>>? _sub;
  List<MessageModel> _messages = [];
  MessageModel? _replyTo;
  bool _isTyping = false;
  bool _isRecording = false;
  bool _sendingMedia = false;
  double _uploadProgress = 0;
  String _uploadFileName = '';
  MessageType _uploadType = MessageType.text;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    notificationService.setActiveChat(widget.chat.id);
    _sub = services.messageRepository
        .getMessages(widget.chat.id)
        .listen((msgs) {
      setState(() => _messages = msgs);
      _scroll();
    });
    services.messageRepository.markMessagesAsRead(
        widget.chat.id, widget.currentUser.uid);
    services.chatRepository.markAsRead(
        widget.chat.id, widget.currentUser.uid);
  }

  void _scroll() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _stopTyping();

    final msg = MessageModel(
      id: _uuid.v4(),
      chatId: widget.chat.id,
      senderId: widget.currentUser.uid,
      senderName: widget.currentUser.displayName,
      senderDepartment: widget.currentUser.department,
      text: text,
      replyToId: _replyTo?.id,
      replyToText: _replyTo?.text,
      replyToSenderName: _replyTo?.senderName,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() => _replyTo = null);
    try {
      await services.messageRepository.sendMessage(msg);
    } catch (_) {
      _snack('Error al enviar mensaje');
    }
  }

  Future<void> _sendFile(File file) async {
    setState(() {
      _sendingMedia = true;
      _uploadFileName = file.path.split('/').last;
      _uploadType = mediaService.getMessageType(file.path);
      _uploadProgress = 0;
    });
    try {
      await services.messageRepository.sendMessageWithFile(
        chatId: widget.chat.id,
        senderId: widget.currentUser.uid,
        senderName: widget.currentUser.displayName,
        senderDepartment: widget.currentUser.department,
        file: file,
        replyToId: _replyTo?.id,
        replyToText: _replyTo?.text,
        replyToSenderName: _replyTo?.senderName,
      );
      setState(() => _replyTo = null);
    } catch (_) {
      _snack('Error al enviar archivo');
    } finally {
      setState(() => _sendingMedia = false);
    }
  }

  void _onTextChanged(String text) {
    if (!_isTyping) {
      _isTyping = true;
      services.messageRepository.setTyping(
          widget.chat.id, widget.currentUser.uid, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _isTyping = false;
    _typingTimer?.cancel();
    services.messageRepository.setTyping(
        widget.chat.id, widget.currentUser.uid, false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _stopTyping();
    notificationService.setActiveChat(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: DeptColors.forDepartment(
                  widget.chat.department.isNotEmpty
                      ? widget.chat.department
                      : 'general'),
              child: Icon(widget.chat.typeIcon,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.name.isNotEmpty
                        ? widget.chat.name
                        : 'Chat',
                    style: const TextStyle(
                        color: Color(0xFFE9EDEF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.chat.participantIds.length} miembros',
                    style: const TextStyle(
                        color: Color(0xFF8696A0), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.videocam_outlined),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.call_outlined),
              onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _menuAction,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'search', child: Text('Buscar')),
              PopupMenuItem(
                  value: 'files',
                  child: Text('Archivos compartidos')),
              PopupMenuItem(
                  value: 'mute', child: Text('Silenciar')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_replyTo != null) _replyPreview(),
          if (_sendingMedia)
            Padding(
              padding: const EdgeInsets.all(8),
              child: UploadProgressWidget(
                progress: _uploadProgress,
                fileName: _uploadFileName,
                type: _uploadType,
                onCancel: () =>
                    setState(() => _sendingMedia = false),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                        'Envía un mensaje para comenzar',
                        style: TextStyle(
                            color: Color(0xFF8696A0))))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderId ==
                          widget.currentUser.uid;

                      if (i == 0 ||
                          !_sameDay(
                              _messages[i - 1].timestamp,
                              msg.timestamp)) {
                        return Column(
                          children: [
                            _DateSeparator(date: msg.timestamp),
                            _Bubble(
                              message: msg,
                              isMe: isMe,
                              showSender:
                                  widget.chat.isGroup ||
                                      widget.chat.isChannel,
                              onReply: () => setState(
                                  () => _replyTo = msg),
                              onLongPress: () =>
                                  _actions(msg, isMe),
                            ),
                          ],
                        );
                      }

                      return _Bubble(
                        message: msg,
                        isMe: isMe,
                        showSender: widget.chat.isGroup ||
                            widget.chat.isChannel,
                        onReply: () =>
                            setState(() => _replyTo = msg),
                        onLongPress: () => _actions(msg, isMe),
                      );
                    },
                  ),
          ),
          _isRecording
              ? AudioRecorderWidget(
                  onSend: (file, dur) async {
                    setState(() => _isRecording = false);
                    await _sendFile(file);
                  },
                  onCancel: () =>
                      setState(() => _isRecording = false),
                )
              : _inputBar(),
        ],
      ),
    );
  }

  Widget _replyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2C34),
        border: Border(
            left:
                BorderSide(color: Color(0xFF00A884), width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_replyTo!.senderName,
                    style: const TextStyle(
                        color: Color(0xFF00A884),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(_replyTo!.text,
                    style: const TextStyle(
                        color: Color(0xFF8696A0), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                color: Color(0xFF8696A0), size: 20),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3942),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: Color(0xFF8696A0),
                          size: 24),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onTextChanged,
                        style: const TextStyle(
                            color: Color(0xFFE9EDEF),
                            fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Mensaje',
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 10),
                        ),
                        maxLines: null,
                        textCapitalization:
                            TextCapitalization.sentences,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                          Icons.attach_file_outlined,
                          color: Color(0xFF8696A0),
                          size: 24),
                      onPressed: _showPicker,
                    ),
                    IconButton(
                      icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF8696A0),
                          size: 24),
                      onPressed: () async {
                        final f = await mediaService.takePhoto();
                        if (f != null) _sendFile(f);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _sendText,
              onLongPress: () =>
                  setState(() => _isRecording = true),
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
      ),
    );
  }

  void _showPicker() {
    MediaPickerSheet.show(
      context,
      onCamera: () async {
        final f = await mediaService.takePhoto();
        if (f != null) _sendFile(f);
      },
      onGallery: () async {
        final files = await mediaService.pickImages();
        for (final f in files) {
          await _sendFile(f);
        }
      },
      onVideo: () async {
        final f = await mediaService.pickVideo();
        if (f != null) _sendFile(f);
      },
      onDocument: () async {
        final f = await mediaService.pickFile();
        if (f != null) _sendFile(f);
      },
      onAudio: () => setState(() => _isRecording = true),
      onLocation: () {},
    );
  }

  void _menuAction(String v) {
    switch (v) {
      case 'search':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatSearchScreen(
              chatId: widget.chat.id,
              chatName: widget.chat.name.isNotEmpty
                  ? widget.chat.name
                  : 'Chat',
            ),
          ),
        );
        break;
      case 'mute':
        services.chatRepository.toggleMute(
            widget.chat.id, widget.currentUser.uid);
        break;
    }
  }

  void _actions(MessageModel msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply,
                  color: Color(0xFF8696A0)),
              title: const Text('Responder',
                  style: TextStyle(color: Color(0xFFE9EDEF))),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyTo = msg);
              },
            ),
            if (isMe && msg.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit,
                    color: Color(0xFF8696A0)),
                title: const Text('Editar',
                    style: TextStyle(color: Color(0xFFE9EDEF))),
                onTap: () {
                  Navigator.pop(context);
                  _editDialog(msg);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete,
                  color: Color(0xFFFF4444)),
              title: Text(
                  isMe
                      ? 'Eliminar para todos'
                      : 'Eliminar para mí',
                  style: const TextStyle(
                      color: Color(0xFFFF4444))),
              onTap: () {
                Navigator.pop(context);
                services.messageRepository.deleteMessage(
                    widget.chat.id, msg.id, isMe);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editDialog(MessageModel msg) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        title: const Text('Editar mensaje',
            style: TextStyle(color: Color(0xFFE9EDEF))),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Color(0xFFE9EDEF)),
          maxLines: null,
          decoration: const InputDecoration(
              filled: true, fillColor: Color(0xFF2A3942)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8696A0))),
          ),
          TextButton(
            onPressed: () {
              services.messageRepository.editMessage(
                  widget.chat.id, msg.id, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Guardar',
                style: TextStyle(color: Color(0xFF00A884))),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ═══════════════════════════════════════════
// BURBUJA
// ═══════════════════════════════════════════

class _Bubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showSender;
  final VoidCallback onReply;
  final VoidCallback onLongPress;

  const _Bubble({
    required this.message,
    required this.isMe,
    required this.showSender,
    required this.onReply,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: const Text('🚫 Este mensaje fue eliminado',
              style: TextStyle(
                  color: Color(0xFF8696A0),
                  fontSize: 13,
                  fontStyle: FontStyle.italic)),
        ),
      );
    }

    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2C34),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(message.text,
              style: const TextStyle(
                  color: Color(0xFF8696A0), fontSize: 12)),
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (isMe) const SizedBox(width: 60),
            Flexible(
              child: Container(
                padding: message.type == MessageType.image
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF005C4B)
                      : const Color(0xFF202C33),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(10),
                    topRight: const Radius.circular(10),
                    bottomLeft: Radius.circular(isMe ? 10 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSender && !isMe)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 4, bottom: 4),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            color: DeptColors.forDepartment(
                                message.senderDepartment),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (message.replyToId != null)
                      _ReplyBubble(
                        name: message.replyToSenderName ?? '',
                        text: message.replyToText ?? '',
                      ),
                    _content(context),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isEdited)
                            const Text('editado ',
                                style: TextStyle(
                                    color: Color(0xFF8696A0),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic)),
                          Text(
                            '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: Color(0xFF8696A0),
                                fontSize: 11),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _statusIcon(message.status),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isMe) const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImagePreviewScreen(
                imageUrl: message.attachment!.url,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.attachment!.url,
              width: 250,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 250,
                  height: 200,
                  color: const Color(0xFF111B21),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00A884),
                        strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 250,
                height: 200,
                color: const Color(0xFF111B21),
                child: const Icon(Icons.broken_image,
                    color: Color(0xFF8696A0), size: 48),
              ),
            ),
          ),
        );

      case MessageType.video:
        return VideoThumbnailWidget(
          thumbnailUrl: message.attachment?.thumbnailUrl,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                    backgroundColor: Colors.black,
                    iconTheme:
                        const IconThemeData(color: Colors.white)),
                body: Center(
                  child: VideoPlayerWidget(
                    videoUrl: message.attachment!.url,
                    thumbnailUrl:
                        message.attachment?.thumbnailUrl,
                  ),
                ),
              ),
            ),
          ),
        );

      case MessageType.audio:
        return AudioPlayerWidget(
          audioUrl: message.attachment?.url,
          isMe: isMe,
        );

      case MessageType.document:
        return _document();

      default:
        return Text(message.text,
            style: const TextStyle(
                color: Color(0xFFE9EDEF), fontSize: 14.5));
    }
  }

  Widget _document() {
    final a = message.attachment!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(a.icon, color: const Color(0xFF00A884), size: 32),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Text(a.fileName,
                    style: const TextStyle(
                        color: Color(0xFFE9EDEF), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(a.sizeLabel,
                  style: const TextStyle(
                      color: Color(0xFF8696A0), fontSize: 11)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.download,
              color: Color(0xFF00A884), size: 22),
        ],
      ),
    );
  }
}

Widget _statusIcon(MessageStatus status) {
  switch (status) {
    case MessageStatus.sending:
      return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Color(0xFF8696A0)));
    case MessageStatus.sent:
      return const Icon(Icons.check,
          size: 16, color: Color(0xFF8696A0));
    case MessageStatus.delivered:
      return const Icon(Icons.done_all,
          size: 16, color: Color(0xFF8696A0));
    case MessageStatus.read:
      return const Icon(Icons.done_all,
          size: 16, color: Color(0xFF53BDEB));
    case MessageStatus.failed:
      return const Icon(Icons.error_outline,
          size: 16, color: Color(0xFFFF4444));
  }
}

class _ReplyBubble extends StatelessWidget {
  final String name;
  final String text;
  const _ReplyBubble({required this.name, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: const Border(
            left: BorderSide(color: Color(0xFF00A884), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  color: Color(0xFF00A884),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF8696A0), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF182229),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(_label(),
            style: const TextStyle(
                color: Color(0xFF8696A0), fontSize: 12)),
      ),
    );
  }

  String _label() {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'HOY';
    if (diff.inDays == 1) return 'AYER';
    if (diff.inDays < 7) {
      const d = [
        'LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES',
        'VIERNES', 'SÁBADO', 'DOMINGO'
      ];
      return d[date.weekday - 1];
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
