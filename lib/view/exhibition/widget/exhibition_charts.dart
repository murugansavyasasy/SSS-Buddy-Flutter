import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'exhibition_common.dart';

/// Chart kit for the Exhibitions module: a card that explains its chart in
/// plain words (what it shows, how to read it, the takeaway), a smooth
/// line/area chart you can scrub, a donut and ranked bars.
///
/// Series colours are validated for colour-blind separation on white:
/// demos `#2A78D6`, leads `#EB6834`.
const exChartDemo = Color(0xFF2A78D6);
const exChartLead = Color(0xFFEB6834);
const exChartGrid = Color(0xFFE9EDF4);
const exChartTrack = Color(0xFFF0F3F8);

// ─────────────────────────────────────────────────────────────────────────
// Explained chart card
// ─────────────────────────────────────────────────────────────────────────

/// The "ⓘ" sheet of a chart: what it shows, how to read it, why it matters.
class ExChartHelp {
  final String what;
  final List<String> howToRead;
  final String why;
  const ExChartHelp({required this.what, required this.howToRead, required this.why});
}

class ExChartCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;

  /// One plain sentence under the title: what the chart shows.
  final String subtitle;

  /// Optional extra help behind the ⓘ button.
  final ExChartHelp? help;

  /// The one-line conclusion, shown under the chart with a bulb icon.
  final String? takeaway;

  /// Optional control on the title row (e.g. a view switch).
  final Widget? trailing;
  final Widget child;

  const ExChartCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.accent = exBrandBold,
    this.help,
    this.takeaway,
    this.trailing,
  });

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: exHeadingSm.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: exBodyMd.copyWith(fontSize: 13, height: 1.35)),
                    ],
                  ),
                ),
                if (help != null)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      tooltip: 'How to read this chart',
                      padding: EdgeInsets.zero,
                      onPressed: () => showExChartHelp(context, title: title, help: help!, accent: accent),
                      icon: const Icon(Icons.info_outline_rounded, size: 20, color: exSubtle),
                    ),
                  ),
              ],
            ),
            if (trailing != null) ...[
              const SizedBox(height: 12),
              trailing!,
            ],
            const SizedBox(height: 16),
            child,
            if (takeaway != null) ...[
              const SizedBox(height: 14),
              ExTakeaway(text: takeaway!, color: accent),
            ],
          ],
        ),
      );
}

/// Tinted line with a bulb: the chart's conclusion in words.
class ExTakeaway extends StatelessWidget {
  final String text;
  final Color color;
  const ExTakeaway({super.key, required this.text, this.color = exBrandBold});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_rounded, size: 17, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w600, color: exInk)),
            ),
          ],
        ),
      );
}

Future<void> showExChartHelp(
  BuildContext context, {
  required String title,
  required ExChartHelp help,
  Color accent = exBrandBold,
}) {
  HapticFeedback.selectionClick();
  Widget section(String heading, Widget body) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11.5, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: exSubtle)),
            const SizedBox(height: 6),
            body,
          ],
        ),
      );
  const body = TextStyle(fontFamily: exFont, fontSize: 15, height: 1.45, color: exInk);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: exBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_rounded, color: accent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontFamily: exFont, fontSize: 19, fontWeight: FontWeight.w700, color: exInk)),
                  ),
                ],
              ),
              section('What it shows', Text(help.what, style: body)),
              section(
                'How to read it',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (k, line) in help.howToRead.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(right: 10, top: 1),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text('${k + 1}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                            ),
                            Expanded(child: Text(line, style: body)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              section('Why it matters', Text(help.why, style: body)),
              const SizedBox(height: 20),
              ExPrimaryButton(label: 'Got it', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Colour key: "● Demos  ● Leads".
class ExLegend extends StatelessWidget {
  final List<(Color, String)> items;
  const ExLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          for (final (c, t) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 14, height: 4, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: exSubtle)),
              ],
            ),
        ],
      );
}

