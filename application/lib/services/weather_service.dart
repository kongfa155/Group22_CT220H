  import 'package:weather/weather.dart';
  import 'package:application/apiWeather.dart';

  class WeatherService {
    final WeatherFactory _apiW = WeatherFactory(WEATHER_API_KEY);
    Future<Weather?> getWeather(double latitude, double longitude) async{ //boi vi Future ko cho tra ve null nen "Weather?"
      try {
          return await _apiW.currentWeatherByLocation(latitude, longitude);
      } catch (error) {
        print("Co loi khi goi API: $error");  //auto tra ve null
      }
    }

  }
