import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ChatType { direct, group, channel, announcement }

class ChatModel extends Equatable {
  final String id;
  final ChatType type;
  final String name;
  final String description;
  final String photoUrl;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String createdBy;
  final String lastMessageText;
  final String lastMessageSenderId;
  final String lastMessageSenderName;
  final DateTime? lastMessageTime;
  final bool lastMessageIsFile;
  final Map<String, int> unreadCounts;
  final Map<String, bool> pinnedBy;
  final Map<String, bool> mutedBy;
  final bool onlyAdminsCanPost;
  final String department;
  final List<String> pinnedMessageIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatModel({
    required this.id,
    required this.type,
    this.name = '',
    this.description = '',
    this.photoUrl = '',
    required this.participantIds,
    this.participantNames = const {},
    this.createdBy = '',
    this.lastMessageText = '',
    this.lastMessageSenderId = '',
    this.lastMessageSenderName = '',
    this.lastMessageTime,
    this.lastMessageIsFile = false,
    this.unreadCounts = const {},
    this.pinnedBy = const {},
    this.mutedBy = const {},
    this.onlyAdminsCanPost = false,
    this.department = '',
    this.pinnedMessageIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isChannel => type == ChatType.channel;
  bool get isAnnouncement => type == ChatType.announcement;
  bool get isGroup => type == ChatType.group;
  bool get isDirect => type == ChatType.direct;

  IconData get typeIcon {
    switch (type) {
      case ChatType.direct:
        return Icons.person;
      case ChatType.group:
        return Icons.group;
      case ChatType.channel:
        return Icons.tag;
      case ChatType.announcement:
        return Icons.campaign;
    }
  }

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

  factory ChatModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatModel(
      id: id,
      type: ChatType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChatType.direct,
      ),
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? {}),
      createdBy: data['createdBy'] ?? '',
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageSenderName: data['lastMessageSenderName'] ?? '',
      lastMessageTime: _toDateNullable(data['lastMessageTime']),
      lastMessageIsFile: data['lastMessageIsFile'] ?? false,
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      pinnedBy: Map<String, bool>.from(data['pinnedBy'] ?? {}),
      mutedBy: Map<String, bool>.from(data['mutedBy'] ?? {}),
      onlyAdminsCanPost: data['onlyAdminsCanPost'] ?? false,
      department: data['department'] ?? '',
      pinnedMessageIds: List<String>.from(data['pinnedMessageIds'] ?? []),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type.name,
        'name': name,
        'description': description,
        'photoUrl': photoUrl,
        'participantIds': participantIds,
        'participantNames': participantNames,
        'createdBy': createdBy,
        'lastMessageText': lastMessageText,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageSenderName': lastMessageSenderName,
        'lastMessageTime': lastMessageTime,
        'lastMessageIsFile': lastMessageIsFile,
        'unreadCounts': unreadCounts,
        'pinnedBy': pinnedBy,
        'mutedBy': mutedBy,
        'onlyAdminsCanPost': onlyAdminsCanPost,
        'department': department,
        'pinnedMessageIds': pinnedMessageIds,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  @override
  List<Object?> get props => [id, lastMessageText, lastMessageTime, updatedAt];
}