/// Small two-or-three-way pill switch for a chart's view.
class ExChartSwitch extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const ExChartSwitch({super.key, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: exChartTrack, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == selected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i == selected) return;
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: i == selected ? exCardShadow : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(options[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: i == selected ? FontWeight.w700 : FontWeight.w600,
                                color: i == selected ? exInk : exSubtle,
                              )),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Line / area chart
// ─────────────────────────────────────────────────────────────────────────

class ExLineSeries {
  final String name;
  final Color color;
  final List<double> values;
  const ExLineSeries(this.name, this.color, this.values);
}

/// Smooth lines with a soft area fill. Tap or drag across the chart to see
/// one point's values in a tooltip; tap again outside to clear it.
class ExLineChart extends StatefulWidget {
  final List<ExLineSeries> series;

  /// Short label under each point (some are skipped when crowded).
  final List<String> xLabels;

  /// Full label for the tooltip (defaults to [xLabels]).
  final List<String>? tooltipTitles;
  final double height;

  const ExLineChart({
    super.key,
    required this.series,
    required this.xLabels,
    this.tooltipTitles,
    this.height = 200,
  });

  @override
  State<ExLineChart> createState() => _ExLineChartState();
}

class _ExLineChartState extends State<ExLineChart> {
  int? _sel;

  int get _n => widget.xLabels.length;

  void _pick(Offset p, double width) {
    final i = _LinePainter.indexAt(p.dx, width, _n);
    if (i == null || i == _sel) return;
    HapticFeedback.selectionClick();
    setState(() => _sel = i);
  }

  @override
  void didUpdateWidget(ExLineChart old) {
    super.didUpdateWidget(old);
    if (_sel != null && _sel! >= _n) _sel = null;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = exReduceMotion(context);
    final semantics = [
      for (var i = 0; i < _n; i++)
        '${(widget.tooltipTitles ?? widget.xLabels)[i]}: '
            '${widget.series.map((s) => '${s.values[i].round()} ${s.name}').join(', ')}',
    ].join('. ');
    return Semantics(
      label: semantics,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => LayoutBuilder(builder: (context, box) {
          final size = Size(box.maxWidth, widget.height);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final i = _LinePainter.indexAt(d.localPosition.dx, size.width, _n);
              HapticFeedback.selectionClick();
              setState(() => _sel = (i == _sel) ? null : i);
            },
            onHorizontalDragStart: (d) => _pick(d.localPosition, size.width),
            onHorizontalDragUpdate: (d) => _pick(d.localPosition, size.width),
            child: CustomPaint(
              size: size,
              painter: _LinePainter(
                series: widget.series,
                xLabels: widget.xLabels,
                titles: widget.tooltipTitles ?? widget.xLabels,
                progress: t,
                selected: _sel,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<ExLineSeries> series;
  final List<String> xLabels;
  final List<String> titles;
  final double progress;
  final int? selected;

  _LinePainter({
    required this.series,
    required this.xLabels,
    required this.titles,
    required this.progress,
    required this.selected,
  });

  static const _axisW = 30.0;
  static const _xLabelH = 24.0;
  static const _top = 10.0;
  static const _side = 12.0;

  static double _x(int i, double width, int n) {
    final w = width - _axisW - _side * 2;
    return n <= 1 ? _axisW + _side + w / 2 : _axisW + _side + w * i / (n - 1);
  }

  static int? indexAt(double dx, double width, int n) {
    if (n == 0) return null;
    if (n == 1) return 0;
    final w = width - _axisW - _side * 2;
    return (((dx - _axisW - _side) / w) * (n - 1)).round().clamp(0, n - 1);
  }

  static int niceMax(double v) {
    if (v <= 4) return 4;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in [1.0, 2.0, 2.5, 4.0, 5.0, 8.0, 10.0]) {
      final c = (m * mag).ceil();
      if (c >= v && c % 4 == 0) return c;
    }
    return ((v + 3) ~/ 4) * 4;
  }

  TextPainter _tp(String s, {double size = 10.5, Color color = exSubtle, FontWeight w = FontWeight.w500}) =>
      TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontFamily: exFont, fontSize: size, color: color, fontWeight: w)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );

  /// Monotone cubic (Fritsch–Carlson): smooth, never overshoots below zero.
  Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    if (p.length == 2) return path..lineTo(p[1].dx, p[1].dy);
    final n = p.length;
    final d = [for (var i = 0; i < n - 1; i++) (p[i + 1].dy - p[i].dy) / (p[i + 1].dx - p[i].dx)];
    final m = List<double>.filled(n, 0);
    m[0] = d[0];
    m[n - 1] = d[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (d[i] == 0) {
        m[i] = 0;
        m[i + 1] = 0;
        continue;
      }
      final a = m[i] / d[i], b = m[i + 1] / d[i];
      final s = a * a + b * b;
      if (s > 9) {
        final t = 3 / math.sqrt(s);
        m[i] = t * a * d[i];
        m[i + 1] = t * b * d[i];
      }
    }
    for (var i = 0; i < n - 1; i++) {
      final h = (p[i + 1].dx - p[i].dx) / 3;
      path.cubicTo(p[i].dx + h, p[i].dy + m[i] * h, p[i + 1].dx - h, p[i + 1].dy - m[i + 1] * h,
          p[i + 1].dx, p[i + 1].dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = xLabels.length;
    if (n == 0) return;
    final plotB = size.height - _xLabelH;
    final plotH = plotB - _top;
    var maxRaw = 1.0;
    for (final s in series) {
      for (final v in s.values) {
        maxRaw = math.max(maxRaw, v);
      }
    }
    final maxV = niceMax(maxRaw);
    double y(double v) => plotB - plotH * (v / maxV);

    // Grid + y labels.
    final grid = Paint()
      ..color = exChartGrid
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final v = maxV * k / 4;
      final yy = y(v);
      canvas.drawLine(Offset(_axisW, yy), Offset(size.width, yy), grid);
      final tp = _tp('${v.round()}')..layout();
      tp.paint(canvas, Offset(_axisW - 6 - tp.width, yy - tp.height / 2));
    }

    // X labels, skipped so they never collide.
    final step = n <= 1 ? 1 : (size.width - _axisW - _side * 2) / (n - 1);
    final every = math.max(1, (52 / step).ceil());
    for (var i = 0; i < n; i++) {
      final isSel = i == selected;
      if (!(i % every == 0 || i == n - 1 && (n - 1) % every >= every / 2) && !isSel) continue;
      if (selected != null && !isSel && (i - selected!).abs() < every) continue;
      final tp = _tp(xLabels[i],
          color: isSel ? exInk : exSubtle, w: isSel ? FontWeight.w700 : FontWeight.w500)
        ..layout(maxWidth: 64);
      final cx = _x(i, size.width, n).clamp(_axisW + tp.width / 2, size.width - tp.width / 2);
      tp.paint(canvas, Offset(cx - tp.width / 2, plotB + 7));
    }

    // Reveal left → right.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, _axisW + (size.width - _axisW) * progress + 6, size.height));

    for (final s in series) {
      final pts = [for (var i = 0; i < n; i++) Offset(_x(i, size.width, n), y(s.values[i]))];
      if (pts.length >= 2) {
        final line = _smooth(pts);
        final area = Path.from(line)
          ..lineTo(pts.last.dx, plotB)
          ..lineTo(pts.first.dx, plotB)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.color.withValues(alpha: 0.20), s.color.withValues(alpha: 0.0)],
            ).createShader(Rect.fromLTRB(0, _top, size.width, plotB)),
        );
        canvas.drawPath(
          line,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
      // Point dots when the chart isn't crowded.
      if (n <= 16) {
        for (final p in pts) {
          canvas.drawCircle(p, 3.2, Paint()..color = Colors.white);
          canvas.drawCircle(
              p,
              3.2,
              Paint()
                ..color = s.color
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2);
        }
      }
    }
    canvas.restore();

    // Selection: crosshair, rings and tooltip.
    final sel = selected;
    if (sel == null || sel >= n) return;
    final sx = _x(sel, size.width, n);
    final dash = Paint()
      ..color = exSubtle.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (var yy = _top; yy < plotB; yy += 6) {
      canvas.drawLine(Offset(sx, yy), Offset(sx, math.min(yy + 3, plotB)), dash);
    }
    for (final s in series) {
      final p = Offset(sx, y(s.values[sel]));
      canvas.drawCircle(p, 7, Paint()..color = s.color.withValues(alpha: 0.18));
      canvas.drawCircle(p, 4.6, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3.4, Paint()..color = s.color);
    }

    final title = _tp(titles[sel], size: 12, color: Colors.white, w: FontWeight.w700)..layout(maxWidth: 180);
    final rows = [
      for (final s in series)
        (
          s.color,
          _tp(s.name, size: 12, color: const Color(0xFFCBD3E1))..layout(maxWidth: 120),
          _tp('${s.values[sel].round()}', size: 12.5, color: Colors.white, w: FontWeight.w800)..layout(),
        ),
    ];
    var rowW = 0.0;
    for (final r in rows) {
      rowW = math.max(rowW, 14 + r.$2.width + 14 + r.$3.width);
    }
    final w = math.max(title.width, rowW) + 22;
    final h = 10 + title.height + 6 + rows.length * 18.0 + 8;
    var left = sx + 12;
    if (left + w > size.width) left = sx - 12 - w;
    left = left.clamp(0, math.max(0, size.width - w));
    final top = _top;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top + 2, w, h), const Radius.circular(10)),
      Paint()
        ..color = const Color(0x2214243B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(10)),
      Paint()..color = exInk,
    );
    title.paint(canvas, Offset(left + 11, top + 9));
    var ry = top + 9 + title.height + 6;
    for (final r in rows) {
      canvas.drawCircle(Offset(left + 15, ry + 8), 4, Paint()..color = r.$1);
      r.$2.paint(canvas, Offset(left + 25, ry + 8 - r.$2.height / 2));
      r.$3.paint(canvas, Offset(left + w - 11 - r.$3.width, ry + 8 - r.$3.height / 2));
      ry += 18;
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.progress != progress || old.selected != selected || old.series != series || old.xLabels != xLabels;
}

// ─────────────────────────────────────────────────────────────────────────
// Donut
// ─────────────────────────────────────────────────────────────────────────

class ExDonutPart {
  final String label;
  final Color color;
  final int value;
  const ExDonutPart(this.label, this.color, this.value);
}

/// Donut with a big centre number, and a legend with count + share beside
/// it (below on narrow cards).
class ExDonut extends StatelessWidget {
  final List<ExDonutPart> parts;
  final String centerValue;
  final String centerLabel;
  const ExDonut({super.key, required this.parts, required this.centerValue, required this.centerLabel});

  @override
  Widget build(BuildContext context) {
    final total = parts.fold<int>(0, (s, p) => s + p.value);
    final ring = SizedBox(
      width: 150,
      height: 150,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: exReduceMotion(context) ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(
          painter: _DonutPainter(parts: parts, progress: t),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerValue,
                    style: const TextStyle(
                        fontFamily: exFont, fontSize: 30, height: 1, fontWeight: FontWeight.w800, color: exInk)),
                const SizedBox(height: 3),
                Text(centerLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: exSubtle)),
              ],
            ),
          ),
        ),
      ),
    );
    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in parts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: p.color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(p.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: exInk)),
                ),
                Text('${p.value}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: exInk)),
                SizedBox(
                  width: 46,
                  child: Text(total == 0 ? '' : '${(p.value * 100 / total).round()}%',
                      textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: exSubtle)),
                ),
              ],
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 360
          ? Row(children: [ring, const SizedBox(width: 22), Expanded(child: legend)])
          : Column(children: [ring, const SizedBox(height: 14), legend]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<ExDonutPart> parts;
  final double progress;
  _DonutPainter({required this.parts, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2);
    canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = exChartTrack
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    final total = parts.fold<int>(0, (s, p) => s + p.value);
    if (total == 0) return;
    final live = parts.where((p) => p.value > 0).toList();
    final gap = live.length > 1 ? 0.05 : 0.0;
    var start = -math.pi / 2;
    final sweepAll = math.pi * 2 * progress;
    for (final p in live) {
      final sweep = sweepAll * p.value / total;
      if (sweep - gap > 0) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          sweep - gap,
          false,
          Paint()
            ..color = p.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.butt,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress || old.parts != parts;
}

// ─────────────────────────────────────────────────────────────────────────
// Ring gauge (one percentage)
// ─────────────────────────────────────────────────────────────────────────

class ExRingGauge extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final Color color;
  final Color track;
  final Widget center;
  const ExRingGauge({
    super.key,
    required this.value,
    required this.center,
    this.size = 112,
    this.color = Colors.white,
    this.track = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: exReduceMotion(context) ? value : 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => CustomPaint(
            painter: _RingPainter(v, color, track),
            child: child,
          ),
          child: Center(child: center),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color;
  final Color track;
  _RingPainter(this.v, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.min(10.0, size.shortestSide / 8);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (v <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * v,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────
// Ranked bars
// ─────────────────────────────────────────────────────────────────────────

/// One row: label + value on top, a bar scaled to [max] below, optional
/// second (thinner) bar and a caption.
class ExRankRow extends StatelessWidget {
  final int rank;
  final String label;
  final int value;
  final int max;
  final Color color;
  final String valueLabel;
  final int? second;
  final Color? secondColor;
  final String? caption;
  final VoidCallback? onTap;

  const ExRankRow({
    super.key,
    required this.rank,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.valueLabel,
    this.second,
    this.secondColor,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget bar(int v, Color c, double h) => TweenAnimationBuilder<double>(
          tween: Tween(begin: exReduceMotion(context) ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, t, __) => ClipRRect(
            borderRadius: BorderRadius.circular(h / 2),
            child: SizedBox(
              height: h,
              child: Stack(
                children: [
                  Container(color: exChartTrack),
                  FractionallySizedBox(
                    widthFactor: max == 0 ? 0 : (v / max * t).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(h / 2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? const Color(0xFFFFF4DE) : exChartTrack,
              shape: BoxShape.circle,
            ),
            child: Text('$rank',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: rank == 1 ? const Color(0xFFB86E00) : exSubtle)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exInk)),
                    ),
                    const SizedBox(width: 8),
                    Text(valueLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: exInk)),
                    if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 18, color: exSubtle),
                  ],
                ),
                const SizedBox(height: 7),
                bar(value, color, 8),
                if (second != null) ...[
                  const SizedBox(height: 4),
                  bar(second!, secondColor ?? exChartLead, 5),
                ],
                if (caption != null) ...[
                  const SizedBox(height: 5),
                  Text(caption!, style: const TextStyle(fontSize: 12, color: exSubtle)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      child: content,
    );
  }
}

/// "16 leads from 42 demos": the two counts in plain words. Leads are
/// captured for the exhibition (not always for a demo), so this states the
/// numbers instead of claiming that demos turned into leads.
String exConversionWords(int demos, int leads) {
  String n(int v, String one) => '$v ${v == 1 ? one : '${one}s'}';
  if (demos == 0 && leads == 0) return 'No demos or leads yet';
  if (demos == 0) return '${n(leads, 'lead')}, no demos yet';
  if (leads == 0) return 'No leads yet from ${n(demos, 'demo')}';
  return '${n(leads, 'lead')} from ${n(demos, 'demo')}';
}

// ─────────────────────────────────────────────────────────────────────────
// Demos vs leads: two bars side by side
// ─────────────────────────────────────────────────────────────────────────

/// Two columns, demos and leads, scaled to the larger one. Leads are not a
/// part of demos (they are captured for the exhibition), so they are shown
/// side by side rather than as a slice of a pie or a filled ring.
class ExDemoLeadBars extends StatelessWidget {
  final int demos;
  final int leads;
  final double height;

  /// White / light-orange bars and white text, for gradient cards.
  final bool onDark;

  /// Values above and labels below the bars (off for the small icon size).
  final bool labels;
  final double barWidth;

  const ExDemoLeadBars({
    super.key,
    required this.demos,
    required this.leads,
    this.height = 110,
    this.onDark = false,
    this.labels = true,
    this.barWidth = 34,
  });

  @override
  Widget build(BuildContext context) {
    final top = math.max(1, math.max(demos, leads));
    final demoC = onDark ? Colors.white : exChartDemo;
    final leadC = onDark ? const Color(0xFFFFB27A) : exChartLead;
    final text = onDark ? Colors.white : exInk;
    final sub = onDark ? Colors.white.withValues(alpha: 0.75) : exSubtle;
    final track = onDark ? Colors.white.withValues(alpha: 0.14) : exChartTrack;
    const valueH = 22.0, labelH = 18.0;
    final barMax = height - (labels ? valueH + labelH : 0);

    Widget column(int v, Color c, String label) => SizedBox(
          width: barWidth + (labels ? 18 : 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (labels)
                SizedBox(
                  height: valueH,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ExCountUp(v,
                        style: TextStyle(fontFamily: exFont, fontSize: 17, fontWeight: FontWeight.w800, color: text)),
                  ),
                ),
              SizedBox(
                width: barWidth,
                height: barMax,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(barWidth / 4)),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: exReduceMotion(context) ? v / top : 0, end: v / top),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, f, __) => Container(
                        height: math.max(v > 0 ? 3.0 : 0.0, barMax * f),
                        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(barWidth / 4)),
                      ),
                    ),
                  ],
                ),
              ),
              if (labels)
                SizedBox(
                  height: labelH,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: sub)),
                    ),
                  ),
                ),
            ],
          ),
        );

    return Semantics(
      label: '$demos demos, $leads leads',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            column(demos, demoC, 'Demos'),
            SizedBox(width: labels ? 6 : barWidth / 3),
            column(leads, leadC, 'Leads'),
          ],
        ),
      ),
    );
  }
}
