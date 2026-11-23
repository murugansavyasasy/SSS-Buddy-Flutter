import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/model/TeamWorkModel.dart';
import '../../utils/app_logger.dart';
import '../notifications/local_notifications.dart';

/// Local notifications for Team Work: "Task assigned to you" and new
/// announcements. No push yet, so this compares what the app loads (hub
/// open, app resumed) with what this device saw last time. The first
/// check for a user only records the current state.
class TeamNotifier {
  TeamNotifier._();

  static final TeamNotifier instance = TeamNotifier._();

  static const _tasksPrefix = 'teamwork_tasks_seen_v1_';
  static const _annPrefix = 'teamwork_ann_seen_v1_';

  Future<void> check({
    required String userId,
    required List<WorkTask> myTasks,
    required List<Announcement> announcements,
  }) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final newTasks = await _diff(prefs, '$_tasksPrefix$userId', myTasks.map((t) => t.id));
      final newAnn = await _diff(prefs, '$_annPrefix$userId', announcements.map((a) => a.id));
      for (final t in myTasks.where((t) => newTasks.contains(t.id))) {
        await _show(
          key: 'task:${t.id}',
          title: 'Task assigned to you ${t.displayId}',
          body: [t.title, if (t.assignedByName.isNotEmpty) 'by ${t.assignedByName}'].join(' · '),
        );
      }
      for (final a in announcements.where((a) => newAnn.contains(a.id))) {
        await _show(
          key: 'announcement:${a.id}',
          title: a.important ? 'Important: ${a.title}' : 'Announcement: ${a.title}',
          body: a.body,
        );
      }
    } catch (e) {
      AppLogger.error('Team notification check failed: $e');
    }
  }

  /// Ids in [ids] not seen before (none on the first check); saves [ids].
  Future<Set<String>> _diff(SharedPreferences prefs, String key, Iterable<String> ids) async {
    final first = !prefs.containsKey(key);
    final seen = (prefs.getStringList(key) ?? const <String>[]).toSet();
    final now = ids.toSet();
    await prefs.setStringList(key, {...seen, ...now}.toList());
    return first ? <String>{} : now.difference(seen);
  }

  Future<void> _show({required String key, required String title, required String body}) async {
    final local = LocalNotifications.instance;
    await local.init();
    await local.requestPermission();
    const ch = LocalNotifications.teamChannel;
    await local.plugin.show(
      id: _id(key),
      title: title,
      body: body,
      payload: key,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          ch.id,
          ch.name,
          channelDescription: ch.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Stable 31-bit id per notification (FNV-1a).
  int _id(String key) {
    var h = 0x811c9dc5;
    for (final c in key.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }
}
