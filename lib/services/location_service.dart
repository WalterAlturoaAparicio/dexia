import 'package:geolocator/geolocator.dart';

/// RF05 – Georreferenciación automática al guardar un avistamiento.
/// RNF03 – GPS en modo High Accuracy solo cuando se necesita, para
///          preservar batería durante jornadas de campo.
class LocationService {
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();
  static LocationService get instance => _instance;

  /// Solicita permisos y obtiene la posición actual.
  /// Lanza [LocationException] si no es posible obtenerla.
  Future<Position> getCurrentPosition() async {
    // 1. Verificar que el servicio de ubicación esté activo
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
          'El servicio de ubicación está desactivado. '
          'Actívalo en los ajustes del dispositivo.');
    }

    // 2. Verificar / solicitar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Permiso de ubicación denegado.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
          'Permiso de ubicación denegado permanentemente. '
          'Habilítalo en los ajustes de la aplicación.');
    }

    // 3. Obtener posición – High Accuracy solo en este momento puntual
    //    para no mantener el GPS encendido continuamente (RNF03).
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Versión silenciosa: devuelve null en vez de lanzar excepción.
  /// Útil cuando la ubicación es opcional (e.g. modo offline sin GPS).
  Future<Position?> tryGetPosition() async {
    try {
      return await getCurrentPosition();
    } catch (_) {
      return null;
    }
  }
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}
