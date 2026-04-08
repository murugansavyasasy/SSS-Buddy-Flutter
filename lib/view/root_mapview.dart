import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../auth/model/TodayVisitModal.dart';
import '../viewModel/today_visit_viewmodal.dart';

class TodayVisitMapScreen extends ConsumerStatefulWidget {
  final VoidCallback onEndDay;
  final LatLng startLocation;
  final LatLng endLocation;
  final String startLabel;
  final String endLabel;
  final String packageName;

  const TodayVisitMapScreen({
    super.key,
    required this.onEndDay,
    required this.startLocation,
    required this.endLocation,
    required this.startLabel,
    required this.endLabel,
    required this.packageName,
  });

  @override
  ConsumerState<TodayVisitMapScreen> createState() =>
      _TodayVisitMapScreenState();
}

class _TodayVisitMapScreenState extends ConsumerState<TodayVisitMapScreen> {
  late final MapController _mapController;
  bool _hasFittedBounds = false;

  static const Color _primaryBlue = Color(0xFF1A73E8);
  static const Color _darkNavy = Color(0xFF1A1F36);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(todayVisitProvider.notifier);
    final trip = ref.watch(todayVisitProvider).value;
    final livePoints = vm.trackedPoints;
    final hasPoints = livePoints.length >= 2;

    if (hasPoints && !_hasFittedBounds) {
      _hasFittedBounds = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds(livePoints);
      });
    }

    return Scaffold(
      backgroundColor: _darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(vm),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(vm),
                  if (trip == null) _buildLoadingOverlay(),
                  if (trip != null) _buildInfoCard(trip, vm),
                  _buildZoomControls(vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TodayVisitViewmodel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: _darkNavy,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Route Map",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4),
                ),
                Text(
                  "${widget.startLabel} → ${widget.endLabel}",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (vm.trackedPoints.isNotEmpty) {
                _hasFittedBounds = false;
                _fitBounds(vm.trackedPoints);
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: _primaryBlue, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(TodayVisitViewmodel vm) {
    final livePoints = vm.trackedPoints;
    final hasPoints = livePoints.length >= 2;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.startLocation,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
          'https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: widget.packageName,
        ),
        if (hasPoints)
          PolylineLayer(
            polylines: [
              Polyline(
                points: livePoints,
                strokeWidth: 10,
                color: Colors.black.withOpacity(0.15),
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),
        if (hasPoints)
          PolylineLayer(
            polylines: [
              Polyline(
                points: livePoints,
                strokeWidth: 6,
                color: _primaryBlue,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
                point: widget.startLocation,
                width: 48,
                height: 48,
                child: _StartMarker()),
            if (livePoints.isNotEmpty)
              Marker(
                  point: livePoints.last,
                  width: 48,
                  height: 64,
                  alignment: Alignment.bottomCenter,
                  child: _CurrentLocationMarker()),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _primaryBlue),
            SizedBox(height: 14),
            Text(
              "Fetching location…",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls(TodayVisitViewmodel vm) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _MapButton(
            icon: Icons.add,
            onTap: () {
              double zoom = _mapController.camera.zoom;
              zoom = (zoom + 0.5).clamp(1.0, 18.0); // smooth increment, clamp to map limits
              _mapController.move(_mapController.camera.center, zoom);
            },
          ),
          const SizedBox(height: 4),
          _MapButton(
            icon: Icons.remove,
            onTap: () {
              double zoom = _mapController.camera.zoom;
              zoom = (zoom - 0.5).clamp(1.0, 18.0);
              _mapController.move(_mapController.camera.center, zoom);
            },
          ),
          const SizedBox(height: 4),
          _MapButton(
            icon: Icons.my_location_rounded,
            onTap: () {
              if (vm.trackedPoints.isNotEmpty) {
                _mapController.move(vm.trackedPoints.last, 15); // optional: smooth zoom
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(TripState trip, TodayVisitViewmodel vm) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.startLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                  width: 2,
                  height: 16,
                  color: const Color(0xFFE0E0E0),
                  margin: const EdgeInsets.symmetric(vertical: 3)),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.endLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36)),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF0F1F5)),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.straighten_rounded,
                  label:
                  "${trip.distance.toStringAsFixed(1)} km",
                  color: _primaryBlue,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.place_rounded,
                  label: "${vm.trackedPoints.length} pts",
                  color: const Color(0xFF22C55E),
                ),
                const Spacer(),
                SizedBox(
                  width: 130,
                  child: _buildEndDayButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDayButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.stop_circle_outlined, size: 20),
        label: const Text(
          "END DAY",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          widget.onEndDay();
          Navigator.pop(context, true);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _StartMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1A73E8), width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: const Center(
        child: Icon(Icons.navigation_rounded,
            color: Color(0xFF1A73E8), size: 14),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF1A73E8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x441A73E8),
                  blurRadius: 12,
                  spreadRadius: 4,
                  offset: Offset(0, 2))
            ],
          ),
          child: const Icon(Icons.person_pin_rounded,
              color: Colors.white, size: 18),
        ),
        CustomPaint(
          size: const Size(14, 14),
          painter: _PinTailPainter(color: const Color(0xFF1A73E8)),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1A1F36)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}