import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../auth/model/OverallTripDetailsModel.dart';
import '../auth/model/TrackPointModel.dart';
import '../core/location/road_route_service.dart';

// ─────────────────────────────────────────────
// Stops: every lat/long of a day's trips, in order
// ─────────────────────────────────────────────

enum StopKind { start, visit, end }

class RouteStop {
  final LatLng point;
  final StopKind kind;
  final String label; // text inside the pin
  final String title;
  final String? time;
  final List<String> details;

  const RouteStop({
    required this.point,
    required this.kind,
    required this.label,
    required this.title,
    this.time,
    this.details = const [],
  });
}

LatLng? _coord(String? lat, String? lng) {
  if ((lat ?? '').trim().isEmpty || (lng ?? '').trim().isEmpty) return null;
  try {
    final a = DistanceCalculator.parseCoordinate(lat!);
    final b = DistanceCalculator.parseCoordinate(lng!);
    if (a == 0 && b == 0) return null;
    if (a.abs() > 90 || b.abs() > 180) return null;
    return LatLng(a, b);
  } catch (_) {
    return null;
  }
}

/// START → visits → END for each trip (oldest trip first).
/// Visits are numbered 1, 2, 3… across the whole day.
List<RouteStop> buildRouteStops(List<Overalltripdetailsmodel> trips) {
  final sorted = List.of(trips)
    ..sort((a, b) {
      final x = a.startDateTime, y = b.startDateTime;
      if (x == null || y == null) return 0;
      return x.compareTo(y);
    });

  final stops = <RouteStop>[];
  int visitNo = 0;
  for (final t in sorted) {
    final multi = sorted.length > 1;
    final start = _coord(t.start_latitude, t.start_longitude);
    if (start != null) {
      stops.add(RouteStop(
        point: start,
        kind: StopKind.start,
        label: 'S',
        title: multi ? 'Trip #${t.trip_id} started' : 'Trip started',
        time: t.start_time.trim(),
      ));
    }
    for (final v in t.visit_details) {
      final p = _coord(v.school_latitude, v.school_longitude);
      if (p == null) continue;
      visitNo++;
      stops.add(RouteStop(
        point: p,
        kind: StopKind.visit,
        label: '$visitNo',
        title: (v.school_name ?? '').trim().isEmpty
            ? 'Visit $visitNo'
            : v.school_name!.trim(),
        details: [
          if ((v.person_name ?? '').trim().isNotEmpty) 'Met: ${v.person_name}',
          if ((v.reason_of_visit ?? '').trim().isNotEmpty)
            'Reason: ${v.reason_of_visit}',
          if ((v.remarks ?? '').trim().isNotEmpty) 'Remarks: ${v.remarks}',
        ],
      ));
    }
    final end = _coord(t.end_latitude, t.end_longitude);
    if (end != null) {
      stops.add(RouteStop(
        point: end,
        kind: StopKind.end,
        label: 'E',
        title: multi ? 'Trip #${t.trip_id} ended' : 'Trip ended',
        time: t.end_time?.trim(),
      ));
    }
  }
  return stops;
}

// ─────────────────────────────────────────────
// Map
// ─────────────────────────────────────────────

/// Google-Maps-style trip map: a road path through every stop with a
/// numbered pin on each lat/long. When GPS breadcrumbs ([track]) exist,
/// the actually travelled line is drawn instead of the estimated road path.
class TripRouteMap extends StatefulWidget {
  final List<Overalltripdetailsmodel> trips;
  final List<TrackPoint> track;
  final bool live;
  final bool compact;
  final VoidCallback? onTap;
  final EdgeInsets fitPadding;

  const TripRouteMap({
    super.key,
    required this.trips,
    this.track = const [],
    this.live = false,
    this.compact = false,
    this.onTap,
    this.fitPadding = const EdgeInsets.all(48),
  });

  @override
  State<TripRouteMap> createState() => TripRouteMapState();
}

