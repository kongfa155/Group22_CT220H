import 'package:application/services/weather_map_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final String apiKey;

  const MapScreen({
    super.key,
    required this.apiKey,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late WeatherMapService mapService;

  WeatherLayer selectedLayer = WeatherLayer.rain;

  @override
  void initState() {
    super.initState();
    mapService = WeatherMapService(widget.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Map"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                buildChip("Clouds", WeatherLayer.clouds),
                buildChip("Rain", WeatherLayer.rain),
                buildChip("Temp", WeatherLayer.temperature),
                buildChip("Wind", WeatherLayer.wind),
                buildChip("Pressure", WeatherLayer.pressure),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(10.0452, 105.7469),
                initialZoom: 6,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  "https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                ),

                TileLayer(
                  urlTemplate: mapService.getTileUrl(selectedLayer),

                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChip(String title, WeatherLayer layer) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title),
        selected: selectedLayer == layer,
        onSelected: (_) {
          setState(() {
            selectedLayer = layer;
          });
        },
      ),
    );
  }
}