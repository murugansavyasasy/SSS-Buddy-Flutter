import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' show Distance, LatLng, LengthUnit;

import '../auth/model/OverallTripDetailsModel.dart';
import '../auth/model/TrackPointModel.dart';
import '../viewModel/root_tracker_viewmodel.dart';
import 'TripRouteMap.dart';

// ─────────────────────────────────────────────
// Headline numbers (shared with the map card)
// ─────────────────────────────────────────────

class TripStats {
  final double km;
  final bool usingGps;
  final DateTime? start;
  final DateTime? last;
  final String duration;
  final int visits;
  final bool live;
  final bool hasTrip;

  const TripStats({
    required this.km,
    required this.usingGps,
    required this.start,
    required this.last,
    required this.duration,
    required this.visits,
    required this.live,
    required this.hasTrip,
  });

  factory TripStats.of(
      RootTrackerData data, List<TrackPoint> points, bool live) {
    // Real GPS line when we have one; otherwise the Status Report estimate.
    final usingGps = points.length >= 2;
    double km;
    if (usingGps) {
      km = TrackPoint.totalKm(points);
    } else {
      // Same estimate the pins and legs use, so every number agrees.
      final legs = stopDistancesKm(buildRouteStops(data.trips), const []);
      km = legs.isEmpty ? data.reportKm : legs.last;
    }
    final start = points.isNotEmpty ? points.first.time : data.firstStart;
    final ends = data.trips.map((t) => t.endDateTime).whereType<DateTime>();
    final last = points.isNotEmpty
        ? points.last.time
        : (ends.isEmpty ? null : ends.reduce((a, b) => a.isAfter(b) ? a : b));

    String duration = "--";
    if (start != null && (live || last != null)) {
      final until = live ? DateTime.now() : last!;
      final d = until.difference(start);
      if (!d.isNegative) {
        duration =
            "${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m";
      }
    }

    return TripStats(
      km: km,
      usingGps: usingGps,
      start: start,
      last: last,
      duration: duration,
      visits: data.visitCount,
      live: live,
      hasTrip: data.hasTrip || points.isNotEmpty,
    );
  }
}

// ─────────────────────────────────────────────
// Timeline entries
// ─────────────────────────────────────────────

class _Entry {
  final RouteStop stop;
  final double legKm; // from the previous entry
  final DateTime? time; // start/end time, or arrival at a school
  final bool approx; // arrival estimated from the GPS track
  final bool current; // last school of a live trip

  const _Entry({
    required this.stop,
    required this.legKm,
    required this.time,
    required this.approx,
    required this.current,
  });
}

/// Route timeline for one member/day: start → schools → end with the km
/// between every consecutive stop. Shows the live layout while a trip is
/// running and a completion summary once it has ended.
class TripTimelineView extends StatefulWidget {
  final RootTrackerData data;
  final List<TrackPoint> points;
  final bool live;
  final VoidCallback onViewMap;
  final Future<void> Function() onRefresh;

  const TripTimelineView({
    super.key,
    required this.data,
    required this.points,
    required this.live,
    required this.onViewMap,
    required this.onRefresh,
  });

  @override
  State<TripTimelineView> createState() => _TripTimelineViewState();
}

class _TripTimelineViewState extends State<TripTimelineView> {
  static const Color _ink = Color(0xFF1A1F36);
  static const Color _body = Color(0xFF4A5468);
  static const Color _muted = Color(0xFF5B6475);
  static const Color _border = Color(0xFFE3E8F0);
  static const Color _soft = Color(0xFFF4F6FA);
  static const Color _navy = Color(0xFF2C4463);
  static const Color _okText = Color(0xFF137333);
  static const Color _okBg = Color(0xFFE6F4EA);

  static const double _arrivalRadiusM = 300;

  final DateFormat _fmt = DateFormat('hh:mm a');
  final Map<String, Future<String>> _addresses = {};

  List<RouteStop> _stops = [];
  String _stopsKey = '';
  String _entriesKey = '';
  List<_Entry> _entries = const [];
  double _afterLastKm = 0; // GPS km after the last stop

  @override
  void initState() {
    super.initState();
    _refreshStops();
  }

  @override
  void didUpdateWidget(covariant TripTimelineView old) {
    super.didUpdateWidget(old);
    _refreshStops();
  }

  void _refreshStops() {
    final stops = buildRouteStops(widget.data.trips);
    final key = stops
        .map((s) => '${s.point.latitude},${s.point.longitude}')
        .join('|');
    if (key == _stopsKey) return;
    _stops = stops;
    _stopsKey = key;
  }

