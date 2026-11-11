import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../auth/model/FollowUpModel.dart';
import '../../utils/app_logger.dart';
import '../notifications/local_notifications.dart';

/// Keeps the device's scheduled reminders in line with the user's follow-ups.
///
/// Each scheduled notification's payload is `followup:<id>:<remindAtMs>`, so
/// [sync] can tell which reminders are stale (done, deleted or rescheduled)
/// and only touch those. Safe to call on every data change.
class FollowUpReminders {
  FollowUpReminders._();

  static final FollowUpReminders instance = FollowUpReminders._();

  static const _prefix = 'followup:';

  bool _syncing = false;
  List<FollowUp>? _queued;

  Future<void> sync(List<FollowUp> mine) async {
    if (_syncing) {
      _queued = mine;
      return;
    }
    _syncing = true;
    try {
      await _sync(mine);
    } catch (e) {
      AppLogger.error('Reminder sync failed: $e');
    } finally {
      _syncing = false;
      final q = _queued;
      _queued = null;
      if (q != null) sync(q);
    }
  }

  Future<void> cancelAll() async {
    final local = LocalNotifications.instance;
    await local.init();
    final pending = await local.plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.payload?.startsWith(_prefix) ?? false) {
        await local.plugin.cancel(id: p.id);
      }
    }
  }

  Future<void> _sync(List<FollowUp> mine) async {
    final local = LocalNotifications.instance;
    await local.init();
    final now = DateTime.now();

    final wanted = <String, FollowUp>{
      for (final f in mine)
        if (f.isPending && f.remindAt != null && f.remindAt!.isAfter(now))
          _payload(f): f,
    };

    final pending = await local.plugin.pendingNotificationRequests();
    final scheduled = <String>{};
    for (final p in pending) {
      final payload = p.payload ?? '';
      if (!payload.startsWith(_prefix)) continue;
      if (wanted.containsKey(payload)) {
        scheduled.add(payload);
      } else {
        await local.plugin.cancel(id: p.id);
      }
    }

    final toAdd = wanted.entries.where((e) => !scheduled.contains(e.key));
    if (toAdd.isEmpty) return;
    await local.requestPermission();

    const ch = LocalNotifications.followUpChannel;
    for (final e in toAdd) {
      final f = e.value;
      await local.plugin.zonedSchedule(
        id: _notificationId(f.id),
        title: '${f.type.label} follow-up: ${f.schoolName}',
        body: _body(f),
        payload: e.key,
        scheduledDate: tz.TZDateTime.from(f.remindAt!, tz.UTC),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            ch.id,
            ch.name,
            channelDescription: ch.description,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }

  String _payload(FollowUp f) =>
      '$_prefix${f.id}:${f.remindAt!.millisecondsSinceEpoch}';

  String _body(FollowUp f) {
    final when = DateFormat('h:mm a').format(f.dueAt);
    final who = f.contactName.isNotEmpty ? ' with ${f.contactName}' : '';
    final note = f.note.isNotEmpty ? ' · ${f.note}' : '';
    return 'Due $when$who$note';
  }

  /// Stable 31-bit id from the Firestore doc id (FNV-1a).
  int _notificationId(String docId) {
    var h = 0x811c9dc5;
    for (final c in docId.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }
}
