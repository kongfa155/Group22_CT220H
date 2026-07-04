import 'package:application/services/weather_forecast.dart';
import 'package:application/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:application/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
// import '../components/logicBackground.dart';
import '../components/widgets/forecast_list_card.dart';
import '../components/widgets/weather_card.dart';
import '../components/widgets/weather_map_card.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService _weatherService =
      WeatherService(); //goi dich vu thoi tiet
  final LocationService _locationService = LocationService();
  final WeatherForecast _weatherForecast = WeatherForecast();
  // final WeatherMapService _mapService = WeatherMapService();
  @override
  void initState() {
    super.initState();
    getInfomationWeather(); //ham lay thong tin du lieu
  }

  void getInfomationWeather() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      Weather? weather = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );
      List<Weather>? forecast = await _weatherForecast.getForeCast(
        position.latitude,
        position.longitude,
      );
      //Cap nhat state weather
      setState(() {
        _weather = weather;
        _forecast = forecast;
      });
    } catch (error) {
      print("Loi ham loadWeather $error");
    }
  }

  Weather? _weather; // doi tuong de luu thoi tiet
  List<Weather>? _forecast; //doi tuong luu danh sach cac du bao trong 5 ngay
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dự báo thời tiết"),
        centerTitle: true,
      ),
      body: MyPageWeatherForecast(), 
      extendBody: true,);
  }

  Widget MyPageWeatherForecast() {
    if (_weather == null || _forecast == null) {
      //Neu ma chua co data thi hien thi vong tron loading
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Đang tải dữ liệu..."),
          ],
        ),
      );
    }
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      width: MediaQuery.sizeOf(context).width,
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
          decoration: BoxDecoration(
          //   image: DecorationImage(
          //
          //     image: AssetImage(
          //       getBackground(_weather!.weatherMain ?? "clear"),
          //     ),
          //     fit: BoxFit.cover,
          //   ),
            color: Color(0xFFFFF6F6)
          ),
        child: ListView(
          // padding: const EdgeInsets.only(top: 50, bottom: 30),
          padding: const EdgeInsets.only(bottom: 30),
            children: [
              WeatherCard(
                weather: _weather!, //truyen tham so weather
              ),
              ForecastListCard(
                forecast:
                    _forecast!, //Them dau cham than de bao chac chan khong null
              ),
              WeatherMapCard(),
            ],
        ),
      ),
    );
  }
}
