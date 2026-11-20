import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../auth/model/ExhibitionModel.dart';
import '../../../viewModel/exhibition_insights.dart';
import 'exhibition_common.dart';

/// "Insights" tab of an exhibition: conversion headline, demos vs leads per
/// day, lead interest mix and call outcome. Built from the demos and leads
/// the detail screen already loaded.
///
/// Colours (validated for colour-blind separation on white):
/// demos `#2A78D6` / leads `#EB6834`; interest is an ordinal orange ramp
/// Average `#F09466` → Good `#EB6834` → Excellent `#A8400F`.
const _demoC = Color(0xFF2A78D6);
const _leadC = Color(0xFFEB6834);
const _interestC = {
  InterestLevel.average: Color(0xFFF09466),
  InterestLevel.good: Color(0xFFEB6834),
  InterestLevel.excellent: Color(0xFFA8400F),
};
const _notSetC = Color(0xFFD9DEE7);
const _grid = Color(0xFFE9EDF4);

// Status colours: reserved for call outcome, always with icon + label.
const _good = Color(0xFF0CA30C);
const _critical = Color(0xFFD03B3B);
const _pendingC = Color(0xFF8A94A6);

class ExhibitionInsightsView extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
      _ConversionCard(i: i),
      if (i.days.isNotEmpty) _DailyCard(i: i),
      if (i.leads > 0) _InterestCard(i: i),
      if (i.demos > 0) _CallsCard(i: i),
    ];
    return LayoutBuilder(builder: (context, box) {
      // Two columns on wide panes (iPad), one on phones.
      if (box.maxWidth >= 720) {
        final left = <Widget>[], right = <Widget>[];
        for (var k = 0; k < cards.length; k++) {
          (k.isEven ? left : right).add(ExAppear(index: k, child: cards[k]));
        }
        Widget col(List<Widget> c) => Column(
              children: [for (final w in c) Padding(padding: const EdgeInsets.only(bottom: 14), child: w)],
            );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: col(left)), const SizedBox(width: 14), Expanded(child: col(right))],
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
// Shared card shell
// ─────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget child;
  const _Card({required this.title, this.caption, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(exRadiusCard),
          boxShadow: exCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: exHeadingSm),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(caption!, style: exBodySm),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

Widget _swatch(Color c) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
    );

// ─────────────────────────────────────────────────────────────────────────
// Conversion headline
// ─────────────────────────────────────────────────────────────────────────

class _ConversionCard extends StatelessWidget {
  final ExhibitionInsights i;
  const _ConversionCard({required this.i});

  String _hour(int h) {
    String f(int x) => DateFormat('h a').format(DateTime(2000, 1, 1, x % 24));
    return '${f(h)} – ${f(h + 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (i.conversion * 100).round();
    return _Card(
      title: 'Demo → lead conversion',
      caption: '${i.leads} of ${i.demos} demos became leads',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct.toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text('${v.round()}%',
                style: const TextStyle(
                    fontFamily: exFont, fontSize: 40, height: 1, fontWeight: FontWeight.w800, color: exInk)),
          ),
          const SizedBox(height: 12),
          // Leads as a share of demos.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFDCE8F8)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: i.conversion.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        decoration: BoxDecoration(color: _leadC, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i.busiestHour != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: exSubtle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Busiest hour  '),
                      TextSpan(
                          text: _hour(i.busiestHour!),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: exInk)),
                      TextSpan(text: '  ·  ${i.busiestHourDemos} demos'),
                    ]),
                    style: const TextStyle(fontSize: 13, color: exSubtle),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Demos vs leads per day (grouped bars, tap a day for its numbers)
// ─────────────────────────────────────────────────────────────────────────

class _DailyCard extends StatefulWidget {
  final ExhibitionInsights i;
  const _DailyCard({required this.i});

