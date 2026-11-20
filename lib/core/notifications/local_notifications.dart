import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../utils/app_logger.dart';
import '../../utils/routes/routes_name.dart';

/// Used to open a screen when the user taps a notification.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Shared local-notification plugin for chat pushes and follow-up reminders.
///
/// Payload format: `chat:<chatId>` or `followup:<followUpId>[:<extra>]`.
class LocalNotifications {
  LocalNotifications._();

  static final LocalNotifications instance = LocalNotifications._();

  static const chatChannel = AndroidNotificationChannel(
    'chat_messages',
    'Chat messages',
    description: 'New chat messages from your team',
    importance: Importance.high,
  );

  static const followUpChannel = AndroidNotificationChannel(
    'followup_reminders',
    'Follow-up reminders',
    description: 'Reminders for scheduled school follow-ups',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  Future<void>? _initFuture;
  String? _pendingPayload;
  bool _permissionAsked = false;

  /// Screen the user is on, e.g. `chat:<id>`; pushes for it are suppressed.
  String? activeScreen;

  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) {
          final p = r.payload;
          if (p != null && p.isNotEmpty) open(p);
        },
      );
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(chatChannel);
      await android?.createNotificationChannel(followUpChannel);

      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _pendingPayload = launch?.notificationResponse?.payload;
      }
    } catch (e) {
      AppLogger.error('Local notifications init failed: $e');
    }
  }

  Future<void> requestPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    await init();
    if (Platform.isAndroid) {
      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Remember a payload to open once the user reaches the dashboard
  /// (cold start: splash/login would otherwise replace the pushed screen).
  void setPending(String payload) => _pendingPayload = payload;

  /// Called by the dashboard after it is shown.
  void flushPending() {
    final p = _pendingPayload;
    if (p == null) return;
    _pendingPayload = null;
    open(p);
  }

  void open(String payload) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      _pendingPayload = payload;
      return;
    }
    if (payload == activeScreen) return;
    final sep = payload.indexOf(':');
    final kind = sep < 0 ? 'chat' : payload.substring(0, sep);
    final rest = sep < 0 ? payload : payload.substring(sep + 1);
    switch (kind) {
      case 'chat':
        nav.pushNamed(RoutesName.chatroom, arguments: rest);
        break;
      case 'followup':
        if (activeScreen == 'followups') return;
        nav.pushNamed(RoutesName.followups);
        break;
    }
  }
}
