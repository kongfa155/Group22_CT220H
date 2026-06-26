import 'dart:async';
import 'dart:io';
import 'package:application/models/ElectricItem.dart';
import 'package:application/services/geocoding_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;

//Web trả về nhiều cái /r dư nên xài này để xóa bớt
String cleanText(String text) {
  return text
      .replaceAll('\r', '')
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .join('\n');
}

class ElectricScrapperService {
  Future<List<ElectricItem>> getElectricData() async {
    final url = Uri.parse('https://lichcupdien.org/lich-cup-dien-can-tho');
    //Gọi HTTP Get tới trang lichcupdien
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load page');
    }
    //Convert dữ liệu trả về thành dạng Document
    dom.Document html = dom.Document.html(response.body);

    //Lấy dữ liệu trong thẻ mình cần
    final items = html.querySelectorAll('.item_content_lcd_wrapper');
    // mẫu trả về
    // items = [
    // <div class="item_content_lcd_wrapper">CTY 1</div>,
    // <div class="item_content_lcd_wrapper">22/06</div>,
    // <div class="item_content_lcd_wrapper">08:00-12:00</div>,
    // <div class="item_content_lcd_wrapper">Khu vực A</div>,
    // <div class="item_content_lcd_wrapper">Bảo trì</div>,
    // <div class="item_content_lcd_wrapper">Đã duyệt</div>,
    // ]

    //Lọc ra lấy đúng text content
    final rawData = items
        .map((e) => cleanText(e.text))
        .where((e) => e.isNotEmpty)
        .toList();
    // rawData = [
    //   "CTY 1",
    //   "22/06",
    //   "08:00-12:00",
    //   "Khu vực A",
    //   "Bảo trì",
    //   "Đã duyệt",
    //
    //   "CTY 2",
    //   "23/06",
    //   "09:00-11:00",
    //   "Khu vực B",
    //   "Nâng cấp",
    //   "Đã duyệt"
    // ]
    final result = <ElectricItem>[];
    // Mặc định tọa độ trung tâm Bến Ninh Kiều, Cần Thơ nếu không tìm thấy gì cả
    double defaultLat = 10.0342;
    double defaultLng = 105.7862;
    //Gom 6 dòng lại thành 1 đối tượng Electric Item
    for (int i = 0; i + 5 < rawData.length; i += 6) {
      // 1. Tạo object tạm từ mảng text 6 phần tử cào được
      final rawItem = ElectricItem.fromList(rawData.sublist(i, i + 6));
      print("Đang chuyển đổi sang toạ độ\n");
      // 2. Gọi file Geocoding service vừa tách ở trên để lấy tọa độ
      final coordinates = await GeocodingService.getCoordinates(rawItem.area);
      print("Chuyển đổi thành công coordinates: $coordinates\n");



      // Phân tích tên công ty điện lực để tìm tọa độ Quận/Huyện fallback phù hợp
      final company = rawItem.powerCompany.toLowerCase();
      if (company.contains("cái răng")) {
        defaultLat = 10.0059; defaultLng = 105.7471; // Trung tâm Cái Răng
      } else if (company.contains("bình thủy")) {
        defaultLat = 10.0717; defaultLng = 105.7288; // Trung tâm Bình Thủy
      } else if (company.contains("ô môn")) {
        defaultLat = 10.1192; defaultLng = 105.6269; // Trung tâm Ô Môn
      } else if (company.contains("thốt nốt")) {
        defaultLat = 10.2692; defaultLng = 105.5297; // Trung tâm Thốt Nốt
      } else if (company.contains("phong điền")) {
        defaultLat = 9.9984; defaultLng = 105.6706;  // Trung tâm Phong Điền
      } else if (company.contains("thới lai")) {
        defaultLat = 10.1065; defaultLng = 105.5414; // Trung tâm Thới Lai
      } else if (company.contains("cờ đỏ")) {
        defaultLat = 10.1306; defaultLng = 105.4286;  // Trung tâm Cờ Đỏ
      } else if (company.contains("vĩnh thạnh")) {
        defaultLat = 10.2241; defaultLng = 105.3725; // Trung tâm Vĩnh Thạnh
      }




      // 3. Khởi tạo Object ElectricItem đầy đủ cả thông tin gốc lẫn tọa độ
      final fullItem = ElectricItem(
        powerCompany: rawItem.powerCompany,
        date: rawItem.date,
        time: rawItem.time,
        area: rawItem.area,
        reason: rawItem.reason,
        status: rawItem.status,
        lat: coordinates?['lat'] ?? defaultLat, // Nếu coordinates null, lat sẽ là null
        lng: coordinates?['lng'] ?? defaultLng, // Nếu coordinates null, lng sẽ là null
      );
      print("$fullItem");
      result.add(fullItem);

      // Lưu ý quan trọng: Tần suất gọi API Nominatim miễn phí tối đa là 1 request / giây.
      // Bạn nên delay nhẹ một chút trong vòng lặp để tránh bị chặn IP (HTTP 423/429).
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    return result;
  }
}