class TripRouteMapState extends State<TripRouteMap> {
  static const Color _blue = Color(0xFF1A73E8);
  static const Color _green = Color(0xFF188038);
  static const Color _red = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF3C4043);
  static const LatLng _fallbackCenter = LatLng(13.0827, 80.2707);

  final MapController _map = MapController();
  bool _ready = false;
  List<RouteStop> _stops = [];
  String _stopsKey = '';
  List<LatLng>? _road;
  bool _routing = false;
  String? _fittedKey;

  @override
  void initState() {
    super.initState();
    _refreshStops();
  }

  @override
  void didUpdateWidget(covariant TripRouteMap old) {
    super.didUpdateWidget(old);
    _refreshStops();
  }

  void _refreshStops() {
    final stops = buildRouteStops(widget.trips);
    final key = stops
        .map((s) => '${s.point.latitude},${s.point.longitude}')
        .join('|');
    if (key == _stopsKey) return;
    _stops = stops;
    _stopsKey = key;
    _road = null;
    _routing = false;
    _fetchRoad(key);
    _scheduleFit();
  }

  Future<void> _fetchRoad(String key) async {
    if (_stops.length < 2) return;
    // Called from initState/didUpdateWidget, where a build follows anyway.
    _routing = true;
    final path = await RoadRouteService.route(_stops.map((s) => s.point).toList());
    if (!mounted || key != _stopsKey) return;
    setState(() {
      _road = path;
      _routing = false;
    });
  }

  List<LatLng> get _allPoints => [
        ..._stops.map((s) => s.point),
        ...widget.track.map((p) => p.latLng),
      ];

  void _scheduleFit() {
    if (!_ready) return; // onMapReady will fit
    WidgetsBinding.instance.addPostFrameCallback((_) => fit());
  }

  void zoomBy(double delta) {
    if (!_ready) return;
    final c = _map.camera;
    _map.move(c.center, (c.zoom + delta).clamp(3, 19).toDouble());
  }

  /// Zooms so every pin and the whole line are visible.
  void fit() {
    if (!mounted || !_ready) return;
    final all = _allPoints;
    if (all.isEmpty) return;
    _fittedKey = _stopsKey;
    if (all.length == 1) {
      _map.move(all.first, 15);
      return;
    }
    _map.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(all),
      padding: widget.fitPadding,
      maxZoom: 16,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Track arrives after the first frame (live trip) → fit once.
    if (_ready && _fittedKey == null && _allPoints.isNotEmpty) _scheduleFit();

    final segments = TrackPoint.segments(widget.track)
        .where((s) => s.length >= 2)
        .toList();
    final useTrack = segments.isNotEmpty;
    final stopPoints = _stops.map((s) => s.point).toList();
    final first = _stops.isNotEmpty
        ? _stops.first.point
        : (widget.track.isNotEmpty ? widget.track.first.latLng : null);

    final map = FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: first ?? _fallbackCenter,
        initialZoom: first == null ? 11 : 14,
        maxZoom: 19,
        minZoom: 3,
        interactionOptions: InteractionOptions(
          flags: widget.compact
              ? InteractiveFlag.none
              : InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: widget.compact && widget.onTap != null
            ? (_, __) => widget.onTap!()
            : null,
        onMapReady: () {
          _ready = true;
          fit();
        },
      ),
      children: [
        // CARTO "Voyager" – OpenStreetMap data in a Google-Maps-like style.
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.sss.buddy',
          maxZoom: 19,
        ),
        PolylineLayer(polylines: [
          if (useTrack)
            for (final seg in segments) ..._styledLine(seg)
          else if (_road != null)
            ..._styledLine(_road!)
          else if (stopPoints.length >= 2)
            // Routing pending / offline: dashed straight lines.
            Polyline(
              points: stopPoints,
              strokeWidth: 4,
              color: _blue.withOpacity(0.8),
              pattern: StrokePattern.dashed(segments: const [12, 8]),
            ),
        ]),
        MarkerLayer(markers: [
          // Draw visits first so START/END pins sit on top.
          for (final s in _stops.where((s) => s.kind == StopKind.visit))
            _pinMarker(s),
          for (final s in _stops.where((s) => s.kind != StopKind.visit))
            _pinMarker(s),
          if (widget.live && widget.track.isNotEmpty)
            Marker(
              point: widget.track.last.latLng,
              width: 44,
              height: 44,
              child: const _LiveDot(color: _blue),
            ),
        ]),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors, © CARTO'),
          backgroundColor: Color(0xCCFFFFFF),
        ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(child: map),
        if (_routing && !useTrack)
          const Positioned(
            top: 10,
            left: 10,
            child: _Chip(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Finding road path…', style: TextStyle(fontSize: 12)),
              ]),
            ),
          ),
        if (widget.compact && widget.onTap != null)
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: widget.onTap,
              child: const _Chip(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.open_in_full_rounded, size: 14, color: _blue),
                  SizedBox(width: 6),
                  Text('Full map',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _blue)),
                ]),
              ),
            ),
          ),
        if (_stops.isEmpty && widget.track.isEmpty)
          const Center(
            child: _Chip(
              child: Text('No location recorded for this day',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }

  List<Polyline> _styledLine(List<LatLng> pts) => [
        Polyline(
          points: pts,
          strokeWidth: 8,
          color: const Color(0xFF0B57D0),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
        Polyline(
          points: pts,
          strokeWidth: 5,
          color: const Color(0xFF4285F4),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ];

  Marker _pinMarker(RouteStop s) {
    final color = switch (s.kind) {
      StopKind.start => _green,
      StopKind.visit => _red,
      StopKind.end => _dark,
    };
    return Marker(
      point: s.point,
      width: 34,
      height: 46,
      alignment: Alignment.topCenter, // pin tip sits on the lat/long
      child: GestureDetector(
        onTap: widget.compact ? widget.onTap : () => _showStop(s, color),
        child: _Pin(color: color, label: s.label),
      ),
    );
  }

  void _showStop(RouteStop s, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 34, height: 46, child: _Pin(color: color, label: s.label)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    if ((s.time ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(s.time!,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                    ],
                    for (final d in s.details) ...[
                      const SizedBox(height: 4),
                      Text(d, style: const TextStyle(fontSize: 13)),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${s.point.latitude.toStringAsFixed(5)}, '
                      '${s.point.longitude.toStringAsFixed(5)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pin widgets
// ─────────────────────────────────────────────

class _Pin extends StatelessWidget {
  final Color color;
  final String label;
  const _Pin({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 46,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PinPainter(color))),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 34,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: label.length > 2 ? 10 : 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  const _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = w / 2;
    final path = Path()
      ..moveTo(r, h)
      ..cubicTo(r - r * 0.35, h - r * 0.55, 0, r * 1.45, 0, r)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..cubicTo(w, r * 1.45, r + r * 0.35, h - r * 0.55, r, h)
      ..close();

    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

class _LiveDot extends StatelessWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration:
            BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Widget child;
  const _Chip({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: child,
    );
  }
}
