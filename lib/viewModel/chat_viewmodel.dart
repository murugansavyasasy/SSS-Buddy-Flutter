import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/ChatModels.dart';
import '../core/chat/chat_notification_service.dart';
import '../core/chat/chat_service.dart';
import '../utils/app_logger.dart';
import 'login_view_model.dart';
import 'reporting_members_dd_viewmodel.dart';

/// Team members reporting to the logged-in user (self excluded).
final chatTeamProvider = FutureProvider<List<ChatContact>>((ref) async {
  final me = (await ref.watch(loginProvider.future));
  if (me == null) return [];
  final members = await ref.watch(reportingmembersProvider.future);
  return members
      .where((m) => m.idmember != me.userId)
      .map((m) => ChatContact(
            id: m.idmember.toString(),
            name: m.membername,
            isTeamMember: true,
          ))
      .toList();
});

/// Connects to Firebase for the logged-in user, registers for push and
/// keeps the manager's team group in sync. Null when logged out.
final chatSessionProvider = FutureProvider<ChatMe?>((ref) async {
  final login = await ref.watch(loginProvider.future);
  if (login == null || !ChatService.instance.isReady) return null;

  final me = ChatMe(
    id: login.userId.toString(),
    name: login.name,
    role: login.roleName,
  );
  await ChatService.instance.connect(me);
  ChatNotificationService.instance.registerUser(me.id);

  try {
    final team = await ref.read(chatTeamProvider.future);
    await ChatService.instance.syncTeamGroup(me, team);
  } catch (e) {
    AppLogger.error('Team group sync failed: $e');
  }
  return me;
});

final chatThreadsProvider = StreamProvider<List<ChatThread>>((ref) async* {
  final me = await ref.watch(chatSessionProvider.future);
  if (me == null) {
    yield [];
    return;
  }
  yield* ChatService.instance.threads(me.id);
});

final chatUnreadTotalProvider = Provider<int>((ref) {
  final me = ref.watch(chatSessionProvider).value;
  final threads = ref.watch(chatThreadsProvider).value;
  if (me == null || threads == null) return 0;
  return threads.fold(0, (sum, t) => sum + t.unreadFor(me.id));
});

final chatThreadProvider =
    StreamProvider.autoDispose.family<ChatThread?, String>(
  (ref, chatId) => ChatService.instance.thread(chatId),
);

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, chatId) => ChatService.instance.messages(chatId),
);

/// My team first, then every other colleague who has opened chat at least once.
final chatContactsProvider =
    FutureProvider.autoDispose<List<ChatContact>>((ref) async {
  final me = await ref.watch(chatSessionProvider.future);
  if (me == null) return [];
  final team = await ref.watch(chatTeamProvider.future);
  final teamIds = team.map((c) => c.id).toSet();

  final others = (await ChatService.instance.registeredUsers())
      .where((c) => c.id != me.id && !teamIds.contains(c.id))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final sortedTeam = [...team]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return [...sortedTeam, ...others];
});
