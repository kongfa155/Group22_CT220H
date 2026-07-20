import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/OutageItem.dart';

class OutageMapResult {
  final List<OutagePointGroup> points;
  final List<OutageRoadSegment> roads;

  OutageMapResult({required this.points, required this.roads});
}

class OutageMapApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/outages';

  static Future<OutageMapResult> getOutagesByWard({String? date }) async {
    date ??=  '2026-07-17';
    final uri = Uri.parse('$baseUrl/by-ward').replace(
      queryParameters: date != null ? {'date': date} : null,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load outages');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pointsJson = data['points'] as List? ?? [];
    final roadsJson = data['roads'] as List? ?? [];

    return OutageMapResult(
      points: pointsJson.map((p) => OutagePointGroup.fromJson(p as Map<String, dynamic>)).toList(),
      roads: roadsJson.map((r) => OutageRoadSegment.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}