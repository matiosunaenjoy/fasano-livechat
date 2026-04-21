import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/chat_model.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _db
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final chats = snap.docs
          .map((doc) => ChatModel.fromFirestore(doc.data(), doc.id))
          .toList();
      chats.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.updatedAt;
        final bTime = b.lastMessageTime ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
      return chats;
    });
  }

  @override
  Stream<List<ChatModel>> getChannels() {
    return _db.collection('chats').snapshots().map((snap) {
      final channels = snap.docs
          .map((doc) => ChatModel.fromFirestore(doc.data(), doc.id))
          .where((c) =>
              c.type == ChatType.channel || c.type == ChatType.announcement)
          .toList();
      channels.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.updatedAt;
        final bTime = b.lastMessageTime ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
      return channels;
    });
  }

  @override
  Future<ChatModel> getOrCreateDirectChat(
      String currentUserId, UserModel otherUser) async {
    final existing = await _db
        .collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (final doc in existing.docs) {
      final participants =
          List<String>.from(doc.data()['participantIds'] ?? []);
      if (participants.contains(otherUser.uid)) {
        return ChatModel.fromFirestore(doc.data(), doc.id);
      }
    }

    final now = DateTime.now();
    final ref = _db.collection('chats').doc();

    final chat = ChatModel(
      id: ref.id,
      type: ChatType.direct,
      participantIds: [currentUserId, otherUser.uid],
      participantNames: {otherUser.uid: otherUser.displayName},
      createdBy: currentUserId,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(chat.toFirestore());
    return chat;
  }

  @override
  Future<ChatModel> createGroup({
    required String name,
    required String createdBy,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    String? description,
    String? department,
  }) async {
    final now = DateTime.now();
    final ref = _db.collection('chats').doc();

    final chat = ChatModel(
      id: ref.id,
      type: ChatType.group,
      name: name,
      description: description ?? '',
      participantIds: participantIds,
      participantNames: participantNames,
      createdBy: createdBy,
      department: department ?? '',
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(chat.toFirestore());
    return chat;
  }

  @override
  Future<ChatModel> createChannel({
    required String name,
    required String createdBy,
    required String department,
    String? description,
    bool onlyAdminsCanPost = false,
  }) async {
    final now = DateTime.now();
    final ref = _db.collection('chats').doc();

    final chat = ChatModel(
      id: ref.id,
      type: ChatType.channel,
      name: name,
      description: description ?? '',
      participantIds: [createdBy],
      createdBy: createdBy,
      onlyAdminsCanPost: onlyAdminsCanPost,
      department: department,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(chat.toFirestore());
    return chat;
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _db.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (_) {}
  }

  @override
  Future<void> togglePin(String chatId, String userId) async {
    final doc = await _db.collection('chats').doc(chatId).get();
    if (!doc.exists) return;
    final pinnedBy = Map<String, bool>.from(doc.data()!['pinnedBy'] ?? {});
    pinnedBy[userId] = !(pinnedBy[userId] ?? false);
    await _db.collection('chats').doc(chatId).update({'pinnedBy': pinnedBy});
  }

  @override
  Future<void> toggleMute(String chatId, String userId) async {
    final doc = await _db.collection('chats').doc(chatId).get();
    if (!doc.exists) return;
    final mutedBy = Map<String, bool>.from(doc.data()!['mutedBy'] ?? {});
    mutedBy[userId] = !(mutedBy[userId] ?? false);
    await _db.collection('chats').doc(chatId).update({'mutedBy': mutedBy});
  }

  @override
  Future<void> deleteChat(String chatId) async {
    await _db.collection('chats').doc(chatId).delete();
  }
}
