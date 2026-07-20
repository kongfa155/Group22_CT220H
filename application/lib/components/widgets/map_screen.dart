// import 'package:application/services/weather_map_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
//
// class MapScreen extends StatefulWidget {
//   final String apiKey;
//
//   const MapScreen({
//     super.key,
//     required this.apiKey,
//   });
//
//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   late WeatherMapService mapService;
//
//   WeatherLayer selectedLayer = WeatherLayer.rain;
//
//   @override
//   void initState() {
//     super.initState();
//     mapService = WeatherMapService(widget.apiKey);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Weather Map"),
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//
//           SizedBox(
//             height: 45,
//             child: ListView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               children: [
//                 buildChip("Clouds", WeatherLayer.clouds),
//                 buildChip("Rain", WeatherLayer.rain),
//                 buildChip("Temp", WeatherLayer.temperature),
//                 buildChip("Wind", WeatherLayer.wind),
//                 buildChip("Pressure", WeatherLayer.pressure),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 10),
//
//           Expanded(
//             child: FlutterMap(
//               options: const MapOptions(
//                 initialCenter: LatLng(10.0452, 105.7469),
//                 initialZoom: 8,
//                 minZoom: 4,
//                 maxZoom: 18,
//
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate:
//                   "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=b2Qcb2a8OPn4k4DuPp3Y",
//                 ),
//
//                 TileLayer(
//                   urlTemplate: mapService.getTileUrl(selectedLayer),
//
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget buildChip(String title, WeatherLayer layer) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: ChoiceChip(
//         label: Text(title),
//         selected: selectedLayer == layer,
//         onSelected: (_) {
//           setState(() {
//             selectedLayer = layer;
//           });
//         },
//       ),
//     );
//   }
// }
import 'dart:convert';

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

  // Ba điểm đại diện cho ba miền.
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

  final Map<String, double> temperatures = {};

  @override
  void initState() {
    super.initState();

    mapService = WeatherMapService(widget.apiKey);
    loadProvinceTemperatures();
  }
  //
  // Future<void> loadProvinceTemperatures() async {
  //   await Future.wait(
  //     provinces.map((province) async {
  //       final name = province['name'] as String;
  //       final point = province['point'] as LatLng;
  //
  //       final url = Uri.parse(
  //         'https://api.openweathermap.org/data/2.5/weather'
  //             '?lat=${point.latitude}'
  //             '&lon=${point.longitude}'
  //             '&units=metric'
  //             '&appid=${widget.apiKey}',
  //       );
  //
  //       try {
  //         final response = await http.get(url);
  //
  //         if (response.statusCode == 200) {
  //           final data =
  //           jsonDecode(response.body) as Map<String, dynamic>;
  //
  //           temperatures[name] =
  //               (data['main']['temp'] as num).toDouble();
  //         } else {
  //           debugPrint(
  //             'Không lấy được $name: ${response.statusCode}',
  //           );
  //         }
  //       } catch (error) {
  //         debugPrint('Lỗi lấy nhiệt độ $name: $error');
  //       }
  //     }),
  //   );
  //
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }
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

        debugPrint(
          '$name: ${response.statusCode} - ${response.body}',
        );

        if (response.statusCode == 200) {
          final data =
          jsonDecode(response.body) as Map<String, dynamic>;

          final temp =
          (data['main']?['temp'] as num?)?.toDouble();

          if (temp != null && mounted) {
            setState(() {
              temperatures[name] = temp;
            });
          }
        }
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
                  options: const MapOptions(
                    initialCenter: LatLng(16.2, 106.2),
                    initialZoom: 5.3,
                    minZoom: 4,
                    maxZoom: 18,
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


                    MarkerLayer(
                      markers: provinces.map((province) {
                        final name = province['name'] as String;
                        final point = province['point'] as LatLng;
                        final temperature = temperatures[name];

                        return Marker(
                          point: point,
                          width: 85,
                          height: 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Text(
                              //   name,
                              //   maxLines: 1,
                              //   overflow: TextOverflow.ellipsis,
                              //   textAlign: TextAlign.center,
                              //   style: const TextStyle(
                              //     color: Colors.white,
                              //     fontSize: 11,
                              //     fontWeight: FontWeight.bold,
                              //     shadows: [
                              //       Shadow(
                              //         color: Colors.black,
                              //         blurRadius: 3,
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              SizedBox(height: 14,),
                              Text(
                                temperature == null
                                    ? '...'
                                    : '${temperature.round()}°C',
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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