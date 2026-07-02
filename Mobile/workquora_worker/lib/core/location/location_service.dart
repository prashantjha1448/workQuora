import 'package:geolocator/geolocator.dart';

class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
}

/// Thin wrapper so the rest of the app never touches the geolocator package
/// directly — keeps permission/error handling in exactly one place.
class LocationService {
  Future<({double lat, double lng})> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure('Location services are off. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationFailure('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure('Location permission permanently denied. Enable it in Settings.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    return (lat: position.latitude, lng: position.longitude);
  }
}
