import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/message_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/service_locator.dart';
import '../../theme.dart';
import '../chat_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  final UserModel currentUser;
  const GlobalSearchScreen({super.key, required this.currentUser});

  @override
  State<GlobalSearchScreen> createState() =>
      _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late final TabController _tab;
  String _query = '';
  bool _loading = false;
  Timer? _debounce;

  List<MessageModel> _messages = [];
  List<MessageModel> _files = [];
  List<UserModel> _people = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tab.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(v.trim());
    });
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _messages = [];
        _files = [];
        _people = [];
      });
      return;
    }

    setState(() {
      _query = q;
      _loading = true;
    });

    try {
      final results = await Future.wait([
        services.messageRepository.searchAllMessages(
            widget.currentUser.uid, q),
        services.userDirectoryRepository.searchEmployees(q),
      ]);

      final msgs = results[0] as List<MessageModel>;
      final people = results[1] as List<UserModel>;

      setState(() {
        _messages = msgs
            .where((m) => m.type == MessageType.text)
            .toList();
        _files = msgs
            .where((m) => m.type != MessageType.text)
            .toList();
        _people = people;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  int get _total => _messages.length + _files.length + _people.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(
              color: Color(0xFFE9EDEF), fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Buscar...',
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        color: Color(0xFF8696A0)),
                    onPressed: () {
                      _ctrl.clear();
                      _search('');
                    },
                  )
                : null,
          ),
        ),
        bottom: _query.isNotEmpty
            ? TabBar(
                controller: _tab,
                indicatorColor: const Color(0xFF00A884),
                labelColor: const Color(0xFF00A884),
                unselectedLabelColor: const Color(0xFF8696A0),
                isScrollable: true,
                tabs: [
                  Tab(text: 'Todo ($_total)'),
                  Tab(text: 'Mensajes (${_messages.length})'),
                  Tab(text: 'Archivos (${_files.length})'),
                  Tab(text: 'Personas (${_people.length})'),
                ],
              )
            : null,
      ),
      body: _query.isEmpty
          ? const Center(
              child: Text('Busca mensajes, archivos o personas',
                  style: TextStyle(color: Color(0xFF8696A0))))
          : _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00A884)))
              : _total == 0
                  ? Center(
                      child: Text(
                          'No hay resultados para "$_query"',
                          style: const TextStyle(
                              color: Color(0xFF8696A0))))
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _allResults(),
                        _messageList(_messages),
                        _fileList(_files),
                        _peopleList(),
                      ],
                    ),
    );
  }

  Widget _allResults() {
    return ListView(
      children: [
        if (_people.isNotEmpty) ...[
          const _Label('PERSONAS'),
          ..._people.take(3).map((u) => _personTile(u)),
        ],
        if (_messages.isNotEmpty) ...[
          const _Label('MENSAJES'),
          ..._messages.take(5).map((m) => _msgTile(m)),
        ],
        if (_files.isNotEmpty) ...[
          const _Label('ARCHIVOS'),
          ..._files.take(3).map((m) => _fileTile(m)),
        ],
      ],
    );
  }

  Widget _messageList(List<MessageModel> list) {
    if (list.isEmpty) return const Center(
        child: Text('Sin mensajes',
            style: TextStyle(color: Color(0xFF8696A0))));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => _msgTile(list[i]),
    );
  }

  Widget _fileList(List<MessageModel> list) {
    if (list.isEmpty) return const Center(
        child: Text('Sin archivos',
            style: TextStyle(color: Color(0xFF8696A0))));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => _fileTile(list[i]),
    );
  }

  Widget _peopleList() {
    if (_people.isEmpty) return const Center(
        child: Text('Sin personas',
            style: TextStyle(color: Color(0xFF8696A0))));
    return ListView.builder(
      itemCount: _people.length,
      itemBuilder: (_, i) => _personTile(_people[i]),
    );
  }

  Widget _msgTile(MessageModel m) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor:
            DeptColors.forDepartment(m.senderDepartment),
        child: Text(m.senderName.isNotEmpty ? m.senderName[0] : '?',
            style: const TextStyle(color: Colors.white)),
      ),
      title: Text(m.senderName,
          style: const TextStyle(
              color: Color(0xFFE9EDEF), fontSize: 14)),
      subtitle: _highlight(m.text, _query),
      trailing: Text(_fmtDate(m.timestamp),
          style: const TextStyle(
              color: Color(0xFF8696A0), fontSize: 11)),
    );
  }

  Widget _fileTile(MessageModel m) {
    IconData icon;
    switch (m.type) {
      case MessageType.image:
        icon = Icons.image;
        break;
      case MessageType.video:
        icon = Icons.videocam;
        break;
      case MessageType.audio:
        icon = Icons.headphones;
        break;
      default:
        icon = Icons.insert_drive_file;
    }

    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A884)),
      title: Text(m.attachment?.fileName ?? m.text,
          style: const TextStyle(
              color: Color(0xFFE9EDEF), fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
          '${m.senderName} · ${m.attachment?.sizeLabel ?? ''}',
          style: const TextStyle(
              color: Color(0xFF8696A0), fontSize: 12)),
    );
  }

  Widget _personTile(UserModel u) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor:
            DeptColors.forDepartment(u.department),
        child: Text(u.initials,
            style: const TextStyle(
                color: Colors.white, fontSize: 14)),
      ),
      title: Text(u.displayName,
          style: const TextStyle(
              color: Color(0xFFE9EDEF), fontSize: 15)),
      subtitle: Text('${u.position} · ${u.department}',
          style: const TextStyle(
              color: Color(0xFF8696A0), fontSize: 13)),
      trailing: IconButton(
        icon: const Icon(Icons.chat_bubble_outline,
            color: Color(0xFF00A884), size: 20),
        onPressed: () async {
          final chat = await services.chatRepository
              .getOrCreateDirectChat(
                  widget.currentUser.uid, u);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                    chat: chat,
                    currentUser: widget.currentUser),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _highlight(String text, String query) {
    if (query.isEmpty) {
      return Text(text,
          style: const TextStyle(
              color: Color(0xFF8696A0), fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final lq = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(lq, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
            color: Color(0xFF00A884), fontWeight: FontWeight.w600),
      ));
      start = idx + query.length;
    }
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
            color: Color(0xFF8696A0), fontSize: 13),
        children: spans,
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text,
          style: const TextStyle(
            color: Color(0xFF8696A0),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          )),
    );
  }
}
