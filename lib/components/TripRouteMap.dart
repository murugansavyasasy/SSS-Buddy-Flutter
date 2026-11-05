import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show Distance, LatLng, LengthUnit;
import 'package:vector_map_tiles/vector_map_tiles.dart'
    show Style, VectorTileLayer, VectorTileLayerMode;

import '../auth/model/OverallTripDetailsModel.dart';
import '../auth/model/TrackPointModel.dart';
import '../core/location/map_style_service.dart';
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
  final DateTime? at; // parsed [time], when the API format allows
  final List<String> details;

  const RouteStop({
    required this.point,
    required this.kind,
    required this.label,
    required this.title,
    this.time,
    this.at,
    this.details = const [],
  });
}

/// One colour per stop state, shared by the map pins and the timeline.
class TripColors {
  static const Color start = Color(0xFF2C4463);
  static const Color visited = Color(0xFF188038);
  static const Color current = Color(0xFF4F6693);
  static const Color end = Color(0xFF3C4043);
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
/// Start is a flag pin, visits are numbered 1, 2, 3… across the whole day.
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
        at: t.startDateTime,
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
        at: t.endDateTime,
      ));
    }
  }
  return stops;
}

/// For each stop (in order), the index of the nearest point on [line],
/// searched forward from the previous stop's match so stops never snap
/// backwards onto an earlier pass of the same road.
List<int> snapStopsToLine(List<LatLng> stops, List<LatLng> line) {
  const d = Distance();
  final out = <int>[];
  var from = 0;
  for (final p in stops) {
    var best = from;
    var bestD = double.infinity;
    for (var j = from; j < line.length; j++) {
      final dd = d.as(LengthUnit.Meter, line[j], p);
      if (dd < bestD) {
        bestD = dd;
        best = j;
      }
    }
    from = best;
    out.add(best);
  }
  return out;
}

/// Km from the first stop to each stop, measured along [line] (GPS track
/// or road path); straight lines between stops when there is no line.
///
/// Pass the track's [segments] when [line] is the GPS track: distance is
/// then counted exactly like [TrackPoint.totalKm] (from the first GPS fix,
/// no jump across a GPS gap), so the last stop's km plus [kmAfterLastStop]
/// equals the "km travelled" total shown on screen.
List<double> stopDistancesKm(List<RouteStop> stops, List<LatLng> line,
    {List<int>? segments}) {
  if (stops.isEmpty) return const [];
  if (line.length < 2) {
    // No GPS track: the same estimate Status Report uses (straight line
    // between stops × road factor), so pins, legs and the total agree.
    final out = <double>[0];
    double acc = 0;
    for (var i = 1; i < stops.length; i++) {
      acc += approxLegKm(stops[i - 1].point, stops[i].point);
      out.add(acc);
    }
    return out;
  }
  final cum = _cumulativeMeters(line, segments);
  final idx = snapStopsToLine(stops.map((s) => s.point).toList(), line);
  if (segments != null) {
    // GPS: count from the first fix; the start pin itself reads 0.
    return [0, for (var i = 1; i < idx.length; i++) cum[idx[i]] / 1000];
  }
  final base = cum[idx.first];
  return idx.map((i) => (cum[i] - base) / 1000).toList();
}

/// Status Report's approximate road km between two points.
double approxLegKm(LatLng a, LatLng b) =>
    DistanceCalculator.totalApproximateRoadDistance([
      [a.latitude, a.longitude],
      [b.latitude, b.longitude],
    ]);

/// GPS km travelled after the last stop (e.g. still driving after the last
/// school). 0 when [line] is not a GPS track.
double kmAfterLastStop(
    List<RouteStop> stops, List<LatLng> line, List<int>? segments) {
  if (stops.isEmpty || segments == null || line.length < 2) return 0;
  final cum = _cumulativeMeters(line, segments);
  final last = snapStopsToLine(stops.map((s) => s.point).toList(), line).last;
  return (cum.last - cum[last]) / 1000;
}

