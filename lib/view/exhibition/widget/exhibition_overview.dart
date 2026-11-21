import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/model/ExhibitionModel.dart';
import '../../../viewModel/exhibition_insights.dart';
import '../../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_charts.dart';
import 'exhibition_common.dart';

/// Overview card at the top of the Exhibitions list: a gradient summary of
/// the exhibitions shown (follows search / status filter), then one chart at
/// a time: show-by-show trend, top shows, or lead quality. Each chart says
/// in words what it shows and has an ⓘ sheet on how to read it.
///
/// On phones the list shows only a slim strip; tapping it opens the full
/// overview in a bottom sheet so the exhibition cards stay in view.
class ExhibitionsOverviewCard extends StatefulWidget {
  final List<Exhibition> items;
  final ValueChanged<Exhibition> onOpen;

  /// Always the full card (inside the phone bottom sheet, and on iPad).
  final bool expanded;

  const ExhibitionsOverviewCard({
    super.key,
    required this.items,
    required this.onOpen,
    this.expanded = false,
  });

  @override
  State<ExhibitionsOverviewCard> createState() => _ExhibitionsOverviewCardState();
}

class _ExhibitionsOverviewCardState extends State<ExhibitionsOverviewCard> {
  bool _open = true;
  int _view = 0; // 0 = trend, 1 = top shows, 2 = lead quality

  void _openSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: exPageBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(16, 10, 16, 24 + MediaQuery.paddingOf(sheet).bottom),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: exStrongBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            ExhibitionsOverviewCard(
              items: widget.items,
              expanded: true,
              onOpen: (e) {
                Navigator.pop(sheet);
                widget.onOpen(e);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = computeExhibitionsOverview(widget.items);
    if (!widget.expanded && exIsPhone(context)) return _CompactOverview(o: o, onTap: _openSheet);
    final hasCharts = o.top.isNotEmpty;
    final white70 = Colors.white.withValues(alpha: 0.8);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(exRadiusCard + 2),
        boxShadow: exCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Gradient summary ──
          Container(
            decoration: const BoxDecoration(
              gradient: exDeepGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: !hasCharts || widget.expanded
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _open = !_open);
                        },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.insights_rounded, color: Colors.white, size: 19),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Overview',
                                  style: TextStyle(
                                      fontFamily: exFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              Text(exConversionWords(o.demos, o.leads),
                                  maxLines: 2,
                                  style: TextStyle(fontSize: 12.5, height: 1.3, color: white70)),
                            ],
                          ),
                        ),
                        if (hasCharts && !widget.expanded)
                          AnimatedRotation(
                            turns: _open ? 0 : -0.25,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.expand_more_rounded, color: white70),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Row(
                    children: [
                      _kpi('${o.exhibitions}', o.active > 0 ? '${o.active} active' : 'Exhibitions'),
                      const SizedBox(width: 8),
                      _kpi('${o.demos}', 'Demos'),
                      const SizedBox(width: 8),
                      _kpi('${o.leads}', 'Leads'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── One chart at a time ──
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open || !hasCharts
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExChartSwitch(
                          options: const ['Trend', 'Top shows', 'Lead interest'],
                          selected: _view,
                          onChanged: (v) => setState(() => _view = v),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: KeyedSubtree(
                            key: ValueKey(_view),
                            child: switch (_view) {
                              0 => _TrendView(o: o, onOpen: widget.onOpen),
                              1 => _TopShowsView(o: o, onOpen: widget.onOpen),
                              _ => _InterestChart(top: o.topByLeads, onOpen: widget.onOpen),
                            },
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

  Widget _kpi(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: int.tryParse(value) == null
                    ? Text(value, style: _kpiStyle)
                    : ExCountUp(int.parse(value), style: _kpiStyle),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ),
            ],
          ),
        ),
      );

  static const _kpiStyle =
      TextStyle(fontFamily: exFont, fontSize: 20, height: 1.1, fontWeight: FontWeight.w800, color: Colors.white);
}

