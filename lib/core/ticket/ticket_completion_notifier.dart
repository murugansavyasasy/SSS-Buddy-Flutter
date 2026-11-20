import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/model/TicketModel.dart';
import '../../utils/app_logger.dart';
import '../notifications/local_notifications.dart';

/// Shows "Ticket completed" to the person who raised it.
///
/// No Firebase push yet, so this runs whenever the app loads that user's
/// tickets (dashboard open, app resumed, Tickets screen): it compares each
/// ticket's status with the one seen last time on this device and notifies
/// for tickets that have just become Completed. Once FCM is set up the
/// backend push covers a closed app; this stays as the fallback.
class TicketCompletionNotifier {
  TicketCompletionNotifier._();

  static final TicketCompletionNotifier instance = TicketCompletionNotifier._();

  static const _prefix = 'tickets_seen_v1_';
  static const _assignedPrefix = 'tickets_assigned_seen_v1_';

  /// Notifies the raiser when a ticket is completed and the assignee when a
  /// ticket is newly assigned to them.
  Future<void> check(List<Ticket> tickets, String userId, {String userName = ''}) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$userId';
      final lastSeen = _decode(prefs.getString(key));
      final done = newlyCompletedTickets(tickets, lastSeen, userId);

      final aKey = '$_assignedPrefix$userId';
      final firstCheck = !prefs.containsKey(aKey);
      final seenAssigned = (prefs.getStringList(aKey) ?? const <String>[]).toSet();
      final assigned = newlyAssignedTickets(tickets, seenAssigned, userId,
          firstCheck: firstCheck, myName: userName);
      await prefs.setStringList(aKey, [
        for (final t in tickets)
          if (t.assignedToId == userId) t.id,
      ]);

      final mine = tickets.where((t) => t.raisedById == userId);
      // Keep entries for tickets not in this list (e.g. a filtered fetch).
      final next = {...lastSeen, for (final t in mine) t.id: t.status.apiValue};
      await prefs.setString(key, jsonEncode(next));

      for (final t in done) {
        await _show(t);
      }
      for (final t in assigned) {
        await _show(t, assignedToMe: true);
      }
    } catch (e) {
      AppLogger.error('Ticket completion check failed: $e');
    }
  }

  Map<String, String> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {
      return {};
    }
  }

  Future<void> _show(Ticket t, {bool assignedToMe = false}) async {
    final local = LocalNotifications.instance;
    await local.init();
    await local.requestPermission();
    const ch = LocalNotifications.ticketChannel;
    final note = t.latestNote;
    await local.plugin.show(
      id: _id(assignedToMe ? 'a${t.id}' : t.id),
      title: assignedToMe
          ? 'Ticket assigned to you ${t.displayId}'
          : 'Ticket completed ${t.displayId}',
      body: assignedToMe
          ? [t.app, t.headline, if (t.raisedByName.isNotEmpty) 'Raised by ${t.raisedByName}'].join(' · ')
          : [t.app, t.headline, if (note.isNotEmpty) note].join(' · '),
      payload: 'ticket:${t.id}',
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

  /// Stable 31-bit id per ticket (FNV-1a).
  int _id(String ticketId) {
    var h = 0x811c9dc5;
    for (final c in 'ticket:$ticketId'.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }
}
