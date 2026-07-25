import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/OutageItem.dart';

class OutageMapResult {
  final List<OutagePointGroup> wardSummaries;
  final List<OutageAreaFeature> roadAreas;
  final List<OutageAreaFeature> placeAreas;
  final List<OutagePointGroup> points;

  OutageMapResult({
    required this.wardSummaries,
    required this.roadAreas,
    required this.placeAreas,
    required this.points,
  });
}

class OutageMapApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/outages';

  static Future<OutageMapResult> getOutagesByWard({String? date}) async {
    final uri = Uri.parse('$baseUrl/by-ward').replace(
      queryParameters: date != null ? {'date': date} : null,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load outages');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = data[key] as List? ?? [];
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    return OutageMapResult(
      wardSummaries: parseList('wardSummaries', OutagePointGroup.fromJson),
      roadAreas: parseList('roadAreas', OutageAreaFeature.fromJson),
      placeAreas: parseList('placeAreas', OutageAreaFeature.fromJson),
      points: parseList('points', OutagePointGroup.fromJson),
    );
  }
}