/// Phone list: one slim gradient strip with the totals; tap for the full
/// overview.
class _CompactOverview extends StatelessWidget {
  final ExhibitionsOverview o;
  final VoidCallback onTap;
  const _CompactOverview({required this.o, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final white80 = Colors.white.withValues(alpha: 0.85);
    Widget figure(String value, String label) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    fontFamily: exFont, fontSize: 17, height: 1.1, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 11, color: white80)),
          ],
        );
    Widget gap() => Container(
          width: 1,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: Colors.white.withValues(alpha: 0.22),
        );
    return Semantics(
      button: true,
      label: 'Overview: ${o.exhibitions} exhibitions, ${o.demos} demos, ${o.leads} leads. Open charts',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: exDeepGradient,
            borderRadius: BorderRadius.circular(exRadiusCard),
            boxShadow: exCardShadow,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(exRadiusCard),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          figure('${o.exhibitions}', o.exhibitions == 1 ? 'Exhibition' : 'Exhibitions'),
                          gap(),
                          figure('${o.demos}', o.demos == 1 ? 'Demo' : 'Demos'),
                          gap(),
                          figure('${o.leads}', o.leads == 1 ? 'Lead' : 'Leads'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Charts',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title-less explanation row above an overview chart: one sentence plus ⓘ.
class _Explain extends StatelessWidget {
  final String text;
  final String title;
  final ExChartHelp help;
  const _Explain({required this.text, required this.title, required this.help});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(text, style: exBodyMd.copyWith(fontSize: 13, height: 1.35))),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              tooltip: 'How to read this chart',
              padding: EdgeInsets.zero,
              onPressed: () => showExChartHelp(context, title: title, help: help),
              icon: const Icon(Icons.info_outline_rounded, size: 19, color: exSubtle),
            ),
          ),
        ],
      );
}

/// Show-by-show line chart: one point per exhibition, oldest on the left.
class _TrendView extends StatelessWidget {
  final ExhibitionsOverview o;
  final ValueChanged<Exhibition> onOpen;
  const _TrendView({required this.o, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = o.trend;
    const help = ExChartHelp(
      what: 'Each point on the lines is one exhibition, in date order: the oldest on the left, the newest on the right.',
      howToRead: [
        'Blue line = demos given at that exhibition; orange line = leads captured.',
        'Tap or slide on the chart to see the exhibition name and its numbers.',
        'Lines going up to the right mean recent exhibitions are doing better.',
      ],
      why: 'Shows whether your exhibitions are improving over time and which shows were worth the effort.',
    );
    if (t.length < 2) {
      return const ExTakeaway(text: 'The trend line appears once there are two or more exhibitions.');
    }
    final last = t.last, prev = t[t.length - 2];
    final diff = last.demoCount - prev.demoCount;
    final takeaway = diff == 0
        ? '${last.name} had the same number of demos as the show before it.'
        : '${last.name} had ${diff.abs()} ${diff.abs() == 1 ? 'demo' : 'demos'} '
            '${diff > 0 ? 'more' : 'fewer'} than ${prev.name}.';
    // Add the year when the shows span more than one.
    final years = {for (final e in t) (e.startDate ?? e.createdAt)?.year};
    final fmt = DateFormat(years.length > 1 ? "MMM ''yy" : 'd MMM');
    String short(Exhibition e) {
      final d = e.startDate ?? e.createdAt;
      return d == null ? '' : fmt.format(d);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Explain(
          text: 'Demos and leads at each exhibition, oldest to newest.',
          title: 'Exhibition trend',
          help: help,
        ),
        const SizedBox(height: 8),
        const ExLegend(items: [(exChartDemo, 'Demos'), (exChartLead, 'Leads')]),
        const SizedBox(height: 8),
        ExLineChart(
          height: 190,
          series: [
            ExLineSeries('Demos', exChartDemo, [for (final e in t) e.demoCount.toDouble()]),
            ExLineSeries('Leads', exChartLead, [for (final e in t) e.leadCount.toDouble()]),
          ],
          xLabels: [for (final e in t) short(e)],
          tooltipTitles: [for (final e in t) e.name],
        ),
        const SizedBox(height: 12),
        ExTakeaway(text: takeaway, color: exChartDemo),
      ],
    );
  }
}

