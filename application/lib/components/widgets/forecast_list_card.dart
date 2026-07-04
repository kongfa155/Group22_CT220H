import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

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
            width: 82,
            margin: EdgeInsets.fromLTRB(5, 10, 2, 0),
            decoration: BoxDecoration(
              color: Color.fromRGBO(61, 69, 170, 0.94),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 10.0,blurStyle: BlurStyle.solid)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat("E").format(weather.date!),
                  style: const TextStyle(color: Colors.white),
                ),
                Image.network(
                  "https://openweathermap.org/img/wn/${weather.weatherIcon}@2x.png",
                  width: 50,
                ),
                Text(
                  "${weather.temperature?.celsius?.round()}°",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(weather.date!),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
