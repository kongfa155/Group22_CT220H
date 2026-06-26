import 'package:geolocator/geolocator.dart';
class LocationService {
  Future<Position> getCurrentLocation() async {
    bool kichHoatDichVu = await Geolocator.isLocationServiceEnabled();
    if(!kichHoatDichVu) {
      throw Exception("GPS dang tat");
    }
    LocationPermission permission = await Geolocator.checkPermission(); //yeu cau quyen truy cap GPS
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Không được cấp quyền vị trí");
    }
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
        //Chu y cho nay, giai thich: Thoi tiet xem theo vung nen ko can vtri chinh xac
      ),
    );
    return position;
}
}