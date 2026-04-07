import 'package:latlong2/latlong.dart';
class RouteModel {
  final double distance;
  final double duration;
  final List<LatLng> points;

  RouteModel({
    required this.distance,
    required this.duration,
    required this.points,
  });
}