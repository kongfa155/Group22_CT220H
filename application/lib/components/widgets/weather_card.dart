import 'package:flutter/material.dart';
import 'package:weather/weather.dart';

import '../logicBackground.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            getBackground(weather.weatherMain ?? "clear"),
          ),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(30), // bo goc
        color: Colors.red.withValues(
          alpha: 0.2,
        ), // mau thuy trang thuy tinh trong suot
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${weather.areaName}",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          Image.network(
            "https://openweathermap.org/img/wn/${weather.weatherIcon}@2x.png",
            width: 100,
          ),
          Text(
            "${weather.temperature?.celsius?.round()}°C",
            style: TextStyle(fontSize: 60, color: Colors.black),
          ),
          Text(
            "${weather.weatherDescription ?? ""}",
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
