import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sssbuddy/auth/model/TicketModel.dart';
import 'package:sssbuddy/repository/ticket_repository.dart';
import 'package:sssbuddy/viewModel/ticket_viewmodel.dart';

void main() {
  test('status and priority parse the API values', () {
    for (final s in TicketStatus.values) {
      expect(parseTicketStatus(s.apiValue), s);
    }
    expect(parseTicketStatus('In Progress'), TicketStatus.inProgress);
    expect(parseTicketStatus('in_progress'), TicketStatus.inProgress);
    expect(parseTicketStatus('COMPLETED'), TicketStatus.completed);
    expect(parseTicketStatus(''), TicketStatus.open);
    expect(TicketStatus.inProgress.apiValue, 'InProgress');

    for (final p in TicketPriority.values) {
      expect(parseTicketPriority(p.apiValue), p);
    }
    expect(parseTicketPriority('unknown'), TicketPriority.medium);
  });

  test('only Admin and Support manage tickets', () {
    expect(canManageTickets('Admin'), isTrue);
    expect(canManageTickets(' support '), isTrue);
    expect(canManageTickets('MyTeam'), isFalse);
    expect(canManageTickets(''), isFalse);
  });

  test('ticket JSON round trip keeps history', () {
    final t = Ticket(
      id: '42',
      app: 'School Chimes',
      description: 'Circular not sending\nTried twice',
      priority: TicketPriority.high,
      status: TicketStatus.completed,
      raisedById: '7',
      raisedByName: 'Ravi',
      createdAt: DateTime(2026, 11, 20, 10),
      attachments: const [
        TicketAttachment(url: 'https://s3/a.jpg', type: TicketAttachmentType.image),
        TicketAttachment(url: 'https://s3/b.mp4', type: TicketAttachmentType.video),
      ],
      history: [
        TicketHistory(status: TicketStatus.open, byName: 'Ravi', at: DateTime(2026, 11, 20, 10)),
        TicketHistory(
            status: TicketStatus.completed,
            note: 'Fixed in 1.0.1',
            byName: 'Support',
            at: DateTime(2026, 11, 20, 12)),
      ],
    );
    final back = Ticket.fromJson(t.toJson());
    expect(back.id, '42');
    expect(back.app, 'School Chimes');
    expect(back.headline, 'Circular not sending');
    expect(back.attachments.map((a) => a.type),
        [TicketAttachmentType.image, TicketAttachmentType.video]);
    expect(back.status, TicketStatus.completed);
    expect(back.priority, TicketPriority.high);
    expect(back.history.length, 2);
    expect(back.latestNote, 'Fixed in 1.0.1');
    expect(back.createdAt, t.createdAt);
  });

  test('attachments: video detected by extension, plain URL lists accepted', () {
    expect(isTicketVideoPath('/tmp/clip.MOV'), isTrue);
    expect(isTicketVideoPath('https://s3/x.mp4?X-Amz=1'), isTrue);
    expect(isTicketVideoPath('/tmp/shot.jpg'), isFalse);
    expect(ticketAttachmentContentType('a.mp4'), 'video/mp4');
    expect(ticketAttachmentContentType('a.mov'), 'video/quicktime');
    expect(ticketAttachmentContentType('a.jpg'), 'image/jpeg');

    final t = Ticket.fromJson({
      'id': 1,
      'app': '',
      'attachments': ['https://s3/a.png', 'https://s3/b.mp4', ''],
    });
    expect(t.app, 'Other');
    expect(t.attachments.length, 2);
    expect(t.attachments.last.isVideo, isTrue);
  });

  group('newlyCompletedTickets', () {
    Ticket t(String id, TicketStatus s, {String by = '7'}) =>
        Ticket(id: id, status: s, raisedById: by);

    test('notifies only for my tickets that just became Completed', () {
      final tickets = [
        t('1', TicketStatus.completed), // was InProgress → notify
        t('2', TicketStatus.completed), // already Completed → no
        t('3', TicketStatus.completed), // never seen → no (first sync)
        t('4', TicketStatus.inProgress), // not completed → no
        t('5', TicketStatus.completed, by: '9'), // someone else's → no
      ];
      final seen = {
        '1': 'InProgress',
        '2': 'Completed',
        '4': 'Open',
        '5': 'Open',
      };
      expect(newlyCompletedTickets(tickets, seen, '7').map((e) => e.id), ['1']);
    });

    test('a reopened then completed ticket notifies again', () {
      final tickets = [t('1', TicketStatus.completed)];
      expect(newlyCompletedTickets(tickets, {'1': 'Open'}, '7').length, 1);
    });
  });

  group('LocalTicketRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('users see their own tickets; managers see all', () async {
      final repo = LocalTicketRepository();
      await repo.createTicket(const CreateTicketRequest(app: 'Gradit', description: 'A'),
          userId: '1', userName: 'Ravi');
      await repo.createTicket(const CreateTicketRequest(app: 'SSS Score', description: 'B'),
          userId: '2', userName: 'Priya');

      final mine = await repo.fetchTickets(userId: '1', all: false);
      expect(mine.map((t) => t.description), ['A']);
      expect(mine.single.app, 'Gradit');
      expect(mine.single.status, TicketStatus.open);
      expect(mine.single.history.single.byName, 'Ravi');

      final all = await repo.fetchTickets(userId: '9', all: true);
      expect(all.length, 2);
    });

    test('status change is stored with a history entry', () async {
      final repo = LocalTicketRepository();
      final t = await repo.createTicket(
          const CreateTicketRequest(app: "Let's Reach", description: 'A'),
          userId: '1',
          userName: 'Ravi');
      await repo.updateStatus(t.id, TicketStatus.completed, note: 'Fixed', byName: 'Support');

      final stored = (await repo.fetchTickets(userId: '1', all: false)).single;
      expect(stored.status, TicketStatus.completed);
      expect(stored.history.map((h) => h.status),
          [TicketStatus.open, TicketStatus.completed]);
      expect(stored.latestNote, 'Fixed');
    });
  });

  group('assignment', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('anyone can assign; the assignee sees it in "mine"; history records it', () async {
      final repo = LocalTicketRepository();
      final t = await repo.createTicket(const CreateTicketRequest(app: 'Gradit', description: 'A'),
          userId: '1', userName: 'Ravi');
      await repo.assign(t.id, (id: '5', name: 'Priya'), byName: 'Ravi');

      final forPriya = await repo.fetchTickets(userId: '5', all: false);
      expect(forPriya.single.assignedToName, 'Priya');
      expect(forPriya.single.history.last.isAssign, isTrue);
      expect(forPriya.single.history.last.assignedToName, 'Priya');

      await repo.assign(t.id, null, byName: 'Priya');
      final after = (await repo.fetchTickets(userId: '1', all: false)).single;
      expect(after.isAssigned, isFalse);
      expect(after.history.last.assignedToName, '');
      expect(await repo.fetchTickets(userId: '5', all: false), isEmpty);
    });

    test('assign while raising', () async {
      final repo = LocalTicketRepository();
      final t = await repo.createTicket(
          const CreateTicketRequest(app: 'Gradit', description: 'A', assignee: (id: '9', name: 'Kavin')),
          userId: '1',
          userName: 'Ravi');
      expect(t.assignedToId, '9');
      expect(t.history.map((h) => h.event), ['status', 'assign']);
      final back = Ticket.fromJson(t.toJson());
      expect(back.assignedToName, 'Kavin');
      expect(back.history.last.isAssign, isTrue);
    });

    test('assignee may change status; others may not (unless Admin / Support)', () {
      const t = Ticket(id: '1', assignedToId: '5');
      expect(canChangeTicketStatus(t, (id: '5', name: 'P', canManage: false)), isTrue);
      expect(canChangeTicketStatus(t, (id: '6', name: 'Q', canManage: false)), isFalse);
      expect(canChangeTicketStatus(t, (id: '6', name: 'Q', canManage: true)), isTrue);
      expect(canChangeTicketStatus(const Ticket(id: '2'), (id: '6', name: 'Q', canManage: false)), isFalse);
    });

    test('newly assigned: notifies once, not on first check, not for self-assign', () {
      Ticket t(String id, String by) => Ticket(
            id: id,
            assignedToId: '5',
            history: [TicketHistory(status: TicketStatus.open, event: 'assign', byName: by, assignedToName: 'Priya')],
          );
      final tickets = [t('1', 'Ravi'), t('2', 'Priya'), t('3', 'Ravi')];
      expect(newlyAssignedTickets(tickets, {}, '5', firstCheck: true, myName: 'Priya'), isEmpty);
      expect(
        newlyAssignedTickets(tickets, {'3'}, '5', firstCheck: false, myName: 'Priya').map((e) => e.id),
        ['1'],
      );
    });
  });

  test('device name / model are optional and round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalTicketRepository();
    final a = await repo.createTicket(
        const CreateTicketRequest(app: 'Gradit', description: 'x', deviceName: ' Redmi Note 12 ', deviceModel: 'Android 14', platform: 'android 15'),
        userId: '1',
        userName: 'R');
    expect(a.deviceLabel, 'Redmi Note 12 · Android 14');
    expect(Ticket.fromJson(a.toJson()).deviceName, 'Redmi Note 12');
    final b = await repo.createTicket(const CreateTicketRequest(app: 'Gradit', description: 'y', platform: 'ios 18'),
        userId: '1', userName: 'R');
    expect(b.deviceLabel, 'ios 18'); // falls back to the detected platform
    expect(const CreateTicketRequest(app: 'G', description: 'z').toJson()['deviceName'], '');
  });
}