  @override
  State<_DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends State<_DailyCard> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final days = widget.i.days;
    final sel = _sel == null ? null : days[_sel!];
    final label = sel == null
        ? 'All days'
        : DateFormat('EEE, d MMM').format(sel.day);
    final demoN = sel?.demos ?? widget.i.demos;
    final leadN = sel?.leads ?? widget.i.leads;
    Widget legend(Color c, String name, int n) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _swatch(c),
            const SizedBox(width: 6),
            Text(name, style: const TextStyle(fontSize: 13, color: exSubtle)),
            const SizedBox(width: 5),
            Text('$n', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: exInk)),
          ],
        );
    return _Card(
      title: 'Activity by day',
      caption: 'Tap a day to see its numbers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend doubles as the readout for the selected day.
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(label,
                    key: ValueKey(label),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: exInk)),
              ),
              legend(_demoC, 'Demos', demoN),
              legend(_leadC, 'Leads', leadN),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, grow, __) => LayoutBuilder(builder: (context, box) {
              final size = Size(box.maxWidth, 180);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  final idx = _DailyPainter.hit(d.localPosition, size, days.length);
                  if (idx == null) return;
                  HapticFeedback.selectionClick();
                  setState(() => _sel = _sel == idx ? null : idx);
                },
                child: CustomPaint(
                  size: size,
                  painter: _DailyPainter(days: days, grow: grow, selected: _sel),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DailyPainter extends CustomPainter {
  final List<DayActivity> days;
  final double grow;
  final int? selected;

  _DailyPainter({required this.days, required this.grow, required this.selected});

  static const _axisW = 28.0;
  static const _xLabelH = 22.0;

  static int? hit(Offset p, Size size, int n) {
    if (n == 0 || p.dx < _axisW) return null;
    final gw = (size.width - _axisW) / n;
    return ((p.dx - _axisW) / gw).floor().clamp(0, n - 1);
  }

  static int _niceMax(int v) {
    if (v <= 4) return 4;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toInt();
    for (final m in [1, 2, 2.5, 5, 10]) {
      final c = (m * mag).ceil();
      if (c >= v && c % 4 == 0) return c;
    }
    return ((v + 3) ~/ 4) * 4;
  }

  void _text(Canvas c, String s, Offset at, {TextAlign align = TextAlign.center, double size = 11, Color color = exSubtle, FontWeight w = FontWeight.w500}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: exFont, fontSize: size, color: color, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(c, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final plotH = size.height - _xLabelH;
    final maxV = _niceMax(days.fold<int>(1, (m, d) => math.max(m, math.max(d.demos, d.leads))));
    final gw = (size.width - _axisW) / n;

    // Recessive grid + y labels (0, ½, max).
    final grid = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = plotH - plotH * f;
      canvas.drawLine(Offset(_axisW, y), Offset(size.width, y), grid);
      _text(canvas, '${(maxV * f).round()}', Offset(_axisW - 6, y), align: TextAlign.right, size: 10.5);
    }

    // Selected day band.
    if (selected != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(_axisW + gw * selected! + 2, 0, gw - 4, plotH),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFFF1F5FC),
      );
    }

    final barW = math.min(14.0, math.max(3.0, (gw - 8) / 2 - 1));
    void bar(double cx, int v, Color c) {
      if (v <= 0) return;
      final h = math.max(2.0, plotH * (v / maxV) * grow);
      final r = math.min(4.0, barW / 2);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - barW / 2, plotH - h, barW, h),
          topLeft: Radius.circular(r),
          topRight: Radius.circular(r),
        ),
        Paint()..color = c,
      );
    }

    // Skip x labels so they never collide.
    final every = math.max(1, (46 / gw).ceil());
    for (var k = 0; k < n; k++) {
      final cx = _axisW + gw * (k + 0.5);
      final dim = selected != null && selected != k;
      bar(cx - barW / 2 - 1, days[k].demos, dim ? _demoC.withValues(alpha: 0.35) : _demoC);
      bar(cx + barW / 2 + 1, days[k].leads, dim ? _leadC.withValues(alpha: 0.35) : _leadC);
      if (k % every == 0 || k == selected) {
        _text(canvas, DateFormat('d MMM').format(days[k].day), Offset(cx, plotH + _xLabelH / 2 + 2),
            size: 10.5,
            color: k == selected ? exInk : exSubtle,
            w: k == selected ? FontWeight.w700 : FontWeight.w500);
      }
    }
  }

  @override
  bool shouldRepaint(_DailyPainter old) =>
      old.grow != grow || old.selected != selected || old.days != days;
}

// ─────────────────────────────────────────────────────────────────────────
// Lead interest mix (one stacked bar + legend with counts)
// ─────────────────────────────────────────────────────────────────────────

class _InterestCard extends StatelessWidget {
  final ExhibitionInsights i;
  const _InterestCard({required this.i});

  @override
  Widget build(BuildContext context) {
    final parts = <(String, Color, int)>[
      ('Excellent', _interestC[InterestLevel.excellent]!, i.interest[InterestLevel.excellent]!),
      ('Good', _interestC[InterestLevel.good]!, i.interest[InterestLevel.good]!),
      ('Average', _interestC[InterestLevel.average]!, i.interest[InterestLevel.average]!),
      if (i.interestNotSet > 0) ('Not set', _notSetC, i.interestNotSet),
    ];
    final total = parts.fold<int>(0, (s, p) => s + p.$3);
    return _Card(
      title: 'Lead interest',
      caption: '$total leads by interest level',
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, grow, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 18,
                child: Row(
                  children: [
                    for (final (k, p) in parts.where((p) => p.$3 > 0).indexed) ...[
                      if (k > 0) const SizedBox(width: 2), // surface gap between segments
                      Expanded(
                        flex: math.max(1, (p.$3 * 1000 * grow).round()),
                        child: Container(color: p.$2),
                      ),
                    ],
                    if (grow < 1)
                      Expanded(
                        flex: math.max(1, (total * 1000 * (1 - grow)).round()),
                        child: const SizedBox(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final p in parts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _swatch(p.$2),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.$1, style: const TextStyle(fontSize: 14, color: exInk))),
                  Text('${p.$3}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: exInk)),
                  SizedBox(
                    width: 48,
                    child: Text(
                      total == 0 ? '' : '${(p.$3 * 100 / total).round()}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, color: exSubtle),
                    ),
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
// Call outcome (status: icon + label + count, never colour alone)
// ─────────────────────────────────────────────────────────────────────────

class _CallsCard extends StatelessWidget {
  final ExhibitionInsights i;
  const _CallsCard({required this.i});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, Color c, String label, int n) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: exPageBg,
              borderRadius: BorderRadius.circular(exRadiusControl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: c),
                const SizedBox(height: 8),
                ExCountUp(n,
                    style: const TextStyle(
                        fontFamily: exFont, fontSize: 22, height: 1, fontWeight: FontWeight.w800, color: exInk)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(label, style: const TextStyle(fontSize: 12.5, color: exSubtle)),
                ),
              ],
            ),
          ),
        );
    return _Card(
      title: 'Demo calls',
      caption: 'How the demo calls ended',
      child: Row(
        children: [
          tile(Icons.check_circle_rounded, _good, 'Reached', i.reached),
          const SizedBox(width: 8),
          tile(Icons.cancel_rounded, _critical, 'Failed', i.failed),
          const SizedBox(width: 8),
          tile(Icons.schedule_rounded, _pendingC, 'In progress', i.pending),
        ],
      ),
    );
  }
}
