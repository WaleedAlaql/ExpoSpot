import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Expo Dubai reference venue (Earth Plaza) — default map viewport for testing.
abstract final class ExpoDubaiVenue {
  static const earthPlaza = LatLng(24.957803, 55.1562148);

  static const center = earthPlaza;

  /// Pedestrian network footprint (component 1) — keeps evaluators inside the site.
  static final bounds = LatLngBounds(
    const LatLng(24.9475, 55.1335),
    const LatLng(24.9735, 55.1725),
  );

  static const initialZoom = 16.0;
  static const minZoom = 14.5;
  static const maxZoom = 19.0;
}
