import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// The service area. Maps open here and pins must stay inside it.
class Bahawalpur {
  Bahawalpur._();

  static final center = LatLng(29.3956, 71.6836);

  /// The city with its suburbs. Matches the limits the database enforces,
  /// which are slightly wider.
  static const south = 29.25;
  static const north = 29.55;
  static const west = 71.50;
  static const east = 71.85;

  static bool contains(LatLng point) =>
      point.latitude >= south &&
      point.latitude <= north &&
      point.longitude >= west &&
      point.longitude <= east;
}

/// Straight-line distance in kilometres.
double distanceKm(LatLng a, LatLng b) {
  const earthRadiusKm = 6371.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(h)));
}

/// Distance when both points are known, otherwise null.
double? distanceBetween(LatLng? a, LatLng? b) =>
    a == null || b == null ? null : distanceKm(a, b);

LatLng? latLngOrNull(Object? lat, Object? lng) {
  if (lat is! num || lng is! num) return null;
  return LatLng(lat.toDouble(), lng.toDouble());
}