/// Exhibitions ranked by demos, with leads and conversion.
class _TopShowsView extends StatelessWidget {
  final ExhibitionsOverview o;
  final ValueChanged<Exhibition> onOpen;
  const _TopShowsView({required this.o, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final top = o.top;
    final maxV = top.fold<int>(1, (m, e) => e.demoCount > m ? e.demoCount : m);
    Exhibition? best;
    for (final e in top) {
      if (e.leadCount > 0 && (best == null || e.leadCount > best.leadCount)) best = e;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Explain(
          text: 'Exhibitions with the most demos. Tap one to open it.',
          title: 'Top shows',
          help: ExChartHelp(
            what: 'Your busiest exhibitions, ranked by the number of demos given.',
            howToRead: [
              'The blue bar is demos given; the thin orange bar is leads captured.',
              'Open an exhibition and check its Insights to see how many of its visitors became leads.',
            ],
            why: 'Busy is not always best: a show with fewer demos but more leads may be worth more.',
          ),
        ),
        const SizedBox(height: 6),
        for (final (k, e) in top.indexed)
          ExRankRow(
            rank: k + 1,
            label: e.name,
            value: e.demoCount,
            max: maxV,
            color: exChartDemo,
            second: e.leadCount,
            secondColor: exChartLead,
            valueLabel: '${e.demoCount} ${e.demoCount == 1 ? 'demo' : 'demos'}',
            caption: '${e.leadCount} ${e.leadCount == 1 ? 'lead' : 'leads'}',
            onTap: () => onOpen(e),
          ),
        if (best != null && top.length > 1) ...[
          const SizedBox(height: 8),
          ExTakeaway(
            text: 'Most leads: ${best.name} (${exConversionWords(best.demoCount, best.leadCount)}).',
            color: exChartDemo,
          ),
        ],
      ],
    );
  }
}

/// Lead interest per exhibition (top 5 by leads): one stacked bar each,
/// Excellent → Good → Average → Not set, plus the mix across them on top.
/// Each row loads that exhibition's leads; tap a row to open it.
///
/// Ordinal ramp (validated, one hue light→dark): Average `#F09466`,
/// Good `#EB6834`, Excellent `#A8400F`; Not set is neutral grey.
const _excellentC = Color(0xFFA8400F);
const _goodC = Color(0xFFEB6834);
const _averageC = Color(0xFFF09466);
const _notSetC = Color(0xFFD9DEE7);

typedef _Mix = ({int excellent, int good, int average, int notSet});

