import '../models/chat_model.dart';
import '../models/user_model.dart';

abstract class ChatRepository {
  Stream<List<ChatModel>> getUserChats(String userId);
  Stream<List<ChatModel>> getChannels();
  Future<ChatModel> getOrCreateDirectChat(
      String currentUserId, UserModel otherUser);
  Future<ChatModel> createGroup({
    required String name,
    required String createdBy,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    String? description,
    String? department,
  });
  Future<ChatModel> createChannel({
    required String name,
    required String createdBy,
    required String department,
    String? description,
    bool onlyAdminsCanPost,
  });
  Future<void> markAsRead(String chatId, String userId);
  Future<void> togglePin(String chatId, String userId);
  Future<void> toggleMute(String chatId, String userId);
  Future<void> deleteChat(String chatId);
}
