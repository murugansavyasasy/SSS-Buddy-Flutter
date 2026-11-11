import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/FollowUpModel.dart';
import '../core/followup/followup_reminders.dart';
import '../repository/followup_repository.dart';
import 'login_view_model.dart';

/// Swap this for an API / Firebase implementation once decided.
final followUpRepositoryProvider =
    Provider<FollowUpRepository>((ref) => LocalFollowUpRepository());

class FollowUpViewModel extends AsyncNotifier<List<FollowUp>> {
  String _ownerId = '';
  String _ownerName = '';

  String get ownerId => _ownerId;

  String get ownerName => _ownerName;

  FollowUpRepository get _repo => ref.read(followUpRepositoryProvider);

  @override
  Future<List<FollowUp>> build() async {
    final login = await ref.watch(loginProvider.future);
    if (login == null) return [];
    _ownerId = login.userId.toString();
    _ownerName = login.name;
    final items = await _repo.fetchAll(_ownerId);
    FollowUpReminders.instance.sync(items);
    return _sorted(items);
  }

  List<FollowUp> get _items => state.value ?? const [];

  List<FollowUp> _sorted(List<FollowUp> items) =>
      [...items]..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  void _set(List<FollowUp> items) {
    final sorted = _sorted(items);
    state = AsyncData(sorted);
    FollowUpReminders.instance.sync(sorted);
  }

  /// Draft with the current user as owner, for the add form.
  FollowUp draft({
    required String schoolName,
    String schoolId = '',
    String contactName = '',
    String contactPhone = '',
    required FollowUpType type,
    required DateTime dueAt,
    int remindBefore = 15,
    String note = '',
    String demoId = '',
  }) =>
      FollowUp(
        ownerId: _ownerId,
        ownerName: _ownerName,
        schoolId: schoolId,
        schoolName: schoolName,
        contactName: contactName,
        contactPhone: contactPhone,
        type: type,
        dueAt: dueAt,
        remindBefore: remindBefore,
        note: note,
        demoId: demoId,
      );

  Future<void> save(FollowUp f) async {
    if (f.id.isEmpty) {
      final stored = await _repo.create(f);
      _set([..._items, stored]);
    } else {
      await _repo.update(f);
      _set([for (final x in _items) x.id == f.id ? f : x]);
    }
  }

  Future<void> delete(FollowUp f) async {
    await _repo.delete(f.ownerId, f.id);
    _set(_items.where((x) => x.id != f.id).toList());
  }

  Future<void> reschedule(FollowUp f, DateTime dueAt) =>
      save(f.copyWith(dueAt: dueAt));

  /// Marks [f] done, optionally creating the next follow-up for the same school.
  Future<void> complete(FollowUp f, {required String outcome, FollowUp? next}) async {
    final done = f.copyWith(
      status: FollowUpStatus.done,
      outcome: outcome,
      completedAt: DateTime.now(),
    );
    await _repo.update(done);
    var items = [for (final x in _items) x.id == f.id ? done : x];
    if (next != null) {
      items = [...items, await _repo.create(next)];
    }
    _set(items);
  }

  Future<void> reopen(FollowUp f) => save(FollowUp(
        id: f.id,
        ownerId: f.ownerId,
        ownerName: f.ownerName,
        schoolId: f.schoolId,
        schoolName: f.schoolName,
        contactName: f.contactName,
        contactPhone: f.contactPhone,
        type: f.type,
        dueAt: f.dueAt,
        remindBefore: f.remindBefore,
        note: f.note,
        demoId: f.demoId,
      ));
}

final followUpProvider =
    AsyncNotifierProvider<FollowUpViewModel, List<FollowUp>>(
  () => FollowUpViewModel(),
);

/// Overdue + due today, shown as the dashboard badge.
final followUpDueCountProvider = Provider<int>((ref) {
  final items = ref.watch(followUpProvider).value ?? const [];
  return items.where((f) => f.isPending && (f.isOverdue || f.isToday)).length;
});
