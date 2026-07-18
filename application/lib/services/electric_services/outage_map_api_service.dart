import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/OutageItem.dart';

class OutageMapApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/outages';

  // date dạng "yyyy-MM-dd", mặc định hôm nay nếu không truyền
  static Future<List<OutageWardGroup>> getOutagesByWard({String? date}) async {
    final uri = Uri.parse('$baseUrl/by-ward').replace(
      queryParameters: date != null ? {'date': date} : null,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load outages by ward');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final wards = data['wards'] as List;

    return wards
        .map((w) => OutageWardGroup.fromJson(w as Map<String, dynamic>))
        .toList();
  }
}