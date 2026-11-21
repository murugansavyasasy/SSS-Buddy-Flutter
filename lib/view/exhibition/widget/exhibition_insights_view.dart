import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/model/ExhibitionModel.dart';
import '../../../viewModel/exhibition_insights.dart';
import '../../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_charts.dart';
import 'exhibition_common.dart';

/// "Insights" tab of an exhibition. Every card says in plain words what it
/// shows, has an ⓘ sheet on how to read it, and ends with a takeaway, so a
/// salesperson understands it at a glance. Built from the demos and leads
/// the detail screen already loaded (no extra API call).
///
/// Interest uses an ordinal orange ramp (validated): Average `#F09466` →
/// Good `#EB6834` → Excellent `#A8400F`; Not set is neutral grey.
const _interestC = {
  InterestLevel.average: Color(0xFFF09466),
  InterestLevel.good: Color(0xFFEB6834),
  InterestLevel.excellent: Color(0xFFA8400F),
};
const _notSetC = Color(0xFFD9DEE7);

// Status colours: reserved for call results, always with icon + label.
const _good = Color(0xFF0CA30C);
const _critical = Color(0xFFD03B3B);
const _pendingC = Color(0xFF8A94A6);
const _teamC = Color(0xFF7A5AF8);

String _hourRange(int h) {
  String f(int x) => DateFormat('h a').format(DateTime(2000, 1, 1, x % 24));
  return '${f(h)} – ${f(h + 1)}';
}

String _plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

class ExhibitionInsightsView extends ConsumerWidget {
  final Exhibition exhibition;
  final List<ExhibitionDemo> demos;
  final List<ExhibitionLead> leads;

