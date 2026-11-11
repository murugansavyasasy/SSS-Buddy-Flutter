import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sssbuddy/auth/model/FollowUpModel.dart';
import 'package:sssbuddy/repository/followup_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  FollowUp draft(String owner, {DateTime? due}) => FollowUp(
        ownerId: owner,
        ownerName: 'Test',
        schoolName: 'ABC School',
        contactPhone: '9876543210',
        type: FollowUpType.call,
        dueAt: due ?? DateTime.now().add(const Duration(days: 1)),
      );

  test('create, update, delete round-trip per owner', () async {
    final repo = LocalFollowUpRepository();
    final a = await repo.create(draft('1'));
    await repo.create(draft('2'));
    expect(a.id, isNotEmpty);
    expect((await repo.fetchAll('1')).single.schoolName, 'ABC School');

    await repo.update(a.copyWith(status: FollowUpStatus.done, outcome: 'Interested'));
    final stored = (await repo.fetchAll('1')).single;
    expect(stored.status, FollowUpStatus.done);
    expect(stored.outcome, 'Interested');

    await repo.delete('1', a.id);
    expect(await repo.fetchAll('1'), isEmpty);
    expect(await repo.fetchAll('2'), hasLength(1));
  });

  test('overdue / today / reminder time', () {
    final past = draft('1', due: DateTime.now().subtract(const Duration(hours: 2)));
    expect(past.isOverdue, isTrue);
    final f = draft('1').copyWith(remindBefore: 60);
    expect(f.remindAt, f.dueAt.subtract(const Duration(hours: 1)));
    expect(draft('1').copyWith(remindBefore: -1).remindAt, isNull);
  });
}
