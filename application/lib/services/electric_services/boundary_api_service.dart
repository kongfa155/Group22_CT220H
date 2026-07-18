import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/BoundaryFeature.dart';

class BoundaryApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/boundaries';

  static Future<List<BoundaryFeature>> getAllBoundaries() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load boundaries');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List;

    return features
        .map((f) => BoundaryFeature.fromGeoJson(f as Map<String, dynamic>))
        .toList();
  }
}