  const ExhibitionInsightsView({
    super.key,
    required this.exhibition,
    required this.demos,
    required this.leads,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The demo list leaves out each number's call status: load every demo's
    // detail (cached; the same one the expanded demo card uses).
    var loading = 0, failedLoads = 0;
    final resolved = <ExhibitionDemo>[
      for (final d in demos)
        if (d.recipients.isNotEmpty || d.id.isEmpty)
          d
        else
          ref.watch(exhibitionDemoDetailProvider(d.id)).when(
                data: (detail) => d.mergedWith(detail),
                loading: () {
                  loading++;
                  return d;
                },
                error: (_, __) {
                  failedLoads++;
                  return d;
                },
              ),
    ];
    final calls = _CallsState(
      results: countCallResults(resolved),
      loading: loading,
      failedLoads: failedLoads,
      onRetry: () {
        for (final d in demos) {
          if (d.id.isNotEmpty) ref.invalidate(exhibitionDemoDetailProvider(d.id));
        }
      },
    );
    final i = computeExhibitionInsights(
      demos: demos,
      leads: leads,
      startDate: exhibition.startDate,
      endDate: exhibition.endDate,
    );
    if (i.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: ExStateView(
          icon: Icons.insights_rounded,
          title: 'No activity yet',
          message: 'Charts appear here after the first demo.',
        ),
      );
    }
    final cards = <Widget>[
      _SummaryCard(i: i, calls: calls),
      if (i.days.length > 1) _TrendCard(i: i),
      if (i.busiestHour != null) _HoursCard(i: i),
      if (i.leads > 0) _LeadQualityCard(i: i),
      if (i.demos > 0) _CallResultsCard(calls: calls),
      if (i.team.isNotEmpty) _TeamCard(i: i),
    ];
    return LayoutBuilder(builder: (context, box) {
      // Summary full width; two columns below it on wide panes (iPad).
      if (box.maxWidth >= 720 && cards.length > 2) {
        final left = <Widget>[], right = <Widget>[];
        for (var k = 1; k < cards.length; k++) {
          (k.isOdd ? left : right).add(ExAppear(index: k, child: cards[k]));
        }
        Widget col(List<Widget> c) => Column(
              children: [for (final w in c) Padding(padding: const EdgeInsets.only(bottom: 14), child: w)],
            );
        return Column(
          children: [
            Padding(padding: const EdgeInsets.only(bottom: 14), child: ExAppear(child: cards.first)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: col(left)), const SizedBox(width: 14), Expanded(child: col(right))],
            ),
          ],
        );
      }
      return Column(
        children: [
          for (var k = 0; k < cards.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ExAppear(index: k, child: cards[k]),
            ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────
// At a glance: conversion ring + the key facts in words
// ─────────────────────────────────────────────────────────────────────────

/// Per-number call results plus how many demo details are still loading
/// or failed to load.
class _CallsState {
  final CallResults results;
  final int loading;
  final int failedLoads;
  final VoidCallback onRetry;
  const _CallsState({required this.results, required this.loading, required this.failedLoads, required this.onRetry});
}

class _SummaryCard extends StatelessWidget {
  final ExhibitionInsights i;
  final _CallsState calls;
  const _SummaryCard({required this.i, required this.calls});

  @override
  Widget build(BuildContext context) {
    final pct = (i.conversion * 100).round();
    final white70 = Colors.white.withValues(alpha: 0.78);
    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      maxLines: 1,
                      style: const TextStyle(
                          fontFamily: exFont, fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(label, maxLines: 1, style: TextStyle(fontSize: 11.5, color: white70)),
                ),
              ],
            ),
          ),
        );
    final facts = <(IconData, String)>[
      if (i.bestDay != null)
        (
          Icons.emoji_events_rounded,
          'Best day: ${DateFormat('EEE, d MMM').format(i.bestDay!.day)} '
              '(${_plural(i.bestDay!.demos, 'demo')}, ${_plural(i.bestDay!.leads, 'lead')})'
        ),
      if (i.busiestHour != null)
        (Icons.schedule_rounded, 'Most visitors: ${_hourRange(i.busiestHour!)}'),
      if (i.team.isNotEmpty && i.team.first.demos > 0)
        (Icons.military_tech_rounded, 'Top performer: ${i.team.first.name} (${_plural(i.team.first.demos, 'demo')})'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), exBrandBold, Color(0xFF0891B2)],
        ),
        borderRadius: BorderRadius.circular(exRadiusCard + 2),
        boxShadow: exBrandGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text('At a glance',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: white70, letterSpacing: 0.3)),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  tooltip: 'What is conversion?',
                  padding: EdgeInsets.zero,
                  onPressed: () => showExChartHelp(context, title: 'Demo → lead conversion', help: _conversionHelp),
                  icon: Icon(Icons.info_outline_rounded, size: 19, color: white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ExRingGauge(
                value: i.conversion.clamp(0.0, 1.0),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExCountUp(pct,
                        style: const TextStyle(
                            fontFamily: exFont, fontSize: 28, height: 1, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('% converted', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: white70)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Demo → lead conversion',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(exConversionWords(i.demos, i.leads),
                        style: const TextStyle(
                            fontFamily: exFont, fontSize: 18, height: 1.25, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat('${i.demos}', 'Demos given'),
              const SizedBox(width: 8),
              stat('${i.leads}', 'Leads captured'),
              const SizedBox(width: 8),
              stat(calls.loading > 0 ? '…' : '${calls.results.answered}', 'Calls answered'),
            ],
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final (icon, text) in facts)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 16, color: const Color(0xFFFFD36B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(text,
                          style: const TextStyle(fontSize: 13.5, height: 1.3, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

const _conversionHelp = ExChartHelp(
  what: 'How many of the demos you gave turned into a lead (a school that showed interest and whose details you captured).',
  howToRead: [
    'The ring fills up to the conversion percentage. A full ring would mean every demo became a lead.',
    'Conversion = leads ÷ demos. 10 demos and 4 leads = 40%.',
    '"Calls answered" counts demos whose voice call the visitor picked up.',
  ],
  why: 'A low percentage means many visitors heard the demo but did not become leads. Ask the team to capture details right after a good conversation.',
);

// ─────────────────────────────────────────────────────────────────────────
// Day-by-day line chart (per day / running total)
// ─────────────────────────────────────────────────────────────────────────

class _TrendCard extends StatefulWidget {
  final ExhibitionInsights i;
  const _TrendCard({required this.i});

  @override
  State<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<_TrendCard> {
  int _mode = 0; // 0 = each day, 1 = running total

  @override
  Widget build(BuildContext context) {
    final days = widget.i.days;
    List<double> run(List<int> v) {
      var s = 0;
      return [for (final x in v) (s += x).toDouble()];
    }

    final demos = [for (final d in days) d.demos];
    final leads = [for (final d in days) d.leads];
    final cumulative = _mode == 1;
    final best = widget.i.bestDay;
    return ExChartCard(
      icon: Icons.show_chart_rounded,
      accent: exChartDemo,
      title: 'Demos & leads by day',
      subtitle: cumulative
          ? 'Total so far, adding up day after day.'
          : 'How many demos were given and leads captured on each day.',
      help: const ExChartHelp(
        what: 'One point per day of the exhibition. The blue line is demos given that day, the orange line is leads captured.',
        howToRead: [
          'Tap or slide your finger on the chart to see the exact numbers for a day.',
          'A line going up means a busier day; a dip means fewer visitors.',
          'When the orange line stays close to the blue line, most demos are turning into leads.',
          '"Running total" adds the days together so you can see the overall growth.',
        ],
        why: 'Shows which days brought the most interest, so you can plan staff and follow-ups for the next exhibition.',
      ),
      trailing: ExChartSwitch(
        options: const ['Each day', 'Running total'],
        selected: _mode,
        onChanged: (m) => setState(() => _mode = m),
      ),
      takeaway: best == null
          ? null
          : 'Best day was ${DateFormat('EEEE, d MMM').format(best.day)} with '
              '${_plural(best.demos, 'demo')} and ${_plural(best.leads, 'lead')}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExLegend(items: [(exChartDemo, 'Demos'), (exChartLead, 'Leads')]),
          const SizedBox(height: 10),
          ExLineChart(
            key: ValueKey(_mode),
            series: [
              ExLineSeries('Demos', exChartDemo, cumulative ? run(demos) : [for (final v in demos) v.toDouble()]),
              ExLineSeries('Leads', exChartLead, cumulative ? run(leads) : [for (final v in leads) v.toDouble()]),
            ],
            xLabels: [for (final d in days) DateFormat('d MMM').format(d.day)],
            tooltipTitles: [for (final d in days) DateFormat('EEE, d MMM').format(d.day)],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Busiest hours
// ─────────────────────────────────────────────────────────────────────────

class _HoursCard extends StatefulWidget {
  final ExhibitionInsights i;
  const _HoursCard({required this.i});

  @override
  State<_HoursCard> createState() => _HoursCardState();
}

class _HoursCardState extends State<_HoursCard> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final hours = widget.i.hours;
    final peak = widget.i.busiestHour!;
    var from = hours.indexWhere((v) => v > 0);
    var to = hours.lastIndexWhere((v) => v > 0);
    // Show at least an 8-hour window around the activity.
    while (to - from < 7) {
      if (from > 0) from--;
      if (to - from < 7 && to < 23) to++;
      if (from == 0 && to == 23) break;
    }
    final maxV = hours.reduce(math.max).clamp(1, 1 << 30);
    final sel = _sel ?? peak;
    final n = to - from + 1;
    final every = n > 12 ? 3 : 2;
    return ExChartCard(
      icon: Icons.schedule_rounded,
      accent: const Color(0xFF0E9F8E),
      title: 'Busiest hours',
      subtitle: 'Demos given in each hour of the day. Taller bar = more visitors.',
      help: const ExChartHelp(
        what: 'All demos of this exhibition grouped by the hour they were given, across every day.',
        howToRead: [
          'Each bar is one hour, e.g. the "11 AM" bar counts demos between 11:00 and 11:59.',
          'The dark bar is the busiest hour. Tap any bar to see its count.',
        ],
        why: 'Keep the full team at the stall during the busiest hours and take breaks in the quiet ones.',
      ),
      takeaway: 'Rush hour is ${_hourRange(peak)} '
          '(${_plural(widget.i.busiestHourDemos, 'demo')}). Keep the full team at the stall then.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text.rich(
              key: ValueKey(sel),
              TextSpan(children: [
                TextSpan(text: _hourRange(sel), style: const TextStyle(fontWeight: FontWeight.w700, color: exInk)),
                TextSpan(text: '  ·  ${_plural(hours[sel], 'demo')}'),
              ]),
              style: const TextStyle(fontSize: 13.5, color: exSubtle),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: exReduceMotion(context) ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, t, __) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var h = from; h <= to; h++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: '${_hourRange(h)}: ${_plural(hours[h], 'demo')}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _sel = h);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                height: math.max(4.0, 104 * hours[h] / maxV * t),
                                decoration: BoxDecoration(
                                  color: h == sel
                                      ? const Color(0xFF0E9F8E)
                                      : const Color(0xFF0E9F8E).withValues(alpha: hours[h] == 0 ? 0.12 : 0.35),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 16,
                                child: (h - from) % every == 0 || h == sel
                                    ? FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          DateFormat('ha').format(DateTime(2000, 1, 1, h)).toLowerCase(),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: h == sel ? FontWeight.w700 : FontWeight.w500,
                                            color: h == sel ? exInk : exSubtle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Lead quality donut
// ─────────────────────────────────────────────────────────────────────────

class _LeadQualityCard extends StatelessWidget {
  final ExhibitionInsights i;
  const _LeadQualityCard({required this.i});

  @override
  Widget build(BuildContext context) {
    final ex = i.interest[InterestLevel.excellent]!;
    final gd = i.interest[InterestLevel.good]!;
    final parts = [
      ExDonutPart('Excellent', _interestC[InterestLevel.excellent]!, ex),
      ExDonutPart('Good', _interestC[InterestLevel.good]!, gd),
      ExDonutPart('Average', _interestC[InterestLevel.average]!, i.interest[InterestLevel.average]!),
      if (i.interestNotSet > 0) ExDonutPart('Not set', _notSetC, i.interestNotSet),
    ];
    final hot = ex + gd;
    return ExChartCard(
      icon: Icons.local_fire_department_rounded,
      accent: const Color(0xFFD2561B),
      title: 'Lead quality',
      subtitle: 'How interested the schools you captured as leads are.',
      help: const ExChartHelp(
        what: 'Every lead split by the interest level chosen when it was captured: Excellent, Good or Average.',
        howToRead: [
          'The number in the middle is the total leads.',
          'Darker orange = more interested. The bigger the dark part, the better the leads.',
          '"Not set" means no interest level was picked; edit the lead to add one.',
        ],
        why: 'Call Excellent and Good leads first; they are the most likely to buy.',
      ),
      takeaway: hot == 0
          ? 'No lead is marked Excellent or Good yet.'
          : '${_plural(hot, 'lead')} ${hot == 1 ? 'is' : 'are'} Excellent or Good. Follow up with them first.',
      child: ExDonut(parts: parts, centerValue: '${i.leads}', centerLabel: i.leads == 1 ? 'lead' : 'leads'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Demo call results
// ─────────────────────────────────────────────────────────────────────────

class _CallResultsCard extends StatelessWidget {
  final _CallsState calls;
  const _CallResultsCard({required this.calls});

  @override
  Widget build(BuildContext context) {
    final c = calls.results;
    final total = c.total;
    final parts = [
      (Icons.call_rounded, _good, 'Answered', 'Picked up the call', c.answered),
      (Icons.call_end_rounded, _critical, 'Not answered', 'Busy, no answer or error', c.failed),
      (Icons.schedule_rounded, _pendingC, 'Still calling', 'Queued or ringing', c.pending),
    ];
    final pct = total == 0 ? 0 : (c.answered * 100 / total).round();
    final busy = calls.loading > 0;
    return ExChartCard(
      icon: Icons.phone_in_talk_rounded,
      accent: _good,
      title: 'Demo call results',
      subtitle: 'Every number called in each demo (visitor and attendees). '
          'Did they pick up?',
      help: const ExChartHelp(
        what: 'The result of every demo voice call. One demo calls several numbers (the visitor and the attendees), '
            'and each number is counted on its own.',
        howToRead: [
          'Answered: the person picked up and heard the demo.',
          'Not answered: the number was busy, did not pick up, or the call failed.',
          'Still calling: the call is queued or ringing right now.',
          'Example: a demo to 5 numbers with 2 picked up and 3 not picked up adds 2 to Answered and 3 to Not answered.',
        ],
        why: 'If many calls are not answered, check the numbers you enter or resend the demo later from the Demos tab.',
      ),
      takeaway: busy || total == 0
          ? null
          : c.failed > c.answered
              ? 'More calls were not answered than answered. Check the numbers or send the demo again.'
              : '$pct% of ${total == 1 ? 'the call was' : 'all $total calls were'} answered.',
      trailing: busy
          ? Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: exBrandBold),
                ),
                const SizedBox(width: 8),
                Text('Loading call details of ${calls.loading} '
                    '${calls.loading == 1 ? 'demo' : 'demos'}…',
                    style: const TextStyle(fontSize: 12.5, color: exSubtle)),
              ],
            )
          : calls.failedLoads > 0
              ? Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 15, color: exSubtle),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          "Couldn't load the calls of ${calls.failedLoads} "
                          "${calls.failedLoads == 1 ? 'demo' : 'demos'}; counted by demo status.",
                          style: const TextStyle(fontSize: 12.5, color: exSubtle)),
                    ),
                    TextButton(onPressed: calls.onRetry, child: const Text('Retry')),
                  ],
                )
              : null,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: exReduceMotion(context) ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, grow, __) => ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (final (k, p) in parts.where((p) => p.$5 > 0).indexed) ...[
                      if (k > 0) const SizedBox(width: 2),
                      Expanded(flex: math.max(1, (p.$5 * 1000 * grow).round()), child: Container(color: p.$2)),
                    ],
                    if (grow < 1)
                      Expanded(
                        flex: math.max(1, (total * 1000 * (1 - grow)).round()),
                        child: Container(color: exChartTrack),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final p in parts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: p.$2.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(p.$1, size: 16, color: p.$2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.$3, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exInk)),
                        Text(p.$4, style: const TextStyle(fontSize: 12, color: exSubtle)),
                      ],
                    ),
                  ),
                  Text('${p.$5}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: exInk)),
                  SizedBox(
                    width: 46,
                    child: Text(total == 0 ? '' : '${(p.$5 * 100 / total).round()}%',
                        textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: exSubtle)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Team performance
// ─────────────────────────────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  final ExhibitionInsights i;
  const _TeamCard({required this.i});

  @override
  Widget build(BuildContext context) {
    final team = i.team.take(6).toList();
    final maxV = team.fold<int>(1, (m, p) => math.max(m, math.max(p.demos, p.leads)));
    final top = team.first;
    return ExChartCard(
      icon: Icons.groups_rounded,
      accent: _teamC,
      title: 'Team performance',
      subtitle: 'Demos given and leads captured by each team member.',
      help: const ExChartHelp(
        what: 'Who gave the demos and who captured the leads at this exhibition.',
        howToRead: [
          'The thick blue bar is demos given; the thin orange bar is leads captured.',
          'People are sorted by demos, most first.',
        ],
        why: 'Recognise the top performers and pair newer team members with them.',
      ),
      takeaway: team.length < 2
          ? null
          : '${top.name} leads with ${_plural(top.demos, 'demo')} and ${_plural(top.leads, 'lead')}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExLegend(items: [(exChartDemo, 'Demos'), (exChartLead, 'Leads')]),
          const SizedBox(height: 6),
          for (final (k, p) in team.indexed)
            ExRankRow(
              rank: k + 1,
              label: p.name,
              value: p.demos,
              max: maxV,
              color: exChartDemo,
              second: p.leads,
              secondColor: exChartLead,
              valueLabel: _plural(p.demos, 'demo'),
              caption: '${_plural(p.leads, 'lead')} captured',
            ),
        ],
      ),
    );
  }
}
