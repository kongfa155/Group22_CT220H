import 'package:weather/weather.dart';
import 'package:application/apiWeather.dart';

class WeatherForecast {
  final WeatherFactory _apiW = WeatherFactory(WEATHER_API_KEY);
  Future<List<Weather>?> getForeCast(double latitude, double longitude) async {

    try {
      List<Weather> data = await _apiW.fiveDayForecastByLocation(latitude, longitude);
      print("Lay du lieu du bao thoi tiet thanh cong");
      return data;
    } catch (error) {
      print("Loi ham getForeCast: $error");
    }
  }
}
