import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'dart:ui';

class ForecastListCard extends StatelessWidget {
  final List<Weather> forecast;

  const ForecastListCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, //keo ngang
        itemCount: forecast.length,
        itemBuilder: (context, index) {
          Weather weather = forecast[index];
          return Container(
            width: 110,
            margin: EdgeInsets.fromLTRB(2, 10, 2, 0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${weather.date?.day}/${weather.date?.month}",
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  "${weather.date?.hour}:00",
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Image.network(
                  "https://openweathermap.org/img/wn/${weather.weatherIcon}@2x.png",
                  width: 50,
                ),
                const SizedBox(height: 10),
                Text(
                  "${weather.temperature?.celsius?.round()}°",

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 20,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
