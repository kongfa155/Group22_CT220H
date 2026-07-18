import 'package:latlong2/latlong.dart';

class OutageItem {
  final String? subareaName;
  final String? roadName;
  final String? powerCompany;
  final String areaText;
  final String? reason;
  final String? status;
  final String? startTime; // "HH:MM:SS"
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

  // "07:30:00" -> "07:30"
  String get timeRangeLabel {
    String trim(String? t) => t != null && t.length >= 5 ? t.substring(0, 5) : (t ?? '?');
    return '${trim(startTime)} - ${trim(endTime)}';
  }
}

class OutageWardGroup {
  final String boundaryId;
  final String wardName;
  final double lat;
  final double lng;
  final bool isApproximateLocation;
  final List<OutageItem> outages;

  OutageWardGroup({
    required this.boundaryId,
    required this.wardName,
    required this.lat,
    required this.lng,
    required this.isApproximateLocation,
    required this.outages,
  });

  factory OutageWardGroup.fromJson(Map<String, dynamic> json) {
    final outagesJson = json['outages'] as List;
    return OutageWardGroup(
      boundaryId: json['boundaryId'].toString(),
      wardName: json['wardName']?.toString() ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isApproximateLocation: json['isApproximateLocation'] as bool? ?? false,
      outages: outagesJson
          .map((o) => OutageItem.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}