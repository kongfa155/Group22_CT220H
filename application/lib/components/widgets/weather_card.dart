import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'dart:ui';
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
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 2,
                sigmaY: 2,
              ),

              child: Container(
                width: 350,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.39), // trong suốt
                  borderRadius: BorderRadiusGeometry.circular(20),
                  // boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 10.0,blurStyle: BlurStyle.solid)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${weather.areaName}",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Image.network(
                      "https://openweathermap.org/img/wn/${weather.weatherIcon}@2x.png",
                      width: 100,
                    ),
                    Text(
                      "${weather.temperature?.celsius?.round()}°C",
                      style: TextStyle(fontSize: 60, color: Colors.white),
                    ),
                    Text(
                      "${weather.weatherDescription ?? ""}",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
