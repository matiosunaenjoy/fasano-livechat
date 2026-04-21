import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum UserRole { admin, moderator, employee }
enum UserStatus { online, offline, away, busy }

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String department;
  final String position;
  final String phoneNumber;
  final UserRole role;
  final UserStatus status;
  final String statusMessage;
  final DateTime lastSeen;
  final DateTime createdAt;
  final bool isActive;
  final List<String> mutedChats;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.department = '',
    this.position = '',
    this.phoneNumber = '',
    this.role = UserRole.employee,
    this.status = UserStatus.offline,
    this.statusMessage = '',
    required this.lastSeen,
    required this.createdAt,
    this.isActive = true,
    this.mutedChats = const [],
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  Color get statusColor {
    switch (status) {
      case UserStatus.online:
        return const Color(0xFF00A884);
      case UserStatus.away:
        return const Color(0xFFFFC107);
      case UserStatus.busy:
        return const Color(0xFFFF4444);
      case UserStatus.offline:
        return const Color(0xFF8696A0);
    }
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      department: data['department'] ?? '',
      position: data['position'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.employee,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.offline,
      ),
      statusMessage: data['statusMessage'] ?? '',
      lastSeen: _toDate(data['lastSeen']),
      createdAt: _toDate(data['createdAt']),
      isActive: data['isActive'] ?? true,
      mutedChats: List<String>.from(data['mutedChats'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'department': department,
        'position': position,
        'phoneNumber': phoneNumber,
        'role': role.name,
        'status': status.name,
        'statusMessage': statusMessage,
        'lastSeen': lastSeen,
        'createdAt': createdAt,
        'isActive': isActive,
        'mutedChats': mutedChats,
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

  @override
  List<Object?> get props =>
      [uid, email, displayName, status, department, role, isActive];
}
