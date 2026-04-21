import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import '../../core/models/message_model.dart';
import '../../core/repositories/message_repository.dart';

class FirebaseMessageRepository implements MessageRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(200)
        .snapshots()
        .map((snap) => snap.docs
            .map(
                (doc) => MessageModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<MessageModel>> getMessagesPaginated(
    String chatId, {
    int limit = 50,
    DateTime? before,
  }) async {
    Query query = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (before != null) {
      query = query.where('timestamp', isLessThan: before);
    }

    final snap = await query.get();
    return snap.docs
        .map((d) => MessageModel.fromFirestore(
            d.data() as Map<String, dynamic>, d.id))
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    final batch = _db.batch();

    final msgRef = _db
        .collection('chats')
        .doc(message.chatId)
        .collection('messages')
        .doc(message.id);

    batch.set(msgRef, message.toFirestore());

    final chatRef = _db.collection('chats').doc(message.chatId);
    batch.update(chatRef, {
      'lastMessageText': message.text.isNotEmpty
          ? message.text
          : _mediaLabel(message.type),
      'lastMessageSenderId': message.senderId,
      'lastMessageSenderName': message.senderName,
      'lastMessageTime': message.timestamp,
      'lastMessageIsFile': message.attachment != null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    final chatDoc = await chatRef.get();
    if (chatDoc.exists) {
      final participants =
          List<String>.from(chatDoc.data()!['participantIds'] ?? []);
      for (final pid in participants) {
        if (pid != message.senderId) {
          await chatRef.update({
            'unreadCounts.$pid': FieldValue.increment(1),
          });
        }
      }
    }

    return message.copyWith(status: MessageStatus.sent);
  }

  @override
  Future<MessageModel> sendMessageWithFile({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderDepartment,
    required File file,
    String? caption,
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
    final fileName = p.basename(file.path);
    final ext = p.extension(file.path).toLowerCase();
    final mimeType = _getMimeType(ext);
    final fileSize = await file.length();

    final ref = _storage.ref().child(
        'chats/$chatId/files/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    final task = await ref.putFile(file);
    final downloadUrl = await task.ref.getDownloadURL();

    final attachment = FileAttachment(
      url: downloadUrl,
      fileName: fileName,
      mimeType: mimeType,
      fileSize: fileSize,
    );

    MessageType type;
    if (mimeType.startsWith('image/')) {
      type = MessageType.image;
    } else if (mimeType.startsWith('video/')) {
      type = MessageType.video;
    } else if (mimeType.startsWith('audio/')) {
      type = MessageType.audio;
    } else {
      type = MessageType.document;
    }

    final msgRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: msgRef.id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderDepartment: senderDepartment,
      text: caption ?? fileName,
      type: type,
      attachment: attachment,
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    await sendMessage(message);
    return message;
  }

  @override
  Future<void> editMessage(
      String chatId, String messageId, String newText) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newText, 'isEdited': true});
  }

  @override
  Future<void> deleteMessage(
      String chatId, String messageId, bool forEveryone) async {
    if (forEveryone) {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'text': 'Mensaje eliminado',
        'attachment': null,
      });
    } else {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    }
  }

  @override
  Future<void> markMessagesAsRead(
      String chatId, String readerId) async {
    final unread = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: readerId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'status': MessageStatus.read.name,
        'readAt': FieldValue.serverTimestamp(),
        'readBy': FieldValue.arrayUnion([readerId]),
      });
    }
    await batch.commit();

    await _db.collection('chats').doc(chatId).update({
      'unreadCounts.$readerId': 0,
    });
  }

  @override
  Future<List<MessageModel>> searchMessages(
      String chatId, String query) async {
    final lowerQuery = query.toLowerCase();
    final snap = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(500)
        .get();

    return snap.docs
        .map((d) => MessageModel.fromFirestore(d.data(), d.id))
        .where((m) => m.text.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<List<MessageModel>> searchAllMessages(
      String userId, String query) async {
    final chatsSnap = await _db
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .get();

    final results = <MessageModel>[];
    final lowerQuery = query.toLowerCase();

    for (final chatDoc in chatsSnap.docs) {
      final messagesSnap = await _db
          .collection('chats')
          .doc(chatDoc.id)
          .collection('messages')
          .where('isDeleted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      for (final msgDoc in messagesSnap.docs) {
        final msg =
            MessageModel.fromFirestore(msgDoc.data(), msgDoc.id);
        if (msg.text.toLowerCase().contains(lowerQuery)) {
          results.add(msg);
        }
      }
    }

    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results.take(50).toList();
  }

  @override
  Future<List<MessageModel>> getSharedFiles(String chatId) async {
    final snap = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('type', whereIn: ['image', 'video', 'document', 'audio'])
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    return snap.docs
        .map((d) => MessageModel.fromFirestore(d.data(), d.id))
        .where((m) => m.attachment != null)
        .toList();
  }

  @override
  Stream<Map<String, bool>> getTypingStatus(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String, bool>{};
      final typing =
          doc.data()!['typing'] as Map<String, dynamic>? ?? {};
      return typing.map((k, v) => MapEntry(k, v as bool));
    });
  }

  @override
  Future<void> setTyping(
      String chatId, String userId, bool isTyping) async {
    await _db.collection('chats').doc(chatId).update({
      'typing.$userId': isTyping,
    });
  }

  String _mediaLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return '📷 Imagen';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.document:
        return '📄 Documento';
      default:
        return '';
    }
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.mp3':
        return 'audio/mpeg';
      case '.aac':
        return 'audio/aac';
      case '.m4a':
        return 'audio/mp4';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