class _InterestChart extends ConsumerWidget {
  final List<Exhibition> top;
  final ValueChanged<Exhibition> onOpen;
  const _InterestChart({required this.top, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (top.isEmpty) {
      return const ExTakeaway(text: 'No leads captured yet. Lead interest appears after the first lead.');
    }
    final asyncs = [for (final e in top) ref.watch(exhibitionLeadsProvider(e.id))];
    final loaded = asyncs.every((a) => a.hasValue);
    _Mix? total;
    if (loaded) {
      var ex = 0, gd = 0, av = 0, ns = 0;
      for (final a in asyncs) {
        final m = interestMix(a.value!);
        ex += m.excellent;
        gd += m.good;
        av += m.average;
        ns += m.notSet;
      }
      total = (excellent: ex, good: gd, average: av, notSet: ns);
    }
    Widget legend(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 5),
            Text(t, style: const TextStyle(fontSize: 12, color: exSubtle)),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Explain(
          text: top.length == 1
              ? 'How interested the leads of your top exhibition are.'
              : 'How interested the leads of your top ${top.length} exhibitions are.',
          title: 'Lead interest',
          help: const ExChartHelp(
            what: 'Each bar is one exhibition\'s leads, split by the interest level picked when the lead was captured.',
            howToRead: [
              'Darker orange = more interested (Excellent), lighter = Average, grey = not set.',
              'The first bar adds all of them together.',
              'Tap an exhibition to open it.',
            ],
            why: 'An exhibition with many Excellent leads is worth following up first, and worth attending again.',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            legend(_excellentC, 'Excellent'),
            legend(_goodC, 'Good'),
            legend(_averageC, 'Average'),
            legend(_notSetC, 'Not set'),
          ],
        ),
        if (total != null && _sum(total) > 0) ...[
          const SizedBox(height: 14),
          _MixRow(
            title: 'All ${_sum(total)} leads',
            bold: true,
            mix: total,
          ),
        ],
        const SizedBox(height: 4),
        for (var k = 0; k < top.length; k++)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticFeedback.selectionClick();
              onOpen(top[k]);
            },
            child: asyncs[k].when(
              loading: () => _MixRow(title: top[k].name, trailing: '${top[k].leadCount} leads'),
              error: (_, __) => _MixRow(
                title: top[k].name,
                trailing: '${top[k].leadCount} leads',
                error: true,
                onRetry: () => ref.invalidate(exhibitionLeadsProvider(top[k].id)),
              ),
              data: (leads) => _MixRow(
                title: top[k].name,
                trailing: '${leads.length} leads',
                mix: interestMix(leads),
              ),
            ),
          ),
      ],
    );
  }
}

int _sum(_Mix m) => m.excellent + m.good + m.average + m.notSet;

/// Title + stacked bar + compact counts. With no [mix] it shows a loading
/// placeholder (or a retry when [error]).
class _MixRow extends StatelessWidget {
  final String title;
  final String? trailing;
  final _Mix? mix;
  final bool bold;
  final bool error;
  final VoidCallback? onRetry;

  const _MixRow({
    required this.title,
    this.trailing,
    this.mix,
    this.bold = false,
    this.error = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final m = mix;
    final parts = m == null
        ? const <(String, Color, int)>[]
        : <(String, Color, int)>[
            ('Exc', _excellentC, m.excellent),
            ('Good', _goodC, m.good),
            ('Avg', _averageC, m.average),
            ('Not set', _notSetC, m.notSet),
          ].where((p) => p.$3 > 0).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                        color: exInk)),
              ),
              if (trailing != null)
                Text(trailing!, style: const TextStyle(fontSize: 12.5, color: exSubtle)),
              if (!bold) const Icon(Icons.chevron_right_rounded, size: 18, color: exSubtle),
            ],
          ),
          const SizedBox(height: 7),
          if (error)
            Row(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 15, color: exSubtle),
                const SizedBox(width: 6),
                const Text("Couldn't load", style: TextStyle(fontSize: 12.5, color: exSubtle)),
                const Spacer(),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            )
          else
            TweenAnimationBuilder<double>(
              key: ValueKey(m == null),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, grow, __) => ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: bold ? 14 : 10,
                  child: m == null || parts.isEmpty
                      ? Container(color: exChartTrack)
                      : Row(
                          children: [
                            for (final (k, p) in parts.indexed) ...[
                              if (k > 0) const SizedBox(width: 2), // surface gap
                              Expanded(
                                flex: (p.$3 * 1000 * grow).round().clamp(1, 1 << 30),
                                child: Container(color: p.$2),
                              ),
                            ],
                            if (grow < 1)
                              Expanded(
                                flex: (_sum(m) * 1000 * (1 - grow)).round().clamp(1, 1 << 30),
                                child: const SizedBox(),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                for (final p in parts)
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${p.$1} '),
                      TextSpan(
                          text: '${p.$3}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: exInk)),
                    ]),
                    style: const TextStyle(fontSize: 12, color: exSubtle),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
