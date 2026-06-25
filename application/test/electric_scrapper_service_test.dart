import 'package:flutter_test/flutter_test.dart';
import 'package:application/services/electric_scrapper_service.dart';

void main() {
  test('Get electric data', () async {
    final service = ElectricScrapperService();
  //Gọi hàm lấy lịch cúp điện
    final result = await service.getElectricData();

    print('Tong so luong data: ${result.length}');

    print('\n=== 3 dong dau tien ===');
    for (final item in result.take(3)) {
      print(item);
    }

    expect(result, isNotEmpty);
  });
}