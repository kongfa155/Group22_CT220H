import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {

  /// Hàm làm sạch chuỗi địa chỉ để API dễ tìm kiếm hơn
  static String _cleanAddress(String area) {
    String cleaned = area.toLowerCase();

    // 1. Thay thế các cụm từ thừa thường gặp (xử lý thủ công thay cho \b)
    final wordsToRemove = [
      'toàn bộ', 'khu vực', 'kv', 'phường', 'p.', 'quận', 'q.',
      'tpct', 'tp cần thơ', 'thành phố cần thơ', 'cần thơ', 'lộ nông thôn'
    ];

    for (var word in wordsToRemove) {
      cleaned = cleaned.replaceAll(word, '');
    }

    // 2. Thay thế dấu gạch ngang và các ký tự đặc biệt thành khoảng trắng
    cleaned = cleaned.replaceAll(RegExp(r'[-–,_]'), ' ');

    // 3. Dọn dẹp khoảng trắng thừa
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }





  /// Hàm chuyển đổi tên khu vực thành tọa độ Lat/Lng sử dụng OpenStreetMap Nominatim
  static Future<Map<String, double>?> getCoordinates(String area) async {
    // Gọi hàm lọc sạch địa chỉ trước
    final cleanArea = _cleanAddress(area);
    print("Clean area: $cleanArea\n");
    // Luôn cộng thêm "Cần Thơ, Việt Nam" để giới hạn phạm vi tìm kiếm chính xác
    final searchQuery = "$cleanArea, Cần Thơ, Việt Nam";
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=1'
    );

    try {
      // Nominatim yêu cầu bắt buộc phải có User-Agent hợp lệ trong Header
      final response = await http.get(url, headers: {
        'User-Agent': 'Flutter_Electric_Map_App_Project',
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat']),
            'lng': double.parse(data[0]['lon']),
          };
        }
      }
    } catch (e) {
      print('⚠️ Lỗi Geocoding cho khu vực [$area]: $e');
    }

    // Trả về null nếu không tìm thấy hoặc lỗi để app xử lý fallback (bỏ qua hoặc chấm đại diện)
    return null;
  }
}