import 'dart:convert';
import 'dart:math' as math;

import 'package:application/services/weather_map_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const _provinces = <String, LatLng>{
  'Hà Nội': LatLng(21.0285, 105.8542),
  'Cao Bằng': LatLng(22.6666, 106.2588),
  'Tuyên Quang': LatLng(21.8236, 105.2142),
  'Điện Biên': LatLng(21.3860, 103.0230),
  'Lai Châu': LatLng(22.3864, 103.4702),
  'Sơn La': LatLng(21.3256, 103.9188),
  'Lào Cai': LatLng(21.7168, 104.8986),
  'Thái Nguyên': LatLng(21.5942, 105.8482),
  'Lạng Sơn': LatLng(21.8537, 106.7610),
  'Quảng Ninh': LatLng(20.9712, 107.0448),
  'Bắc Ninh': LatLng(21.2731, 106.1946),
  'Phú Thọ': LatLng(21.3227, 105.4019),
  'Hải Phòng': LatLng(20.8449, 106.6881),
  'Hưng Yên': LatLng(20.6464, 106.0511),
  'Ninh Bình': LatLng(20.2506, 105.9745),
  'Thanh Hóa': LatLng(19.8067, 105.7852),
  'Nghệ An': LatLng(18.6796, 105.6813),
  'Hà Tĩnh': LatLng(18.3559, 105.8877),
  'Quảng Trị': LatLng(17.4689, 106.6223),
  'Huế': LatLng(16.4637, 107.5909),
  'Đà Nẵng': LatLng(16.0544, 108.2022),
  'Quảng Ngãi': LatLng(15.1214, 108.8044),
  'Gia Lai': LatLng(13.7820, 109.2190),
  'Khánh Hòa': LatLng(12.2388, 109.1967),
  'Lâm Đồng': LatLng(11.9404, 108.4583),
  'Đắk Lắk': LatLng(12.6664, 108.0378),
  'TP.HCM': LatLng(10.7769, 106.7009),
  'Đồng Nai': LatLng(10.9574, 106.8426),
  'Tây Ninh': LatLng(10.5359, 106.4137),
  'Cần Thơ': LatLng(10.0452, 105.7469),
  'Vĩnh Long': LatLng(10.2396, 105.9572),
  'Đồng Tháp': LatLng(10.3600, 106.3600),
  'Cà Mau': LatLng(9.1769, 105.1524),
  'An Giang': LatLng(10.0125, 105.0809),
};

const _chips = <(String, IconData, WeatherLayer)>[
  ('Mây', Icons.cloud, WeatherLayer.clouds),
  ('Mưa', Icons.water_drop, WeatherLayer.rain),
  ('Nhiệt độ', Icons.thermostat, WeatherLayer.temperature),
  ('Gió', Icons.air, WeatherLayer.wind),
  ('Áp suất', Icons.speed, WeatherLayer.pressure),
];

class MapScreen extends StatefulWidget {
  final String apiKey;

  const MapScreen({super.key, required this.apiKey});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _markerMinZoom = 6.5;

  late final WeatherMapService mapService;
  final mapController = MapController();
  final Map<String, _ProvinceWeather> provinceWeather = {};

  WeatherLayer selectedLayer = WeatherLayer.temperature;
  double currentZoom = 5.3;

  bool get showMarkers => currentZoom >= _markerMinZoom;

  @override
  void initState() {
    super.initState();
    mapService = WeatherMapService(widget.apiKey);
    loadProvinceWeather();
  }

  Future<void> loadProvinceWeather() async {
    for (final entry in _provinces.entries) {
      final url = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'lat': entry.value.latitude.toString(),
        'lon': entry.value.longitude.toString(),
        'units': 'metric',
        'appid': widget.apiKey.trim(),
      });

