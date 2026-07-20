import 'package:latlong2/latlong.dart';

class BoundaryFeature {
  final String name;
  final String boundaryType;
  final List<List<LatLng>> polygons;

  BoundaryFeature({
    required this.name,
    required this.boundaryType,
    required this.polygons,
  });

  factory BoundaryFeature.fromGeoJson(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final type = geometry['type'] as String;
    final coords = geometry['coordinates'] as List;

    List<List<LatLng>> polygons = [];

    if (type == 'Polygon') {
      polygons = [_ringToLatLng(coords[0] as List)];
    } else if (type == 'MultiPolygon') {
      polygons = (coords)
          .map((polygon) => _ringToLatLng((polygon as List)[0] as List))
          .toList();
    }

    return BoundaryFeature(
      name: props['name']?.toString() ?? '',
      boundaryType: props['boundaryType']?.toString() ?? '',
      polygons: polygons,
    );
  }

  static List<LatLng> _ringToLatLng(List ring) {
    return ring
        .map((point) => LatLng(
      (point[1] as num).toDouble(),
      (point[0] as num).toDouble(),
    ))
        .toList();
  }
}