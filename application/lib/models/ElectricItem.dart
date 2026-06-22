import 'package:flutter/material.dart';

class ElectricItem {
  final String powerCompany;
  final String date;
  final String time;
  final String area;
  final String reason;
  final String status;
  //Constructor
  ElectricItem({
    required this.powerCompany,
    required this.date,
    required this.time,
    required this.area,
    required this.reason,
    required this.status,
  });
  //Tạo đối tượng t một mảng data truyền vào
  // Ví dụ một mảng mình truyền từ service [
  // "Điện lực Ninh Kiều",
  // "22/06/2026",
  // "08:00-12:00",
  // "An Khánh",
  // "Bảo trì",
  // "Đã duyệt"
  // ]
  factory ElectricItem.fromList(List<String> values) {
    if (values.length != 6) {
      throw Exception(
        'ElectricItem requires exactly 6 values, got ${values.length}',
      );
    }

    return ElectricItem(
      powerCompany: values[0],
      date: values[1],
      time: values[2],
      area: values[3],
      reason: values[4],
      status: values[5],
    );
  }

  //Hàm toString để in đẹp hơn
  @override
  String toString() {
    return '''
      Điện lực: $powerCompany
      Ngày: $date
      Thời gian: $time
      Khu vực: $area
      Lý do: $reason
      Trạng thái: $status
      ''';
  }
}
