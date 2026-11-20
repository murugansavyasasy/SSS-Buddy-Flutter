import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';
import 'package:sssbuddy/viewModel/exhibition_insights.dart';

ExhibitionDemo _demo(int id, DateTime at, String status) => ExhibitionDemo.fromJson({
      'id': id,
      'status': status,
      'createdAt': at.toIso8601String(),
    });

ExhibitionLead _lead(int id, DateTime at, String? level) => ExhibitionLead.fromJson({
      'id': id,
      'schoolName': 'S$id',
      'createdAt': at.toIso8601String(),
      if (level != null) 'interestLevel': level,
    });

void main() {
  final d1 = DateTime(2027, 9, 10, 11, 5);
  final d2 = DateTime(2027, 9, 11, 11, 40);
  final d3 = DateTime(2027, 9, 11, 15, 10);

  test('conversion, per-day buckets over the exhibition dates, interest, calls', () {
    final i = computeExhibitionInsights(
      demos: [_demo(1, d1, 'completed'), _demo(2, d2, 'failed'), _demo(3, d3, 'queued'), _demo(4, d2, 'answered')],
      leads: [_lead(1, d1, 'Excellent'), _lead(2, d2, 'Good'), _lead(3, d2, null)],
      startDate: DateTime(2027, 9, 10),
      endDate: DateTime(2027, 9, 12),
    );
    expect(i.demos, 4);
    expect(i.leads, 3);
    expect(i.conversion, closeTo(0.75, 1e-9));
    // All three exhibition days, including the quiet last day.
    expect(i.days.map((d) => (d.day.day, d.demos, d.leads)), [(10, 1, 1), (11, 3, 2), (12, 0, 0)]);
    expect(i.interest[InterestLevel.excellent], 1);
    expect(i.interest[InterestLevel.good], 1);
    expect(i.interest[InterestLevel.average], 0);
    expect(i.interestNotSet, 1);
    expect(i.busiestHour, 11); // 11:05, 11:40, 11:40
    expect(i.busiestHourDemos, 3);
    expect((i.reached, i.failed, i.pending), (2, 1, 1));
  });

  test('activity outside the exhibition dates falls back to the active range, capped to 14 days', () {
    final demos = [
      for (var k = 0; k < 30; k++) _demo(k, DateTime(2027, 1, 1).add(Duration(days: k)), 'completed'),
    ];
    final i = computeExhibitionInsights(
      demos: demos,
      leads: const [],
      startDate: DateTime(2027, 1, 1),
      endDate: DateTime(2027, 1, 2),
    );
    expect(i.days.length, ExhibitionInsights.maxDays);
    expect(i.days.last.day, DateTime(2027, 1, 30));
    expect(i.conversion, 0);
  });

  test('no demos: empty, no division by zero', () {
    final i = computeExhibitionInsights(demos: const [], leads: const []);
    expect(i.isEmpty, isTrue);
    expect(i.conversion, 0);
    expect(i.days, isEmpty);
    expect(i.busiestHour, isNull);
  });

  test('list overview: totals, conversion and top exhibitions by demos', () {
    Exhibition ex(int id, int demos, int leads, String status) => Exhibition.fromJson({
          'id': id,
          'name': 'E$id',
          'status': status,
          'demoCount': demos,
          'leadCount': leads,
        });
    final o = computeExhibitionsOverview([
      ex(1, 12, 5, 'active'),
      ex(2, 30, 11, 'completed'),
      ex(3, 0, 0, 'active'),
      ex(4, 30, 2, 'completed'),
    ]);
    expect((o.exhibitions, o.active, o.demos, o.leads), (4, 2, 72, 18));
    expect(o.conversion, closeTo(0.25, 1e-9));
    // Ties on demos fall back to leads; empty exhibitions are left out.
    expect(o.top.map((e) => e.id), ['2', '4', '1']);
    expect(o.topByLeads.map((e) => e.id), ['2', '1', '4']);
    final mix = interestMix([
      ExhibitionLead.fromJson({'id': 1, 'schoolName': 'a', 'interestLevel': 'Excellent'}),
      ExhibitionLead.fromJson({'id': 2, 'schoolName': 'b', 'interestLevel': 'Good'}),
      ExhibitionLead.fromJson({'id': 3, 'schoolName': 'c', 'interestLevel': 'Good'}),
      ExhibitionLead.fromJson({'id': 4, 'schoolName': 'd'}),
    ]);
    expect((mix.excellent, mix.good, mix.average, mix.notSet), (1, 2, 0, 1));
  });

  test('demos get "lead captured" from leads the server did not link', () {
    final demos = [
      ExhibitionDemo.fromJson({'id': 1, 'visitorName': 'Mrs. Lakshmi'}),
      ExhibitionDemo.fromJson({
        'id': 2,
        'visitorName': 'Kumar',
        'recipients': [
          {'mobile': '9811112222', 'recipientType': 'visitor'},
        ],
      }),
      ExhibitionDemo.fromJson({'id': 3, 'visitorName': 'Arun'}),
      ExhibitionDemo.fromJson({'id': 4, 'visitorName': 'Nobody'}),
      ExhibitionDemo.fromJson({'id': 5, 'visitorName': 'Server says yes', 'hasLead': true}),
    ];
    final leads = [
      ExhibitionLead.fromJson({'id': 1, 'schoolName': 'A', 'contactName': '  mrs.  lakshmi '}),
      ExhibitionLead.fromJson({'id': 2, 'schoolName': 'B', 'contactNumber': '+91 98111 12222'}),
      ExhibitionLead.fromJson({'id': 3, 'schoolName': 'C', 'demoId': 3}),
    ];
    final out = demosWithLeads(demos, leads);
    expect(out.map((d) => d.hasLead), [true, true, true, false, true]);
    expect(demosWithLeads(demos, const []).map((d) => d.hasLead), [false, false, false, false, true]);
  });

  test('capture lead sends the demo id when there is one', () {
    expect(const CaptureLeadRequest(schoolName: 'S', demoId: '51').toJson()['demoId'], '51');
    expect(const CaptureLeadRequest(schoolName: 'S').toJson().containsKey('demoId'), isFalse);
  });
}
