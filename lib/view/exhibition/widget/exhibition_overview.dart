import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/model/ExhibitionModel.dart';
import '../../../viewModel/exhibition_insights.dart';
import '../../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_common.dart';

/// Overview card at the top of the Exhibitions list: totals for the
/// exhibitions shown (follows search / status filter) and the lead
/// interest mix of the top exhibitions by leads. Tap a row to open it.
///
/// Same validated series colours as the Insights tab: demos `#2A78D6`,
/// leads `#EB6834`.
const _demoC = Color(0xFF2A78D6);
const _leadC = Color(0xFFEB6834);
const _track = Color(0xFFF0F3F8);

class ExhibitionsOverviewCard extends StatefulWidget {
  final List<Exhibition> items;
  final ValueChanged<Exhibition> onOpen;

  const ExhibitionsOverviewCard({super.key, required this.items, required this.onOpen});

  @override
  State<ExhibitionsOverviewCard> createState() => _ExhibitionsOverviewCardState();
}

class _ExhibitionsOverviewCardState extends State<ExhibitionsOverviewCard> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final o = computeExhibitionsOverview(widget.items);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(exRadiusCard),
        boxShadow: exCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (tap to collapse the chart).
          InkWell(
            borderRadius: BorderRadius.circular(exRadiusCard),
            onTap: o.topByLeads.isEmpty
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _open = !_open);
                  },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 4),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: exHeroGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights_rounded, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Overview', style: exHeadingSm)),
                  if (o.topByLeads.isNotEmpty)
                    AnimatedRotation(
                      turns: _open ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more_rounded, color: exSubtle),
                    ),
                ],
              ),
            ),
          ),
          // KPIs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                _kpi('${o.exhibitions}', o.active > 0 ? '${o.active} active' : 'Exhibitions'),
                _divider(),
                _kpi('${o.demos}', 'Demos', dot: _demoC),
                _divider(),
                _kpi('${o.leads}', 'Leads', dot: _leadC),
                _divider(),
                _kpi('${(o.conversion * 100).round()}%', 'Conversion'),
              ],
            ),
          ),
          // Top exhibitions chart
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open || o.topByLeads.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _InterestChart(top: o.topByLeads, onOpen: widget.onOpen),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: exBorder,
      );

  Widget _kpi(String value, String label, {Color? dot}) => Expanded(
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dot != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(label, style: const TextStyle(fontSize: 12, color: exSubtle)),
                ],
              ),
            ),
          ],
        ),
      );

  static const _kpiStyle =
      TextStyle(fontFamily: exFont, fontSize: 21, height: 1.1, fontWeight: FontWeight.w800, color: exInk);
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
        const Divider(height: 1, color: exBorder),
        const SizedBox(height: 12),
        const Text('Lead interest',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: exInk)),
        const SizedBox(height: 2),
        Text(
          top.length == 1 ? 'Top exhibition by leads' : 'Top ${top.length} exhibitions by leads',
          style: exBodySm,
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
                      ? Container(color: _track)
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
