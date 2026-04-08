import 'package:latlong2/latlong.dart';
class RouteModel {
  final bool isTripStarted;
  final double distance;
  final int duration;
  final List<LatLng> points;

  RouteModel({
    required this.isTripStarted,
    required this.distance,
    required this.duration,
    required this.points,
  });

  RouteModel copyWith({bool? isTripStarted, double? distance, int? duration, List<LatLng>? points}) {
    return RouteModel(
      isTripStarted: isTripStarted ?? this.isTripStarted,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      points: points ?? this.points,
    );
  }
}