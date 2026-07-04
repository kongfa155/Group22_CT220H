import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'dart:ui';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 20, bottom: 20),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(61, 69, 170,0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 10.0,blurStyle: BlurStyle.solid)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, //de tam nhu vay
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(DateFormat('EEEE, dd MMMM').format(weather.date!), style: TextStyle(fontSize: 20, color: Colors.white)),
                            Text(
                              "${weather.areaName}",
                              style: TextStyle(fontSize: 30, color: Colors.white),
                            ),
                            Text("${weather.tempMin?.celsius?.round()}°/${weather.tempMax?.celsius?.round()}°",
                                style: TextStyle(fontSize: 20, color: Colors.white)),

                            Text(
                              "${weather.weatherDescription}",
                              style: TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          ],

                        ),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.network(
                              "https://openweathermap.org/img/wn/${weather.weatherIcon}@2x.png",
                              width: 70,
                            ),
                            Text(
                              "${weather.temperature?.celsius?.round()}°C",
                              style: TextStyle(fontSize: 40, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.water_drop, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              "${weather.humidity}%",
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Icon(Icons.wind_power_sharp, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              "${weather.windSpeed} m/s",
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
        ],
    );
  }
}
