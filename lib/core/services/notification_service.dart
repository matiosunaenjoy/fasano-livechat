import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _token;
  String? _userId;
  String? _activeChatId;

  final _navController = StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _navController.stream;

  Future<void> init(String userId) async {
    _userId = userId;

    // En web no usar notificaciones nativas
    if (kIsWeb) {
      try {
        _token = await _fcm.getToken();
        await _saveToken();
      } catch (_) {}
      return;
    }

    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _local.initialize(
        const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: _onTap,
      );

      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'direct_messages',
            'Mensajes directos',
            importance: Importance.high,
          ),
        );
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'group_messages',
            'Mensajes de grupo',
            importance: Importance.defaultImportance,
          ),
        );
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'channel_messages',
            'Canales',
            importance: Importance.low,
          ),
        );
      }

      _token = await _fcm.getToken();
      await _saveToken();

      _fcm.onTokenRefresh.listen((t) {
        _token = t;
        _saveToken();
      });

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      final initial = await _fcm.getInitialMessage();
      if (initial != null) _onOpened(initial);
    } catch (_) {}
  }

  Future<void> _saveToken() async {
    if (_token == null || _userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('tokens')
          .doc(_token)
          .set({
        'token': _token,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _onForeground(RemoteMessage msg) {
    final chatId = msg.data['chatId'];
    if (chatId != null && chatId == _activeChatId) return;

    final notification = msg.notification;
    if (notification != null) {
      _showLocal(
        id: msg.hashCode,
        title: notification.title ?? 'Empresa Chat',
        body: notification.body ?? '',
        channelId: 'direct_messages',
        payload: jsonEncode(msg.data),
      );
    }
  }

  void _onOpened(RemoteMessage msg) {
    final chatId = msg.data['chatId'];
    if (chatId != null) _navController.add(chatId);
  }

  void _onTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final chatId = data['chatId'];
        if (chatId != null) _navController.add(chatId);
      } catch (_) {}
    }
  }

  Future<void> _showLocal({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    if (kIsWeb) return;

    final android = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF00A884),
    );
    const ios = DarwinNotificationDetails();
    await _local.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
  }

  Future<void> cleanup() async {
    if (_userId != null && _token != null) {
      try {
        await _db
            .collection('users')
            .doc(_userId)
            .collection('tokens')
            .doc(_token)
            .delete();
      } catch (_) {}
    }
    _userId = null;
  }

  void dispose() {
    _navController.close();
  }
}

final notificationService = NotificationService();
