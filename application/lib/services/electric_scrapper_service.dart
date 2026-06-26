import 'dart:async';
import 'dart:io';
import 'package:application/models/ElectricItem.dart';
import 'package:application/services/outage_api_service.dart';
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
    //Gom 6 dòng lại thành 1 đối tượng Electric Item
    for (int i = 0; i + 5 < rawData.length; i += 6) {
      // 1. Tạo object tạm từ mảng text 6 phần tử cào được
      final rawItem = ElectricItem.fromList(rawData.sublist(i, i + 6));

      result.add(rawItem);
      await OutageApiService
          .saveRawOutage(rawItem);
    }


    return result;
  }
}
