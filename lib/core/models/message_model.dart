import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  system,
  announcement,
}

class FileAttachment {
  final String url;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? thumbnailUrl;

  const FileAttachment({
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.thumbnailUrl,
  });

  String get sizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get icon {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.videocam;
    if (mimeType.startsWith('audio/')) return Icons.headphones;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      url: json['url'] ?? '',
      fileName: json['fileName'] ?? '',
      mimeType: json['mimeType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'thumbnailUrl': thumbnailUrl,
      };
}

class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderDepartment;
  final String text;
  final MessageType type;
  final FileAttachment? attachment;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final bool isPinned;
  final bool isEdited;
  final bool isDeleted;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderDepartment = '',
    required this.text,
    this.type = MessageType.text,
    this.attachment,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.readAt,
    this.isPinned = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.readBy = const [],
  });

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderDepartment,
    String? text,
    MessageType? type,
    FileAttachment? attachment,
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? readAt,
    bool? isPinned,
    bool? isEdited,
    bool? isDeleted,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderDepartment: senderDepartment ?? this.senderDepartment,
      text: text ?? this.text,
      type: type ?? this.type,
      attachment: attachment ?? this.attachment,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      readBy: readBy ?? this.readBy,
    );
  }

  factory MessageModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderDepartment: data['senderDepartment'] ?? '',
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      attachment: data['attachment'] != null
          ? FileAttachment.fromJson(
              Map<String, dynamic>.from(data['attachment']))
          : null,
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToSenderName: data['replyToSenderName'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: _toDate(data['timestamp']),
      readAt: _toDateNullable(data['readAt']),
      isPinned: data['isPinned'] ?? false,
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderDepartment': senderDepartment,
        'text': text,
        'type': type.name,
        'attachment': attachment?.toJson(),
        'replyToId': replyToId,
        'replyToText': replyToText,
        'replyToSenderName': replyToSenderName,
        'status': status.name,
        'timestamp': timestamp,
        'readAt': readAt,
        'isPinned': isPinned,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        'readBy': readBy,
      };

  static DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _toDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return value.toDate();
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props =>
      [id, chatId, text, type, status, timestamp];
}