      try {
        final response = await http.get(url);
        if (response.statusCode != 200) {
          debugPrint('Không lấy được ${entry.key}: ${response.statusCode}');
          continue;
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          provinceWeather[entry.key] = _ProvinceWeather.fromJson(json);
        });
      } catch (error) {
        debugPrint('Lỗi ${entry.key}: $error');
      }
    }
  }

  void changeZoom(double amount) {
    final camera = mapController.camera;
    mapController.move(
      camera.center,
      (camera.zoom + amount).clamp(4.0, 18.0).toDouble(),
    );
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
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                for (final (title, icon, layer) in _chips)
                  buildChip(title, icon, layer),
              ],
            ),
          ),
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
                      // Chỉ rebuild khi vượt ngưỡng, tránh setState mỗi frame lúc zoom.
                      final wasVisible = showMarkers;
                      currentZoom = camera.zoom;
                      if (showMarkers != wasVisible) setState(() {});
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://api.maptiler.com/maps/streets/'
                          '{z}/{x}/{y}.png?key=b2Qcb2a8OPn4k4DuPp3Y',
                    ),
                    TileLayer(urlTemplate: mapService.getTileUrl(selectedLayer)),
                    if (showMarkers)
                      MarkerLayer(
                        markers: [
                          for (final entry in _provinces.entries)
                            Marker(
                              point: entry.value,
                              width: 116,
                              height: 52,
                              child: _ProvinceBadge(
                                name: entry.key,
                                data: provinceWeather[entry.key],
                                layer: selectedLayer,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                if (!showMarkers)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
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
                Positioned(
                  right: 12,
                  bottom: 20,
                  child: Column(
                    children: [
                      buildZoomButton(Icons.add, () => changeZoom(1)),
                      const SizedBox(height: 8),
                      buildZoomButton(Icons.remove, () => changeZoom(-1)),
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

  Widget buildChip(String title, IconData icon, WeatherLayer layer) {
    final selected = selectedLayer == layer;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        selected: selected,
        selectedColor: Colors.blue.shade100,
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(color: selected ? Colors.blue : Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.blue : Colors.black54),
            const SizedBox(width: 5),
            Text(title),
          ],
        ),
        onSelected: (_) => setState(() => selectedLayer = layer),
      ),
    );
  }

  Widget buildZoomButton(IconData icon, VoidCallback onPressed) {
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

  factory _ProvinceWeather.fromJson(Map<String, dynamic> json) {
    double read(Object? value) => (value as num?)?.toDouble() ?? 0;
    final rain = json['rain'] as Map<String, dynamic>?;

    return _ProvinceWeather(
      temperature: read(json['main']?['temp']),
      windSpeed: read(json['wind']?['speed']),
      windDegree: read(json['wind']?['deg']),
      // OpenWeatherMap chỉ trả field `rain` khi tỉnh đó đang mưa.
      rain: read(rain?['1h'] ?? rain?['3h']),
      clouds: read(json['clouds']?['all']),
      pressure: read(json['main']?['pressure']),
    );
  }
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (weather != null && layer == WeatherLayer.wind) ...[
                  _WindArrow(degree: weather.windDegree),
                  const SizedBox(width: 4),
                ],
                Text(
                  weather == null ? '...' : _metricText(weather, layer),
                  style: TextStyle(
                    color: weather == null
                        ? Colors.white
                        : _metricColor(layer),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WindArrow extends StatelessWidget {
  final double degree;

  const _WindArrow({required this.degree});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFF0288D1),
        shape: BoxShape.circle,
      ),
      child: Transform.rotate(
        // wind.deg là hướng gió thổi TỪ, +180 để mũi tên chỉ theo chiều gió
        // đang đi. Icon gốc hướng lên = 0° = Bắc.
        angle: (degree + 180) * math.pi / 180,
        child: const Icon(Icons.navigation, size: 12, color: Colors.white),
      ),
    );
  }
}

String _layerName(WeatherLayer layer) => switch (layer) {
      WeatherLayer.temperature => 'nhiệt độ',
      WeatherLayer.rain => 'lượng mưa',
      WeatherLayer.clouds => 'lượng mây',
      WeatherLayer.pressure => 'áp suất',
      WeatherLayer.wind => 'hướng gió',
    };

String _metricText(_ProvinceWeather w, WeatherLayer layer) => switch (layer) {
      WeatherLayer.temperature => '${w.temperature.round()}°C',
      WeatherLayer.rain => '${w.rain.toStringAsFixed(1)} mm',
      WeatherLayer.clouds => '${w.clouds.round()}%',
      WeatherLayer.pressure => '${w.pressure.round()} hPa',
      WeatherLayer.wind => '${w.windSpeed.toStringAsFixed(1)} m/s',
    };

Color _metricColor(WeatherLayer layer) => switch (layer) {
      WeatherLayer.temperature => const Color(0xFFFFEB3B),
      WeatherLayer.rain => const Color(0xFF4FC3F7),
      WeatherLayer.clouds => const Color(0xFFE0E0E0),
      WeatherLayer.pressure => const Color(0xFFCE93D8),
      WeatherLayer.wind => const Color(0xFF81D4FA),
    };
