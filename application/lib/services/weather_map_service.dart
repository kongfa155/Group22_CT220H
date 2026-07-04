import 'package:application/apiWeather.dart';
import 'package:weather/weather.dart';


enum WeatherLayer {
  clouds,
  rain,
  temperature,
  wind,
  pressure,
}
class WeatherMapService {
final String apiKey;

WeatherMapService(this.apiKey);

String getTileUrl(WeatherLayer layer) {
  String layerName;

  switch (layer) {
    case WeatherLayer.clouds:
      layerName = "clouds_new";
      break;

    case WeatherLayer.rain:
      layerName = "precipitation_new";
      break;

    case WeatherLayer.temperature:
      layerName = "temp_new";
      break;

    case WeatherLayer.wind:
      layerName = "wind_new";
      break;

    case WeatherLayer.pressure:
      layerName = "pressure_new";
      break;
  }

  return "https://tile.openweathermap.org/map/$layerName/{z}/{x}/{y}.png?appid=$apiKey";
}
}