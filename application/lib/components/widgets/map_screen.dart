import 'dart:convert';
import 'dart:math' as math;

import 'package:application/services/weather_map_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
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
  late final WeatherMapService mapService;
  final MapController mapController = MapController();

  WeatherLayer selectedLayer = WeatherLayer.temperature;

  final List<Map<String, dynamic>> provinces = const [
    {'name': 'Hà Nội', 'point': LatLng(21.0285, 105.8542)},
    {'name': 'Cao Bằng', 'point': LatLng(22.6666, 106.2588)},
    {'name': 'Tuyên Quang', 'point': LatLng(21.8236, 105.2142)},
    {'name': 'Điện Biên', 'point': LatLng(21.3860, 103.0230)},
    {'name': 'Lai Châu', 'point': LatLng(22.3864, 103.4702)},
    {'name': 'Sơn La', 'point': LatLng(21.3256, 103.9188)},
    {'name': 'Lào Cai', 'point': LatLng(21.7168, 104.8986)},
    {'name': 'Thái Nguyên', 'point': LatLng(21.5942, 105.8482)},
    {'name': 'Lạng Sơn', 'point': LatLng(21.8537, 106.7610)},
    {'name': 'Quảng Ninh', 'point': LatLng(20.9712, 107.0448)},
    {'name': 'Bắc Ninh', 'point': LatLng(21.2731, 106.1946)},
    {'name': 'Phú Thọ', 'point': LatLng(21.3227, 105.4019)},
    {'name': 'Hải Phòng', 'point': LatLng(20.8449, 106.6881)},
    {'name': 'Hưng Yên', 'point': LatLng(20.6464, 106.0511)},
    {'name': 'Ninh Bình', 'point': LatLng(20.2506, 105.9745)},
    {'name': 'Thanh Hóa', 'point': LatLng(19.8067, 105.7852)},
    {'name': 'Nghệ An', 'point': LatLng(18.6796, 105.6813)},
    {'name': 'Hà Tĩnh', 'point': LatLng(18.3559, 105.8877)},
    {'name': 'Quảng Trị', 'point': LatLng(17.4689, 106.6223)},
    {'name': 'Huế', 'point': LatLng(16.4637, 107.5909)},
    {'name': 'Đà Nẵng', 'point': LatLng(16.0544, 108.2022)},
    {'name': 'Quảng Ngãi', 'point': LatLng(15.1214, 108.8044)},
    {'name': 'Gia Lai', 'point': LatLng(13.7820, 109.2190)},
    {'name': 'Khánh Hòa', 'point': LatLng(12.2388, 109.1967)},
    {'name': 'Lâm Đồng', 'point': LatLng(11.9404, 108.4583)},
    {'name': 'Đắk Lắk', 'point': LatLng(12.6664, 108.0378)},
    {'name': 'TP.HCM', 'point': LatLng(10.7769, 106.7009)},
    {'name': 'Đồng Nai', 'point': LatLng(10.9574, 106.8426)},
    {'name': 'Tây Ninh', 'point': LatLng(10.5359, 106.4137)},
    {'name': 'Cần Thơ', 'point': LatLng(10.0452, 105.7469)},
    {'name': 'Vĩnh Long', 'point': LatLng(10.2396, 105.9572)},
    {'name': 'Đồng Tháp', 'point': LatLng(10.3600, 106.3600)},
    {'name': 'Cà Mau', 'point': LatLng(9.1769, 105.1524)},
    {'name': 'An Giang', 'point': LatLng(10.0125, 105.0809)},
  ];

  final Map<String, _ProvinceWeather> provinceWeather = {};

  static const double _markerMinZoom = 6.5;
  double currentZoom = 5.3;

  bool get showMarkers => currentZoom >= _markerMinZoom;

  @override
  void initState() {
    super.initState();

    mapService = WeatherMapService(widget.apiKey);
    loadProvinceTemperatures();
  }

  Future<void> loadProvinceTemperatures() async {
    for (final province in provinces) {
      final name = province['name'] as String;
      final point = province['point'] as LatLng;

      final url = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/weather',
        {
          'lat': point.latitude.toString(),
          'lon': point.longitude.toString(),
          'units': 'metric',
          'appid': widget.apiKey.trim(),
        },
      );

      try {
        final response = await http.get(url);

        if (response.statusCode != 200) {
          debugPrint('Không lấy được $name: ${response.statusCode}');
          continue;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final temp = (data['main']?['temp'] as num?)?.toDouble();
        if (temp == null) continue;

        final entry = _ProvinceWeather(
          temperature: temp,
          windSpeed: (data['wind']?['speed'] as num?)?.toDouble() ?? 0,
          windDegree: (data['wind']?['deg'] as num?)?.toDouble() ?? 0,
          rain: (data['rain']?['1h'] as num?)?.toDouble() ??
              (data['rain']?['3h'] as num?)?.toDouble() ??
              0,
          clouds: (data['clouds']?['all'] as num?)?.toDouble() ?? 0,
          pressure: (data['main']?['pressure'] as num?)?.toDouble() ?? 0,
        );

        if (!mounted) return;
        setState(() {
          provinceWeather[name] = entry;
        });
      } catch (error) {
        debugPrint('Lỗi $name: $error');
      }
    }
  }
  void changeZoom(double amount) {
    final camera = mapController.camera;

    final newZoom = (camera.zoom + amount)
        .clamp(4.0, 18.0)
        .toDouble();

    mapController.move(camera.center, newZoom);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ thời tiết'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                buildChip('Mây', Icons.cloud, WeatherLayer.clouds),
                buildChip('Mưa', Icons.water_drop, WeatherLayer.rain),
                buildChip(
                  'Nhiệt độ',
                  Icons.thermostat,
                  WeatherLayer.temperature,
                ),
                buildChip('Gió', Icons.air, WeatherLayer.wind),
                buildChip(
                  'Áp suất',
                  Icons.speed,
                  WeatherLayer.pressure,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(16.2, 106.2),
                    initialZoom: currentZoom,
                    minZoom: 4,
                    maxZoom: 18,
                    onPositionChanged: (camera, _) {
                      // Chỉ setState khi vượt ngưỡng để tránh rebuild mỗi frame khi kéo zoom.
                      if ((camera.zoom >= _markerMinZoom) != showMarkers) {
                        setState(() => currentZoom = camera.zoom);
                      } else {
                        currentZoom = camera.zoom;
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://api.maptiler.com/maps/streets/'
                          '{z}/{x}/{y}.png?key=b2Qcb2a8OPn4k4DuPp3Y',
                    ),

                    TileLayer(
                      urlTemplate:
                      mapService.getTileUrl(selectedLayer),
                    ),

                    if (showMarkers)
                      MarkerLayer(
                        markers: provinces.map((province) {
                          final name = province['name'] as String;
                          final point = province['point'] as LatLng;
                          final data = provinceWeather[name];

                          return Marker(
                            point: point,
                            width: 116,
                            height: 52,
                            child: _ProvinceBadge(
                              name: name,
                              data: data,
                              layer: selectedLayer,
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),

                if (!showMarkers)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 12,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Phóng to để xem ${_layerName(selectedLayer)} từng tỉnh',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Nút phóng to và thu nhỏ.
                Positioned(
                  right: 12,
                  bottom: 20,
                  child: Column(
                    children: [
                      buildZoomButton(
                        icon: Icons.add,
                        onPressed: () => changeZoom(1),
                      ),
                      const SizedBox(height: 8),
                      buildZoomButton(
                        icon: Icons.remove,
                        onPressed: () => changeZoom(-1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChip(
      String title,
      IconData icon,
      WeatherLayer layer,
      ) {
    final selected = selectedLayer == layer;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        selected: selected,
        selectedColor: Colors.blue.shade100,
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(
          color: selected ? Colors.blue : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.blue : Colors.black54,
            ),
            const SizedBox(width: 5),
            Text(title),
          ],
        ),
        onSelected: (_) {
          setState(() {
            selectedLayer = layer;
          });
        },
      ),
    );
  }

  Widget buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.blue,
        onPressed: onPressed,
      ),
    );
  }
}

class _ProvinceWeather {
  final double temperature;
  final double windSpeed;
  final double windDegree;
  final double rain;
  final double clouds;
  final double pressure;

  const _ProvinceWeather({
    required this.temperature,
    required this.windSpeed,
    required this.windDegree,
    required this.rain,
    required this.clouds,
    required this.pressure,
  });
}

class _ProvinceBadge extends StatelessWidget {
  final String name;
  final _ProvinceWeather? data;
  final WeatherLayer layer;

  const _ProvinceBadge({
    required this.name,
    required this.data,
    required this.layer,
  });

  @override
  Widget build(BuildContext context) {
    final weather = data;
    final isWind = layer == WeatherLayer.wind;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (weather == null)
              const Text(
                '...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              )
            else if (isWind)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0288D1),
                      shape: BoxShape.circle,
                    ),
                    child: Transform.rotate(
                      // wind.deg là hướng gió thổi TỪ, +180 để mũi tên chỉ theo
                      // chiều gió đang đi. Icon gốc hướng lên = 0° = Bắc.
                      angle: (weather.windDegree + 180) * math.pi / 180,
                      child: const Icon(
                        Icons.navigation,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.windSpeed.toStringAsFixed(1)} m/s',
                    style: const TextStyle(
                      color: Color(0xFF81D4FA),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else
              Text(
                _metricText(weather, layer),
                style: TextStyle(
                  color: _metricColor(layer),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _metricText(_ProvinceWeather weather, WeatherLayer layer) {
  switch (layer) {
    case WeatherLayer.temperature:
      return '${weather.temperature.round()}°C';
    case WeatherLayer.rain:
      return weather.rain == 0
          ? '0 mm'
          : '${weather.rain.toStringAsFixed(1)} mm';
    case WeatherLayer.clouds:
      return '${weather.clouds.round()}%';
    case WeatherLayer.pressure:
      return '${weather.pressure.round()} hPa';
    case WeatherLayer.wind:
      return '${weather.windSpeed.toStringAsFixed(1)} m/s';
  }
}

Color _metricColor(WeatherLayer layer) {
  switch (layer) {
    case WeatherLayer.temperature:
      return const Color(0xFFFFEB3B);
    case WeatherLayer.rain:
      return const Color(0xFF4FC3F7);
    case WeatherLayer.clouds:
      return const Color(0xFFE0E0E0);
    case WeatherLayer.pressure:
      return const Color(0xFFCE93D8);
    case WeatherLayer.wind:
      return const Color(0xFF81D4FA);
  }
}