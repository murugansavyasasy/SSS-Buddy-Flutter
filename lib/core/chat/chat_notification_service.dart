import '../notifications/local_notifications.dart';

/// Chat push notifications.
///
/// Push delivery depends on the chat backend (not decided yet), so
/// [registerUser] / [unregister] are no-ops for now. Foreground display and
/// tap-to-open already go through [LocalNotifications] with the payload
/// `chat:<chatId>`.
class ChatNotificationService {
  ChatNotificationService._();

  static final ChatNotificationService instance = ChatNotificationService._();

  final LocalNotifications _local = LocalNotifications.instance;

  /// Chat currently on screen; notifications for it should not be shown.
  String? get activeChatId {
    final s = _local.activeScreen;
    return (s != null && s.startsWith('chat:')) ? s.substring(5) : null;
  }

  set activeChatId(String? id) =>
      _local.activeScreen = id == null ? null : 'chat:$id';

  /// Register this device's push token for [userId] with the chat backend.
  Future<void> registerUser(String userId) async {}

  /// Stop pushes to this device for the user who is logging out.
  Future<void> unregister() async {}
}
