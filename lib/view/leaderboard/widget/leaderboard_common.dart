import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../auth/model/LeaderboardModel.dart';

const medalGold = Color(0xFFE6A700);
const medalSilver = Color(0xFF9AA5B1);
const medalBronze = Color(0xFFB8733A);

const rankUpColor = Color(0xFF1E8E4E);
const rankDownColor = Color(0xFFC93A3A);

Color medalFor(int rank) => switch (rank) {
      1 => medalGold,
      2 => medalSilver,
      3 => medalBronze,
      _ => const Color(0xFF94A3B8),
    };

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

/// ₹4.8L / ₹1.2Cr / ₹45K style.
String formatInrShort(double v) {
  final a = v.abs();
  if (a >= 1e7) return '₹${(v / 1e7).toStringAsFixed(1)}Cr';
  if (a >= 1e5) return '₹${(v / 1e5).toStringAsFixed(1)}L';
  if (a >= 1e3) return '₹${(v / 1e3).toStringAsFixed(0)}K';
  return _inr.format(v);
}

String formatMetricValue(double v, LbMetric m) {
  if (m == LbMetric.overall) return '${v.round()}%';
  if (m.isCurrency) return formatInrShort(v);
  return v.round().toString();
}

String formatGap(double gap, LbMetric m) {
  if (m == LbMetric.overall) return '${gap.toStringAsFixed(gap < 10 ? 1 : 0)} pts';
  if (m.isCurrency) return formatInrShort(gap);
  final n = gap.round();
  return '$n ${m.label.toLowerCase().replaceAll(RegExp(r's$'), '')}${n == 1 ? '' : 's'}';
}

/// "12 of 20" / "₹3.2L of ₹6.0L"; empty for overall.
String targetLine(LbEntry e, LbMetric m) {
  if (m == LbMetric.overall) return '';
  final s = e.scores[m];
  if (s == null) return '';
  return '${formatMetricValue(s.achieved, m)} of ${formatMetricValue(s.target, m)}';
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
}

class RankChange extends StatelessWidget {
  final int? change;

  const RankChange({super.key, required this.change});

  @override
  Widget build(BuildContext context) {
    final c = change;
    if (c == null) return const SizedBox(height: 14);
    if (c == 0) {
      return Icon(Icons.remove_rounded, size: 14, color: Colors.grey.shade400);
    }
    final up = c > 0;
    final color = up ? rankUpColor : rankDownColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: 18, color: color),
        Text(
          '${c.abs()}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class MemberAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color ring;
  final bool highlight;

  const MemberAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.ring = Colors.transparent,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring == Colors.transparent ? 0 : 2.5),
      decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
      child: Container(
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFF4F6693) : const Color(0xFFE8EDF6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          initialsOf(name),
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
            color: highlight ? Colors.white : const Color(0xFF2C4463),
          ),
        ),
      ),
    );
  }
}
