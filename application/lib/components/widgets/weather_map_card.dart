import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import '../../apiWeather.dart';
import 'map_screen.dart';

class WeatherMapCard extends StatelessWidget {
  const WeatherMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MapScreen(apiKey: WEATHER_API_KEY),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        height: 180,
        width: double.infinity,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 10.0,blurStyle: BlurStyle.solid)],
          // 🔥 fallback background (quan trọng)
          color: Colors.blueGrey.shade300,
        ),

        child: Stack(
          children: [
            // background layer (SAFE)
            Positioned.fill(
              child: Image.network(
                "https://tile.openstreetmap.org/5/15/10.png",
                fit: BoxFit.cover,
                scale:10,
              ),
            ),

            // overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Weather Map",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Tap to view radar & clouds",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
