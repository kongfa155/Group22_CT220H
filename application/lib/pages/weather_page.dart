import 'dart:ui';
import 'package:application/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:application/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../components/widgets/weather_card.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService _weatherService = WeatherService();  //goi dich vu thoi tiet
  final LocationService _locationService = LocationService();
  @override
  void initState() {
    super.initState();
    getInfomationWeather(); //ham lay thong tin du lieu
  }
void getInfomationWeather() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      print("Kinh do: ${position.longitude}");
      print("Vi do: ${position.latitude}");
      Weather? weather = await _weatherService.getWeather(
          position.latitude,
          position.longitude
      );
      //Cap nhat state weather
      setState(() {
        _weather = weather;
      });
    } catch (error){
      print("Loi ham loadWeather $error");
    }
}
  Weather? _weather; // doi tuong de luu thoi tiet

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MyPageWeatherForecast());
  }

  Widget MyPageWeatherForecast() {
    if (_weather == null) {
      //Neu ma chua co data thi hien thi vong tron loading
      // _weather.
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
      child:  WeatherCard(
        weather: _weather!, //truyen tham so weather
      ),
    );
  }
}
