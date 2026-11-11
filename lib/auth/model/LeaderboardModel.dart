import 'package:flutter/material.dart';

enum LbMetric {
  overall('Overall', Icons.emoji_events_rounded, false),
  demos('Demos', Icons.co_present_rounded, false),
  pos('POs', Icons.description_rounded, false),
  poValue('PO Value', Icons.trending_up_rounded, true),
  collection('Collection', Icons.account_balance_wallet_rounded, true);

  final String label;
  final IconData icon;
  final bool isCurrency;

  const LbMetric(this.label, this.icon, this.isCurrency);

  /// Metrics that have their own target (overall is derived from these).
  static const scored = [demos, pos, poValue, collection];
}

enum LbPeriod {
  week('This Week'),
  month('This Month'),
  quarter('This Quarter');

  final String label;

  const LbPeriod(this.label);
}

class LbScore {
  final double achieved;
  final double target;

  const LbScore(this.achieved, this.target);

  /// Achievement as a fraction of target (can exceed 1).
  double get ratio => target <= 0 ? 0 : achieved / target;
}

class LbMember {
  final String id;
  final String name;
  final String role;

  const LbMember({required this.id, required this.name, this.role = ''});
}

class LbEntry {
  final LbMember member;
  final bool isMe;
  final Map<LbMetric, LbScore> scores;

  /// Rank in the previous period for the overall score; null if unknown.
  final int? previousRank;

  const LbEntry({
    required this.member,
    required this.isMe,
    required this.scores,
    this.previousRank,
  });

  /// Average % of target across the scored metrics, each capped at 150%
  /// so one huge number can't carry the whole score.
  double get overallScore {
    final r = LbMetric.scored
        .map((m) => (scores[m]?.ratio ?? 0).clamp(0.0, 1.5))
        .toList();
    return r.isEmpty ? 0 : r.reduce((a, b) => a + b) / r.length * 100;
  }

  /// Value used for ranking by [metric].
  double valueFor(LbMetric metric) => metric == LbMetric.overall
      ? overallScore
      : scores[metric]?.achieved ?? 0;

  /// 0..1 progress towards target for [metric] (overall: score / 100).
  double progressFor(LbMetric metric) => metric == LbMetric.overall
      ? (overallScore / 100).clamp(0.0, 1.0)
      : (scores[metric]?.ratio ?? 0).clamp(0.0, 1.0);
}

/// An entry with its rank for the selected metric.
class RankedEntry {
  final int rank;
  final LbEntry entry;

  const RankedEntry(this.rank, this.entry);

  /// Positive = moved up since last period (overall ranking only).
  int? get rankChange =>
      entry.previousRank == null ? null : entry.previousRank! - rank;
}

/// Ranks by value (desc); equal values share a rank (1, 2, 2, 4).
List<RankedEntry> rankEntries(List<LbEntry> entries, LbMetric metric) {
  final sorted = [...entries]
    ..sort((a, b) {
      final c = b.valueFor(metric).compareTo(a.valueFor(metric));
      return c != 0 ? c : a.member.name.compareTo(b.member.name);
    });
  final out = <RankedEntry>[];
  for (var i = 0; i < sorted.length; i++) {
    final tie = i > 0 &&
        sorted[i].valueFor(metric) == sorted[i - 1].valueFor(metric);
    out.add(RankedEntry(tie ? out[i - 1].rank : i + 1, sorted[i]));
  }
  return out;
}
