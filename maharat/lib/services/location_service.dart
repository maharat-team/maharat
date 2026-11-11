import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/l10n/l10n.dart';

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

/// The device's current position, asking for permission when needed.
class LocationService {
  Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException(
        tr(
          'Turn on location (GPS) and try again.',
          'لوکیشن (جی پی ایس) آن کریں اور دوبارہ کوشش کریں۔',
        ),
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationException(
        tr(
          'Location permission is off. You can place the pin on the map yourself.',
          'لوکیشن کی اجازت بند ہے۔ آپ نقشے پر خود پن لگا سکتے ہیں۔',
        ),
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }
}
