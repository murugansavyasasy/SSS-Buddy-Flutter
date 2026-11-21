import '../auth/model/ExhibitionModel.dart';

/// Numbers behind the Exhibition "Insights" tab, computed from the demos and
/// leads already loaded for the detail screen (no extra API call).

class DayActivity {
  final DateTime day;
  final int demos;
  final int leads;
  const DayActivity(this.day, this.demos, this.leads);
}

/// One team member's activity at an exhibition.
class PersonActivity {
  final String name;
  final int demos;
  final int leads;
  const PersonActivity(this.name, this.demos, this.leads);
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

  /// Demos per hour of day (24 entries, index = hour).
  final List<int> hours;

  /// Day with the most demos + leads (null with fewer than two days).
  final DayActivity? bestDay;

  /// Demos given / leads captured per person, most demos first.
  final List<PersonActivity> team;

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
    this.hours = const [],
    this.bestDay,
    this.team = const [],
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

  // ── Best day ──
  DayActivity? best;
  if (days.length > 1) {
    for (final d in days) {
      if (d.demos + d.leads > 0 &&
          (best == null || d.demos + d.leads > best.demos + best.leads)) {
        best = d;
      }
    }
  }

  // ── Team ──
  String norm(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
  final names = <String, String>{}; // lower-case key → display name
  final teamDemos = <String, int>{}, teamLeads = <String, int>{};
  void add(Map<String, int> m, String raw) {
    final name = norm(raw);
    if (name.isEmpty || RegExp(r'^\d+$').hasMatch(name)) return; // ids aren't names
    final key = name.toLowerCase();
    names.putIfAbsent(key, () => name);
    m.update(key, (v) => v + 1, ifAbsent: () => 1);
  }
  for (final d in demos) {
    add(teamDemos, d.createdBy);
  }
  for (final l in leads) {
    add(teamLeads, l.capturedBy);
  }
  final team = [
    for (final k in names.keys) PersonActivity(names[k]!, teamDemos[k] ?? 0, teamLeads[k] ?? 0),
  ]..sort((a, b) {
      final c = b.demos.compareTo(a.demos);
      if (c != 0) return c;
      final l = b.leads.compareTo(a.leads);
      return l != 0 ? l : a.name.compareTo(b.name);
    });

  return ExhibitionInsights(
    hours: [for (var h = 0; h < 24; h++) byHour[h] ?? 0],
    bestDay: best,
    team: team,
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

  /// Exhibitions in date order (oldest first, at most [trendN]): the points
  /// of the show-by-show trend line.
  final List<Exhibition> trend;

  const ExhibitionsOverview({
    required this.exhibitions,
    required this.active,
    required this.demos,
    required this.leads,
    required this.conversion,
    required this.top,
    required this.topByLeads,
    this.trend = const [],
  });

  static const topN = 5;
  static const trendN = 8;
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
  final dated = items.where((e) => (e.startDate ?? e.createdAt) != null).toList()
    ..sort((a, b) => (a.startDate ?? a.createdAt)!.compareTo((b.startDate ?? b.createdAt)!));
  final trend = dated.length > ExhibitionsOverview.trendN
      ? dated.sublist(dated.length - ExhibitionsOverview.trendN)
      : dated;
  return ExhibitionsOverview(
    trend: trend,
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

// ─────────────────────────────────────────────────────────────────────────
// Call results, per number dialled
// ─────────────────────────────────────────────────────────────────────────

/// Demo call results counted per number dialled (visitor and attendees),
/// not per demo: a demo to 5 numbers with 2 answered and 3 failed counts
/// as 2 answered + 3 not answered.
class CallResults {
  final int answered;
  final int failed;
  final int pending;

  /// Demos counted by their overall status because their numbers weren't
  /// available (detail not loaded or failed to load).
  final int demosWithoutNumbers;

  const CallResults({
    required this.answered,
    required this.failed,
    required this.pending,
    this.demosWithoutNumbers = 0,
  });

  int get total => answered + failed + pending;
}

CallResults countCallResults(List<ExhibitionDemo> demos) {
  var answered = 0, failed = 0, pending = 0, without = 0;
  void add(CallStatus s) {
    switch (s) {
      case CallStatus.answered:
      case CallStatus.completed:
        answered++;
      case CallStatus.failed:
        failed++;
      case CallStatus.queued:
      case CallStatus.ringing:
      case CallStatus.calling:
        pending++;
    }
  }

  for (final d in demos) {
    if (d.recipients.isEmpty) {
      without++;
      add(d.status);
    } else {
      for (final r in d.recipients) {
        add(r.status);
      }
    }
  }
  return CallResults(answered: answered, failed: failed, pending: pending, demosWithoutNumbers: without);
}
