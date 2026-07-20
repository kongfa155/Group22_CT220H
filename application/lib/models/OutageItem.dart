import 'package:latlong2/latlong.dart';

class OutageItem {
  final String? subareaName;
  final String? roadName;
  final String? powerCompany;
  final String areaText;
  final String? reason;
  final String? status;
  final String? startTime;
  final String? endTime;

  OutageItem({
    this.subareaName,
    this.roadName,
    this.powerCompany,
    required this.areaText,
    this.reason,
    this.status,
    this.startTime,
    this.endTime,
  });

  factory OutageItem.fromJson(Map<String, dynamic> json) {
    return OutageItem(
      subareaName: json['subareaName'] as String?,
      roadName: json['roadName'] as String?,
      powerCompany: json['powerCompany'] as String?,
      areaText: json['areaText']?.toString() ?? '',
      reason: json['reason'] as String?,
      status: json['status'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );
  }

  String get timeRangeLabel {
    String trim(String? t) => t != null && t.length >= 5 ? t.substring(0, 5) : (t ?? '?');
    return '${trim(startTime)} - ${trim(endTime)}';
  }
}

// Marker chấm tròn (ward centroid, district centroid, hoặc điểm cụ thể)
class OutagePointGroup {
  final String label;
  final double lat;
  final double lng;
  final String precision; // "point" | "ward" | "district"
  final List<OutageItem> outages;

  OutagePointGroup({
    required this.label,
    required this.lat,
    required this.lng,
    required this.precision,
    required this.outages,
  });

  factory OutagePointGroup.fromJson(Map<String, dynamic> json) {
    final outagesJson = json['outages'] as List;
    return OutagePointGroup(
      label: json['label']?.toString() ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      precision: json['precision']?.toString() ?? 'ward',
      outages: outagesJson.map((o) => OutageItem.fromJson(o as Map<String, dynamic>)).toList(),
    );
  }
}

// Đoạn đường có cúp điện, vẽ bằng polyline
class OutageRoadSegment {
  final String label;
  final String color; // "yellow" | "orange"
  final List<LatLng> points;
  final OutageItem outage;

  OutageRoadSegment({
    required this.label,
    required this.color,
    required this.points,
    required this.outage,
  });

  factory OutageRoadSegment.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final type = geometry['type'] as String;
    final coords = geometry['coordinates'] as List;

    List<LatLng> points = [];
    if (type == 'LineString') {
      points = (coords).map((p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble())).toList();
    } else if (type == 'MultiLineString') {
      // Gộp các đoạn con lại vẽ liền (đơn giản hoá - đủ dùng cho hiển thị)
      for (final line in coords) {
        points.addAll((line as List).map((p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble())));
      }
    }

    return OutageRoadSegment(
      label: json['label']?.toString() ?? '',
      color: json['color']?.toString() ?? 'yellow',
      points: points,
      outage: OutageItem.fromJson(json['outage'] as Map<String, dynamic>),
    );
  }
}