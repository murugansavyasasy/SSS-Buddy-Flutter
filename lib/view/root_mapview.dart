import 'dart:math' as Math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../auth/model/TodayVisitModal.dart';
import '../viewModel/today_visit_viewmodal.dart';

const LatLng kStart = LatLng(13.0827, 80.2707);
const LatLng kEnd = LatLng(13.0674, 80.2209);

class TodayVisitMapScreen extends ConsumerStatefulWidget {
  final VoidCallback onEndDay;

  const TodayVisitMapScreen({
    super.key,
    required this.onEndDay,
  });

  @override
  ConsumerState<TodayVisitMapScreen> createState() =>
      _TodayVisitMapScreenState();
}

class _TodayVisitMapScreenState extends ConsumerState<TodayVisitMapScreen> {
  late final MapController _mapController;

  static const Color _primaryBlue = Color(0xFF1A73E8);
  static const Color _darkNavy = Color(0xFF1A1F36);
  static const Color _surface = Color(0xFFF8F9FF);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(todayVisitProvider.notifier)
          .getRoute(start: kStart, end: kEnd);
    });
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
    final routeAsync = ref.watch(todayVisitProvider);

    return Scaffold(
      backgroundColor: _darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(routeAsync),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(routeAsync),
                  if (routeAsync.isLoading) _buildLoadingOverlay(),
                  if (routeAsync.hasError) _buildErrorBanner(routeAsync.error),
                  _buildZoomControls(),
                  if (routeAsync.hasValue && routeAsync.value != null)
                    _buildInfoCard(routeAsync.value!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(AsyncValue<RouteModel?> routeAsync) {
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
                const Text("Route Map",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
                Text(
                  routeAsync.hasValue && routeAsync.value != null
                      ? "Chennai Central → Anna Nagar"
                      : "Fetching route...",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref
                .read(todayVisitProvider.notifier)
                .getRoute(start: kStart, end: kEnd),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: _primaryBlue, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(AsyncValue<RouteModel?> routeAsync) {
    final route = routeAsync.when(
      data: (d) => d,
      loading: () => null,
      error: (_, __) => null,
    );
    final hasRoute = route != null && route.points.isNotEmpty;

    if (hasRoute) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fitBounds(route.points));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: kStart,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
          'https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.app',
        ),

        if (hasRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.points,
                strokeWidth: 10,
                color: Colors.black.withOpacity(0.18),
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        if (hasRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.points,
                strokeWidth: 6,
                color: _primaryBlue,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            // Start marker (blue circle like Google Maps)
            Marker(
              point: kStart,
              width: 48,
              height: 48,
              child: _StartMarker(),
            ),

            // End marker (red pin)
            Marker(
              point: kEnd,
              width: 48,
              height: 64,
              alignment: Alignment.bottomCenter,
              child: _EndMarker(),
            ),

            // Midpoint annotation
            if (hasRoute && route.points.length > 2)
              Marker(
                point: route.points[route.points.length ~/ 2],
                width: 130,
                height: 40,
                child: _RouteAnnotation(
                  label:
                  "${route.distance.toStringAsFixed(1)} km · ${route.duration.toStringAsFixed(0)} min",
                ),
              ),
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
            Text("Fetching route…",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(Object? error) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error?.toString() ?? "Something went wrong",
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _MapButton(
            icon: Icons.add,
            onTap: () {
              final zoom = _mapController.camera.zoom;
              _mapController.move(
                  _mapController.camera.center, zoom + 1);
            },
          ),
          const SizedBox(height: 4),
          _MapButton(
            icon: Icons.remove,
            onTap: () {
              final zoom = _mapController.camera.zoom;
              _mapController.move(
                  _mapController.camera.center, zoom - 1);
            },
          ),
          const SizedBox(height: 4),
          _MapButton(
            icon: Icons.my_location_rounded,
            onTap: () => ref
                .read(todayVisitProvider.notifier)
                .getRoute(start: kStart, end: kEnd),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(RouteModel route) {
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
            // Route title row
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
                const Expanded(
                  child: Text(
                    "Chennai Central",
                    style: TextStyle(
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
                const Expanded(
                  child: Text(
                    "Anna Nagar",
                    style: TextStyle(
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
                  label: "${route.distance.toStringAsFixed(1)} km",
                  color: _primaryBlue,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: "${route.duration.toStringAsFixed(0)} min",
                  color: const Color(0xFF22C55E),
                ),
                const Spacer(),
                // ✅ END DAY BUTTON
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
          foregroundColor: Color(0xFFEF4444),
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
            Navigator.pop(context, true);
        },
      ),
    );
  }
}


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

class _EndMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x33EF4444),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 3))
            ],
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
        ),
        CustomPaint(
          size: const Size(14, 14),
          painter: _PinTailPainter(color: const Color(0xFFEF4444)),
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

class _RouteAnnotation extends StatelessWidget {
  final String label;
  const _RouteAnnotation({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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