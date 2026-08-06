import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;
  final List<Weather> forecast;

  const WeatherCard({
    super.key,
    required this.weather,
    this.forecast = const [],
  });

  @override
  Widget build(BuildContext context) {
    final minMaxTemp = _todayMinMaxTemp(weather, forecast);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 10, left: 10),
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(61, 69, 170, 0.94),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 10.0,
                blurStyle: BlurStyle.solid,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd/MM', 'vi').format(weather.date!),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${weather.areaName}',
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Cao ${minMaxTemp.max.round()}\u00B0  \u2022  Th\u1EA5p ${minMaxTemp.min.round()}\u00B0',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${weather.weatherDescription}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.network(
                        'https://openweathermap.org/img/wn/${weather.weatherIcon}@2x.png',
                        width: 70,
                      ),
                      Text(
                        '${weather.temperature?.celsius?.round()}\u00B0C',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${weather.humidity}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.wind_power_sharp, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${weather.windSpeed} m/s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

({double min, double max}) _todayMinMaxTemp(
  Weather weather,
  List<Weather> forecast,
) {
  final now = weather.date ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  List<double> tempsWhere(bool Function(DateTime) test) => forecast
      .where((item) => item.date != null && test(item.date!))
      .map((item) => item.temperature?.celsius)
      .whereType<double>()
      .toList();

  var temps = tempsWhere(
    (date) => DateTime(date.year, date.month, date.day) == today,
  );

  // Về cuối ngày gần như không còn mốc dự báo nào của hôm nay, khiến min/max
  // sụp về đúng nhiệt độ hiện tại. Khi đó nới ra cửa sổ trượt 24 giờ.
  if (temps.length < 2) {
    temps = tempsWhere(
      (date) =>
          date.isAfter(now.subtract(const Duration(hours: 3))) &&
          date.isBefore(now.add(const Duration(hours: 24))),
    );
  }

  temps.addAll([
    weather.temperature?.celsius,
    weather.tempMin?.celsius,
    weather.tempMax?.celsius,
  ].whereType<double>());

  if (temps.isEmpty) return (min: 0.0, max: 0.0);

  return (min: temps.reduce(math.min), max: temps.reduce(math.max));
}