  List<_Entry> _buildEntries() {
    final key = '$_stopsKey#${widget.points.length}#${widget.live}';
    if (key == _entriesKey) return _entries;

    final track = widget.points;
    // GPS track when recorded; otherwise the Status Report estimate.
    final line = track.length >= 2
        ? track.map((p) => p.latLng).toList()
        : const <LatLng>[];
    final segments =
        track.length >= 2 ? track.map((p) => p.segment).toList() : null;
    final km = stopDistancesKm(_stops, line, segments: segments);
    _afterLastKm = kmAfterLastStop(_stops, line, segments);
    final onTrack = track.length >= 2
        ? snapStopsToLine(_stops.map((s) => s.point).toList(), line)
        : null;
    const d = Distance();

    final out = <_Entry>[];
    for (var i = 0; i < _stops.length; i++) {
      final s = _stops[i];
      DateTime? time = s.at;
      var approx = false;
      if (s.kind == StopKind.visit && onTrack != null) {
        final p = track[onTrack[i]];
        if (d.as(LengthUnit.Meter, p.latLng, s.point) <= _arrivalRadiusM) {
          time = p.time;
          approx = true;
        }
      }
      out.add(_Entry(
        stop: s,
        legKm: i == 0 ? 0 : math.max(0, km[i] - km[i - 1]),
        time: time,
        approx: approx,
        current: widget.live &&
            s.kind == StopKind.visit &&
            i == _stops.length - 1,
      ));
    }
    _entriesKey = key;
    _entries = out;
    return out;
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stats = TripStats.of(widget.data, widget.points, widget.live);
    if (_stops.isEmpty) return _emptyState();

    final entries = _buildEntries();
    // Legs + whatever was driven after the last stop = the GPS total above.
    final totalKm =
        entries.fold<double>(0, (sum, e) => sum + e.legKm) + _afterLastKm;
    final completed = !widget.live && widget.data.hasTrip;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: completed
            ? _completedLayout(entries, stats, totalKm)
            : _liveLayout(entries, stats, totalKm),
      ),
    );
  }

  List<Widget> _liveLayout(
      List<_Entry> entries, TripStats stats, double totalKm) {
    return [
      _statsStrip(stats),
      if (entries.isNotEmpty && entries.last.current) ...[
        const SizedBox(height: 12),
        _currentCard(entries),
      ],
      const SizedBox(height: 12),
      _timelineCard(entries, totalKm),
    ];
  }

  List<Widget> _completedLayout(
      List<_Entry> entries, TripStats stats, double totalKm) {
    final legs = entries.length - 1;
    return [
      _completedHero(entries),
      const SizedBox(height: 12),
      Row(
        children: [
          _totalTile(stats.usingGps ? "Total distance" : "Total distance (approx.)",
              stats.km.toStringAsFixed(2), "km"),
          const SizedBox(width: 10),
          _totalTile("Schools visited", "${stats.visits}", null),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _totalTile("Trip duration", stats.duration, null),
          const SizedBox(width: 10),
          _totalTile(
            "Average per leg",
            legs > 0
                ? ((totalKm - _afterLastKm) / legs).toStringAsFixed(2)
                : "--",
            legs > 0 ? "km" : null,
          ),
        ],
      ),
      if (legs > 0) ...[
        const SizedBox(height: 12),
        _legsCard(entries, totalKm, stats.usingGps),
      ],
      const SizedBox(height: 12),
      _endpointsCard(entries),
      const SizedBox(height: 16),
      SizedBox(
        height: 50,
        child: FilledButton.icon(
          onPressed: widget.onViewMap,
          icon: const Icon(Icons.map_outlined, size: 20),
          label: const Text("View route on map",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: TripColors.current,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ];
  }

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.route_rounded, size: 48, color: _muted),
          SizedBox(height: 12),
          Text(
            "No trip on this day.\nTap START in Today Visit to begin tracking.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _body, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Live layout pieces
  // ─────────────────────────────────────────────

  Widget _statsStrip(TripStats st) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(st.km.toStringAsFixed(2),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(st.usingGps ? "km travelled" : "km (approx.)",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _muted)),
              ),
              const SizedBox(width: 8),
              st.live
                  ? _statusChip("LIVE", _okText, _okBg)
                  : st.hasTrip
                      ? _statusChip("ENDED", _body, const Color(0xFFEEF0F3))
                      : _statusChip("NO TRIP", const Color(0xFFC5221F),
                          const Color(0xFFFCE8E6)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat("Started", st.start == null ? "--" : _fmt.format(st.start!)),
              _stat("Schools", "${st.visits}"),
              _stat("Duration", st.duration),
            ],
          ),
        ],
      ),
    );
  }

  Widget _currentCard(List<_Entry> entries) {
    final cur = entries.last;
    final prev = entries.length >= 2 ? entries[entries.length - 2] : null;
    final from = prev == null
        ? null
        : switch (prev.stop.kind) {
            StopKind.start => "trip start",
            StopKind.end => "previous trip end",
            StopKind.visit => prev.stop.title,
          };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(border: TripColors.current, width: 1.5).copyWith(
        boxShadow: [
          BoxShadow(
            color: TripColors.current.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: TripColors.current,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFFDCE3EE), spreadRadius: 4)
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _sectionTitle("Current visit", color: TripColors.current),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _marker(cur, 40, ring: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cur.stop.title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            height: 1.25)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        if (from != null)
                          _iconText(Icons.south_rounded,
                              "${cur.legKm.toStringAsFixed(2)} km from $from"),
                        if (cur.time != null)
                          _iconText(Icons.schedule_rounded,
                              "Arrived ${_fmt.format(cur.time!)}${cur.approx ? ' (approx.)' : ''}"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineCard(List<_Entry> entries, double totalKm) {
    final schools = entries.where((e) => e.stop.kind == StopKind.visit).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(child: _sectionTitle("Route timeline")),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$schools ${schools == 1 ? 'school' : 'schools'} · "
                  "${totalKm.toStringAsFixed(2)} km",
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) _legRow(entries[i]),
            _nodeRow(
              entries[i],
              below: i == entries.length - 1
                  ? null
                  : _legColor(entries[i + 1]),
            ),
          ],
          if (_afterLastKm >= 0.05) ...[
            const SizedBox(height: 6),
            _afterLastRow(entries.last),
          ],
        ],
      ),
    );
  }

  Widget _afterLastRow(_Entry last) {
    return Row(
      children: [
        const SizedBox(
          width: 32,
          child: Icon(Icons.more_vert_rounded, size: 18, color: _muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "+${_afterLastKm.toStringAsFixed(2)} km travelled after "
            "${last.stop.kind == StopKind.visit ? last.stop.title : last.stop.title.toLowerCase()}",
            style: const TextStyle(fontSize: 12.5, color: _body),
          ),
        ),
      ],
    );
  }

  Color _legColor(_Entry to) =>
      to.current ? TripColors.current : TripColors.visited;

  Widget _legRow(_Entry to) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 40,
          child: Center(child: Container(width: 2, color: _legColor(to))),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.south_rounded, size: 13, color: _navy),
              const SizedBox(width: 6),
              Text("${to.legKm.toStringAsFixed(2)} km",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _navy)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nodeRow(_Entry e, {Color? below}) {
    final content = _nodeContent(e);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _marker(e, 32),
                if (below != null)
                  Expanded(child: Container(width: 2, color: below)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: e.current
                ? Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC9D3E3)),
                    ),
                    child: content,
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: content,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _nodeContent(_Entry e) {
    final s = e.stop;
    if (s.kind == StopKind.visit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
              ),
              const SizedBox(width: 8),
              e.current
                  ? _pill("Current", Colors.white, TripColors.current)
                  : _pill("Visited", _okText, _okBg),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            e.time != null
                ? "Arrived ${_fmt.format(e.time!)}${e.approx ? ' (approx.)' : ''}"
                : "School ${s.label}",
            style: const TextStyle(fontSize: 12.5, color: _body),
          ),
        ],
      );
    }

    final timeText = _stopTime(e);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
            ),
            if (timeText != null)
              Text(timeText,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _body)),
          ],
        ),
        const SizedBox(height: 3),
        _address(s.point),
        const SizedBox(height: 2),
        Text(
          "GPS ${s.point.latitude.toStringAsFixed(5)}, "
          "${s.point.longitude.toStringAsFixed(5)}",
          style: const TextStyle(
              fontSize: 11.5,
              color: _muted,
              fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Completed layout pieces
  // ─────────────────────────────────────────────

  Widget _completedHero(List<_Entry> entries) {
    final start = entries.first.time;
    final endEntry =
        entries.lastWhere((e) => e.stop.kind == StopKind.end, orElse: () => entries.last);
    final end = endEntry.stop.kind == StopKind.end ? endEntry.time : null;
    final parts = <String>[
      DateFormat('EEE, dd MMM yyyy').format(widget.data.date),
      if (start != null)
        "${_fmt.format(start)}${end != null ? ' – ${_fmt.format(end)}' : ''}",
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: _card(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration:
                const BoxDecoration(color: _okBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 30, color: _okText),
          ),
          const SizedBox(height: 12),
          const Text("Trip completed",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 6),
          Text(parts.join(" · "),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _body)),
        ],
      ),
    );
  }

  Widget _totalTile(String label, String value, String? unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _card(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                text: value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _ink),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: " $unit",
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legsCard(List<_Entry> entries, double totalKm, bool usingGps) {
    final maxLeg = entries.skip(1).map((e) => e.legKm).fold<double>(0, math.max);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle("Distance by leg"),
          const SizedBox(height: 14),
          for (var i = 1; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _marker(entries[i - 1], 22, ring: false),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 12, color: Color(0xFF8792A6)),
                      ),
                      _marker(entries[i], 22, ring: false),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entries[i].stop.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 13, color: _body)),
                      ),
                      const SizedBox(width: 8),
                      Text("${entries[i].legKm.toStringAsFixed(2)} km",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: maxLeg > 0 ? entries[i].legKm / maxLeg : 0,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFEEF1F5),
                      color: maxLeg > 0 && entries[i].legKm == maxLeg
                          ? TripColors.current
                          : const Color(0xFF8FA3C8),
                    ),
                  ),
                ],
              ),
            ),
          if (_afterLastKm >= 0.05)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text("After the last stop",
                        style: TextStyle(fontSize: 13, color: _body)),
                  ),
                  Text("${_afterLastKm.toStringAsFixed(2)} km",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ],
              ),
            ),
          const Divider(height: 1, color: Color(0xFFEEF1F5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                    usingGps ? "Total travelled" : "Total (approx.)",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _navy)),
              ),
              const SizedBox(width: 8),
              Text("${totalKm.toStringAsFixed(2)} km",
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: _navy)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _endpointsCard(List<_Entry> entries) {
    final start = entries.firstWhere((e) => e.stop.kind == StopKind.start,
        orElse: () => entries.first);
    final ends = entries.where((e) => e.stop.kind == StopKind.end);
    final end = ends.isEmpty ? null : ends.last;

    Widget row(_Entry e, String verb) {
      final t = _stopTime(e);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _marker(e, 30, ring: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t == null ? verb : "$verb · $t",
                    style: const TextStyle(fontSize: 12, color: _muted)),
                const SizedBox(height: 2),
                _address(e.stop.point,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        children: [
          row(start, "Started"),
          if (end != null) ...[
            const SizedBox(height: 14),
            row(end, "Ended"),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Small pieces
  // ─────────────────────────────────────────────

  String? _stopTime(_Entry e) {
    if (e.time != null) return _fmt.format(e.time!);
    final raw = e.stop.time?.trim() ?? '';
    return raw.isEmpty || raw.toLowerCase() == 'null' ? null : raw;
  }

  Widget _address(LatLng p, {TextStyle? style}) {
    final key =
        '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
    final future = _addresses.putIfAbsent(
      key,
      () => TripAddressLoader.getCachedAddress(
          latitude: p.latitude, longitude: p.longitude),
    );
    final textStyle =
        style ?? const TextStyle(fontSize: 12.5, color: _body, height: 1.35);
    return FutureBuilder<String>(
      future: future,
      builder: (context, snap) => Text(
        snap.connectionState == ConnectionState.done
            ? (snap.data ?? "Address unavailable")
            : "Fetching address…",
        style: snap.connectionState == ConnectionState.done
            ? textStyle
            : textStyle.copyWith(color: _muted, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget _marker(_Entry e, double size, {bool ring = true}) {
    final s = e.stop;
    final color = e.current
        ? TripColors.current
        : switch (s.kind) {
            StopKind.start => TripColors.start,
            StopKind.visit => TripColors.visited,
            StopKind.end => TripColors.end,
          };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: ring && e.current
            ? const [BoxShadow(color: Color(0xFFDCE3EE), spreadRadius: 5)]
            : null,
      ),
      child: switch (s.kind) {
        StopKind.start =>
          Icon(Icons.flag_rounded, size: size * 0.5, color: Colors.white),
        StopKind.end =>
          Icon(Icons.stop_rounded, size: size * 0.55, color: Colors.white),
        StopKind.visit => Text(
            s.label,
            style: TextStyle(
                color: Colors.white,
                fontSize: size * (s.label.length > 2 ? 0.34 : 0.44),
                fontWeight: FontWeight.w800),
          ),
      },
    );
  }

  BoxDecoration _card({Color? border, double width = 1, double radius = 18}) =>
      BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? _border, width: width),
      );

  Widget _sectionTitle(String text, {Color color = _body}) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: color),
      );

  Widget _statusChip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: fg)),
        ],
      ),
    );
  }

  Widget _pill(String label, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: _muted)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _body),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              style: const TextStyle(fontSize: 12.5, color: _body)),
        ),
      ],
    );
  }
}
