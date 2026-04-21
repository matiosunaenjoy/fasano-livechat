import 'dart:io';
import '../models/message_model.dart';

abstract class MessageRepository {
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<List<MessageModel>> getMessagesPaginated(
    String chatId, {
    int limit,
    DateTime? before,
  });
  Future<MessageModel> sendMessage(MessageModel message);
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
  });
  Future<void> editMessage(
      String chatId, String messageId, String newText);
  Future<void> deleteMessage(
      String chatId, String messageId, bool forEveryone);
  Future<void> markMessagesAsRead(String chatId, String readerId);
  Future<List<MessageModel>> searchMessages(
      String chatId, String query);
  Future<List<MessageModel>> searchAllMessages(
      String userId, String query);
  Future<List<MessageModel>> getSharedFiles(String chatId);
  Stream<Map<String, bool>> getTypingStatus(String chatId);
  Future<void> setTyping(
      String chatId, String userId, bool isTyping);
}
