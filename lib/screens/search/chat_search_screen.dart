import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/message_model.dart';
import '../../core/services/service_locator.dart';
import '../../theme.dart';

class ChatSearchScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatSearchScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatSearchScreen> createState() =>
      _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final _ctrl = TextEditingController();
  List<MessageModel> _results = [];
  bool _loading = false;
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(v.trim());
    });
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _results = [];
      });
      return;
    }
    setState(() {
      _query = q;
      _loading = true;
    });
    try {
      final r = await services.messageRepository
          .searchMessages(widget.chatId, q);
      setState(() {
        _results = r;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buscar en ${widget.chatName}',
                style: const TextStyle(
                    color: Color(0xFFE9EDEF), fontSize: 16)),
            if (_results.isNotEmpty)
              Text('${_results.length} resultados',
                  style: const TextStyle(
                      color: Color(0xFF8696A0), fontSize: 12)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              style: const TextStyle(
                  color: Color(0xFFE9EDEF), fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar mensaje...',
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF8696A0), size: 20),
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
                filled: true,
                fillColor: const Color(0xFF2A3942),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF00A884)))
          : _query.isEmpty
              ? const Center(
                  child: Text(
                      'Busca mensajes en esta conversación',
                      style: TextStyle(
                          color: Color(0xFF8696A0))))
              : _results.isEmpty
                  ? Center(
                      child: Text(
                          'No se encontró "$_query"',
                          style: const TextStyle(
                              color: Color(0xFF8696A0))))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final m = _results[i];
                        return ListTile(
                          onTap: () => Navigator.pop(context, m),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                DeptColors.forDepartment(
                                    m.senderDepartment),
                            child: Text(
                                m.senderName.isNotEmpty
                                    ? m.senderName[0]
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white)),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(m.senderName,
                                    style: const TextStyle(
                                        color: Color(0xFFE9EDEF),
                                        fontSize: 14)),
                              ),
                              Text(_fmtDate(m.timestamp),
                                  style: const TextStyle(
                                      color: Color(0xFF8696A0),
                                      fontSize: 11)),
                            ],
                          ),
                          subtitle: Text(m.text,
                              style: const TextStyle(
                                  color: Color(0xFF8696A0),
                                  fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        );
                      },
                    ),
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Ayer';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
