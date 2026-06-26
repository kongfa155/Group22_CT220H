import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ElectricItem.dart';

class OutageApiService {
  static const String baseUrl =
      'http://10.0.2.2:3000/api/outages';

  static Future<void> saveRawOutage(
      ElectricItem item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/raw'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(item.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Save raw outage failed');
    }
  }
}