List<double> _cumulativeMeters(List<LatLng> line, List<int>? segments) {
  const d = Distance();
  final cum = List<double>.filled(line.length, 0);
  for (var i = 1; i < line.length; i++) {
    final gap = segments != null && segments[i] != segments[i - 1];
    cum[i] = cum[i - 1] +
        (gap ? 0 : d.as(LengthUnit.Meter, line[i - 1], line[i]));
  }
  return cum;
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
  static const LatLng _fallbackCenter = LatLng(13.0827, 80.2707);

  final MapController _map = MapController();
  bool _ready = false;
  List<RouteStop> _stops = [];
  String _stopsKey = '';
  List<LatLng>? _road;
  bool _routing = false;
  String? _fittedKey;
  final Map<String, Future<String>> _addressCache = {};

  /// OpenFreeMap "bright" vector style; null while loading.
  Style? _style;
  bool _styleFailed = false;

  @override
  void initState() {
    super.initState();
    _refreshStops();
    MapStyleService.bright().then((style) {
      if (mounted) setState(() => _style = style);
    }).catchError((e) {
      print("OpenFreeMap style Error => $e");
      if (mounted) setState(() => _styleFailed = true);
    });
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
        backgroundColor: const Color(0xFFF2EFE9), // "bright" land colour
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
        // OpenFreeMap "bright" vector style. Falls back to CARTO raster
        // tiles only if the style can't be loaded.
        if (_style != null)
          VectorTileLayer(
            theme: _style!.theme,
            sprites: _style!.sprites,
            tileProviders: _style!.providers,
            layerMode: VectorTileLayerMode.raster,
            maximumZoom: 19,
          )
        else if (_styleFailed)
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
        SimpleAttributionWidget(
          source: Text(_styleFailed
              ? 'OpenStreetMap contributors, © CARTO'
              : 'OpenFreeMap © OpenMapTiles, OpenStreetMap contributors'),
          backgroundColor: const Color(0xCCFFFFFF),
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
    final color = _stopColor(s);
    return Marker(
      point: s.point,
      width: 34,
      height: 46,
      alignment: Alignment.topCenter, // pin tip sits on the lat/long
      child: GestureDetector(
        onTap: widget.compact ? widget.onTap : () => _showStop(s, color),
        child: _Pin(color: color, label: s.label, icon: _stopIcon(s)),
      ),
    );
  }

  Future<String> _addressFor(LatLng p) {
    final key =
        '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
    return _addressCache.putIfAbsent(
      key,
      () => AddressService.getAddress(
          latitude: p.latitude, longitude: p.longitude),
    );
  }

  /// Km from the day's first pin to each stop along the drawn line.
  bool get _usesTrack => widget.track.length >= 2;

  /// Km are measured on the GPS track only; without one, stops use the
  /// Status Report estimate (the road path is just drawn).
  List<LatLng> get _distanceLine => _usesTrack
      ? widget.track.map((p) => p.latLng).toList()
      : const <LatLng>[];

  List<int>? get _trackSegments =>
      _usesTrack ? widget.track.map((p) => p.segment).toList() : null;

  List<double> _stopDistancesKm() =>
      stopDistancesKm(_stops, _distanceLine, segments: _trackSegments);

  /// The last visit of a live trip is where the member is right now.
  bool _isCurrent(RouteStop s) =>
      widget.live &&
      s.kind == StopKind.visit &&
      _stops.isNotEmpty &&
      identical(s, _stops.last);

  Color _stopColor(RouteStop s) => switch (s.kind) {
        StopKind.start => TripColors.start,
        StopKind.visit =>
          _isCurrent(s) ? TripColors.current : TripColors.visited,
        StopKind.end => TripColors.end,
      };

  IconData? _stopIcon(RouteStop s) =>
      s.kind == StopKind.start ? Icons.flag_rounded : null;

  void _showStop(RouteStop s, Color color) {
    final idx = _stops.indexOf(s);
    final dists = _stopDistancesKm();
    final km = idx >= 0 && idx < dists.length ? dists[idx] : 0.0;
    final after = idx == _stops.length - 1
        ? kmAfterLastStop(_stops, _distanceLine, _trackSegments)
        : 0.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
         child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 34,
                  height: 46,
                  child: _Pin(
                      color: color, label: s.label, icon: _stopIcon(s))),
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
                    const SizedBox(height: 12),
                    _legList(idx, dists, km),
                    if (after >= 0.05) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+${after.toStringAsFixed(2)} km travelled after this '
                        'stop · total ${(km + after).toStringAsFixed(2)} km',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: FutureBuilder<String>(
                            future: _addressFor(s.point),
                            builder: (context, snap) {
                              if (snap.connectionState !=
                                  ConnectionState.done) {
                                return Text('Fetching address…',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600));
                              }
                              return Text(
                                snap.data ?? 'Address unavailable',
                                style: const TextStyle(
                                    fontSize: 13, height: 1.35),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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
      ),
    );
  }

  /// Delivery-app style leg list: S → 1, 1 → 2, … up to the tapped pin.
  Widget _legList(int idx, List<double> dists, double km) {
    if (idx <= 0 || idx >= dists.length) {
      return _distanceBadge('Start point · 0.00 km');
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: Column(
        children: [
          for (var i = 1; i <= idx; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  _miniPin(_stops[i - 1]),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Colors.grey.shade500),
                  ),
                  _miniPin(_stops[i]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _stops[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(dists[i] - dists[i - 1]).toStringAsFixed(2)} km',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: Color(0xFFE3E8F0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                const Icon(Icons.straighten_rounded, size: 15, color: _blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _usesTrack ? 'Total from start' : 'Total from start (approx.)',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _blue),
                  ),
                ),
                Text(
                  '${km.toStringAsFixed(2)} km',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: _blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPin(RouteStop s) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration:
            BoxDecoration(color: _stopColor(s), shape: BoxShape.circle),
        child: _stopIcon(s) != null
            ? Icon(_stopIcon(s), size: 12, color: Colors.white)
            : Text(
                s.label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: s.label.length > 2 ? 8 : 11,
                    fontWeight: FontWeight.w800),
              ),
      );

  Widget _distanceBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.straighten_rounded, size: 14, color: _blue),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _blue)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────
// Pin widgets
// ─────────────────────────────────────────────

class _Pin extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;
  const _Pin({required this.color, required this.label, this.icon});

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
              child: icon != null
                  ? Icon(icon, size: 16, color: Colors.white)
                  : Text(
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
