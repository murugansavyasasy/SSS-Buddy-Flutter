import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/TicketModel.dart';
import '../core/ticket/ticket_completion_notifier.dart';
import '../provider/app_providers.dart';
import '../repository/ticket_repository.dart';
import 'login_view_model.dart';
import 'reporting_members_dd_viewmodel.dart';

/// false = demo mode (tickets on this phone only). Set true once the backend
/// implements docs/TICKET_API.md.
const bool kTicketsUseApi = false;

final ticketRepositoryProvider = Provider<TicketRepository>(
  (ref) => kTicketsUseApi ? ApiTicketRepository(ref.read(dioProvider)) : LocalTicketRepository(),
);

/// The logged-in user as the Tickets module sees them.
typedef TicketUser = ({String id, String name, bool canManage});

final ticketUserProvider = FutureProvider<TicketUser?>((ref) async {
  final login = await ref.watch(loginProvider.future);
  if (login == null) return null;
  return (
    id: login.userId.toString(),
    name: login.name,
    canManage: canManageTickets(login.roleCode),
  );
});

Duration? _noRetry(int retryCount, Object error) => null;

/// Admin / Support: every ticket. Everyone else: the tickets they raised.
/// Newest first. Also runs the "ticket completed" check.
final ticketsProvider = FutureProvider.autoDispose<List<Ticket>>(retry: _noRetry, (ref) async {
  final user = await ref.watch(ticketUserProvider.future);
  if (user == null) return [];
  final items = await ref
      .read(ticketRepositoryProvider)
      .fetchTickets(userId: user.id, all: user.canManage);
  await TicketCompletionNotifier.instance.check(items, user.id, userName: user.name);
  return [...items]
    ..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
});

/// Watched by the dashboard: checks the user's tickets when it opens and
/// every time the app comes back to the foreground, and notifies for any
/// that were completed meanwhile.
final ticketCompletionWatchProvider = FutureProvider<void>((ref) async {
  final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(listener.dispose);
  final user = await ref.watch(ticketUserProvider.future);
  if (user == null) return;
  try {
    final mine = await ref
        .read(ticketRepositoryProvider)
        .fetchTickets(userId: user.id, all: false);
    await TicketCompletionNotifier.instance.check(mine, user.id, userName: user.name);
  } catch (_) {
    // Offline or API down: try again on the next resume.
  }
});

/// People a ticket can be assigned to: the API's list when it has one,
/// otherwise the user's reporting members, with the user first ("Me").
final ticketAssigneesProvider = FutureProvider.autoDispose<List<TicketAssignee>>((ref) async {
  final user = await ref.watch(ticketUserProvider.future);
  final fromApi = await ref.read(ticketRepositoryProvider).fetchAssignees().catchError((_) => <TicketAssignee>[]);
  final list = <TicketAssignee>[...fromApi];
  if (list.isEmpty) {
    try {
      final members = await ref.read(reportingmembersProvider.future);
      list.addAll(members.map((m) => (id: '${m.idmember}', name: m.membername.trim())));
    } catch (_) {}
  }
  final seen = <String>{};
  final out = <TicketAssignee>[
    if (user != null) (id: user.id, name: user.name),
  ];
  seen.addAll(out.map((a) => a.id));
  for (final a in list..sort((x, y) => x.name.toLowerCase().compareTo(y.name.toLowerCase()))) {
    if (a.name.isNotEmpty && seen.add(a.id)) out.add(a);
  }
  return out;
});

/// Admin / Support, or the person the ticket is assigned to.
bool canChangeTicketStatus(Ticket t, TicketUser? user) =>
    user != null && (user.canManage || (t.assignedToId.isNotEmpty && t.assignedToId == user.id));

/// Open + In Progress tickets: the dashboard badge. For Admin / Support it
/// counts every user's tickets (work to do); for others their own.
final openTicketCountProvider = Provider<int>((ref) {
  final items = ref.watch(ticketsProvider).value ?? const [];
  return items.where((t) => t.status != TicketStatus.completed).length;
});

class TicketActions {
  final Ref _ref;
  TicketActions(this._ref);

  TicketRepository get _repo => _ref.read(ticketRepositoryProvider);

  Future<TicketUser> _user() async {
    final u = await _ref.read(ticketUserProvider.future);
    if (u == null) throw StateError('Please log in again.');
    return u;
  }

  /// [files] = local image / video paths; uploaded one by one, with
  /// [onUploading] (1-based index, total) for the progress label.
  Future<Ticket> raise({
    required String app,
    required String description,
    required TicketPriority priority,
    TicketAssignee? assignee,
    String deviceName = '',
    String deviceModel = '',
    List<String> files = const [],
    void Function(int index, int total)? onUploading,
  }) async {
    final user = await _user();
    final attachments = <TicketAttachment>[];
    for (var i = 0; i < files.length; i++) {
      onUploading?.call(i + 1, files.length);
      final url = await _repo.uploadAttachment(files[i]);
      attachments.add(TicketAttachment(
        url: url,
        type: isTicketVideoPath(files[i])
            ? TicketAttachmentType.video
            : TicketAttachmentType.image,
      ));
    }
    final t = await _repo.createTicket(
      CreateTicketRequest(
        app: app,
        description: description,
        priority: priority,
        attachments: attachments,
        assignee: assignee,
        deviceName: deviceName,
        deviceModel: deviceModel,
        platform: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      ),
      userId: user.id,
      userName: user.name,
    );
    _ref.invalidate(ticketsProvider);
    return t;
  }

  /// Admin / Support, or the assignee.
  Future<Ticket> changeStatus(Ticket t, TicketStatus status, {String note = ''}) async {
    final user = await _user();
    if (!canChangeTicketStatus(t, user)) {
      throw StateError('Only Admin, Support or the assignee can change the status.');
    }
    final updated = await _repo.updateStatus(t.id, status, note: note, byName: user.name);
    _ref.invalidate(ticketsProvider);
    return updated;
  }
}

extension TicketAssign on TicketActions {
  /// Anyone can assign any ticket to anyone ([to] null = unassign).
  Future<Ticket> assign(Ticket t, TicketAssignee? to) async {
    final user = await _user();
    final updated = await _repo.assign(t.id, to, byName: user.name);
    _ref.invalidate(ticketsProvider);
    return updated;
  }
}

final ticketActionsProvider = Provider<TicketActions>((ref) => TicketActions(ref));
