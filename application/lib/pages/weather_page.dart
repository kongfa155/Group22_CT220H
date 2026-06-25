import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:application/apiWeather.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherFactory _apiW = WeatherFactory(WEATHER_API_KEY);
  final String location = "";

  @override
  void initState() {
    super.initState();
    _apiW
        .currentWeatherByCityName("Can Tho, VN")
        .then((weather) {
          print("Nhan data thanh cong");
          print(weather.weatherIcon);
          setState(() {
            _weather = weather;
          });
        })
        .catchError((error) {
          print("LOI API: $error");
        });
  }

  Weather? _weather; // doi tuong de luu thoi tiet

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MyPageWeatherForecast());
  }

  Widget MyPageWeatherForecast() {
    if (_weather == null) {
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
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Glass Effect",
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
