import '../auth/model/ExhibitionModel.dart';

/// Numbers behind the Exhibition "Insights" tab, computed from the demos and
/// leads already loaded for the detail screen (no extra API call).

class DayActivity {
  final DateTime day;
  final int demos;
  final int leads;
  const DayActivity(this.day, this.demos, this.leads);
}

class ExhibitionInsights {
  final int demos;
  final int leads;

  /// Leads ÷ demos (0 when there are no demos).
  final double conversion;

  /// One entry per day (oldest first), at most [maxDays].
  final List<DayActivity> days;

  /// Lead count per interest level; leads without a level count as `notSet`.
  final Map<InterestLevel, int> interest;
  final int interestNotSet;

  /// Hour of day (0–23) with the most demos, or null when no demo has a time.
  final int? busiestHour;
  final int busiestHourDemos;

  /// Demos whose call reached the visitor / failed / still in progress.
  final int reached;
  final int failed;
  final int pending;

  const ExhibitionInsights({
    required this.demos,
    required this.leads,
    required this.conversion,
    required this.days,
    required this.interest,
    required this.interestNotSet,
    required this.busiestHour,
    required this.busiestHourDemos,
    required this.reached,
    required this.failed,
    required this.pending,
  });

  static const maxDays = 14;

  bool get isEmpty => demos == 0 && leads == 0;
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

ExhibitionInsights computeExhibitionInsights({
  required List<ExhibitionDemo> demos,
  required List<ExhibitionLead> leads,
  DateTime? startDate,
  DateTime? endDate,
}) {
  // ── Per day ──
  final demoByDay = <DateTime, int>{};
  final leadByDay = <DateTime, int>{};
  for (final d in demos) {
    final t = d.createdAt;
    if (t != null) demoByDay.update(_day(t), (v) => v + 1, ifAbsent: () => 1);
  }
  for (final l in leads) {
    final t = l.createdAt;
    if (t != null) leadByDay.update(_day(t), (v) => v + 1, ifAbsent: () => 1);
  }
  final active = {...demoByDay.keys, ...leadByDay.keys}.toList()..sort();

  // Range: the exhibition's own dates when they are short and cover the
  // activity; otherwise first → last active day. Capped to the last 14.
  DateTime? from;
  DateTime? to;
  if (startDate != null && endDate != null) {
    final s = _day(startDate), e = _day(endDate);
    final span = e.difference(s).inDays;
    final covers = active.isEmpty || (!active.first.isBefore(s) && !active.last.isAfter(e));
    if (span >= 0 && span < ExhibitionInsights.maxDays && covers) {
      from = s;
      to = e;
    }
  }
  if (from == null && active.isNotEmpty) {
    from = active.first;
    to = active.last;
  }
  final days = <DayActivity>[];
  if (from != null && to != null) {
    var start = from;
    if (to.difference(start).inDays >= ExhibitionInsights.maxDays) {
      start = to.subtract(const Duration(days: ExhibitionInsights.maxDays - 1));
    }
    for (var d = start; !d.isAfter(to); d = DateTime(d.year, d.month, d.day + 1)) {
      days.add(DayActivity(d, demoByDay[d] ?? 0, leadByDay[d] ?? 0));
    }
  }

  // ── Interest ──
  final interest = {for (final l in InterestLevel.values) l: 0};
  var notSet = 0;
  for (final l in leads) {
    final level = l.interestLevel;
    if (level == null) {
      notSet++;
    } else {
      interest[level] = interest[level]! + 1;
    }
  }

  // ── Busiest hour ──
  final byHour = <int, int>{};
  for (final d in demos) {
    final t = d.createdAt;
    if (t != null) byHour.update(t.hour, (v) => v + 1, ifAbsent: () => 1);
  }
  int? busiest;
  var busiestN = 0;
  for (final e in byHour.entries) {
    if (e.value > busiestN || (e.value == busiestN && busiest != null && e.key < busiest)) {
      busiest = e.key;
      busiestN = e.value;
    }
  }

  // ── Call outcome ──
  var reached = 0, failed = 0, pending = 0;
  for (final d in demos) {
    switch (d.status) {
      case CallStatus.answered:
      case CallStatus.completed:
        reached++;
      case CallStatus.failed:
        failed++;
      case CallStatus.queued:
      case CallStatus.ringing:
      case CallStatus.calling:
        pending++;
    }
  }

  return ExhibitionInsights(
    demos: demos.length,
    leads: leads.length,
    conversion: demos.isEmpty ? 0 : leads.length / demos.length,
    days: days,
    interest: interest,
    interestNotSet: notSet,
    busiestHour: busiest,
    busiestHourDemos: busiestN,
    reached: reached,
    failed: failed,
    pending: pending,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Exhibitions list overview
// ─────────────────────────────────────────────────────────────────────────

class ExhibitionsOverview {
  final int exhibitions;
  final int active;
  final int demos;
  final int leads;
  final double conversion;

  /// Exhibitions with the most demos (then leads), at most [topN].
  final List<Exhibition> top;

  /// Exhibitions with the most leads (then demos), at most [topN]: the
  /// rows of the lead-interest chart.
  final List<Exhibition> topByLeads;

  const ExhibitionsOverview({
    required this.exhibitions,
    required this.active,
    required this.demos,
    required this.leads,
    required this.conversion,
    required this.top,
    required this.topByLeads,
  });

  static const topN = 5;
}

ExhibitionsOverview computeExhibitionsOverview(List<Exhibition> items) {
  var demos = 0, leads = 0, active = 0;
  for (final e in items) {
    demos += e.demoCount;
    leads += e.leadCount;
    if (e.status == ExhibitionStatus.active) active++;
  }
  final top = items.where((e) => e.demoCount > 0 || e.leadCount > 0).toList()
    ..sort((a, b) {
      final c = b.demoCount.compareTo(a.demoCount);
      return c != 0 ? c : b.leadCount.compareTo(a.leadCount);
    });
  final byLeads = items.where((e) => e.leadCount > 0).toList()
    ..sort((a, b) {
      final c = b.leadCount.compareTo(a.leadCount);
      return c != 0 ? c : b.demoCount.compareTo(a.demoCount);
    });
  return ExhibitionsOverview(
    exhibitions: items.length,
    active: active,
    demos: demos,
    leads: leads,
    conversion: demos == 0 ? 0 : leads / demos,
    top: top.take(ExhibitionsOverview.topN).toList(),
    topByLeads: byLeads.take(ExhibitionsOverview.topN).toList(),
  );
}

/// Lead count per interest level for one exhibition's leads.
({int excellent, int good, int average, int notSet}) interestMix(List<ExhibitionLead> leads) {
  var ex = 0, gd = 0, av = 0, ns = 0;
  for (final l in leads) {
    switch (l.interestLevel) {
      case InterestLevel.excellent:
        ex++;
      case InterestLevel.good:
        gd++;
      case InterestLevel.average:
        av++;
      case null:
        ns++;
    }
  }
  return (excellent: ex, good: gd, average: av, notSet: ns);
}
