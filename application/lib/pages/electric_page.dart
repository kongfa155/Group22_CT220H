import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../models/BoundaryFeature.dart';
import '../services/electric_services/boundary_api_service.dart';

class ElectricPage extends StatefulWidget {
  const ElectricPage({super.key});

  @override
  State<ElectricPage> createState() => _ElectricPageState();
}

class _ElectricPageState extends State<ElectricPage> {
  //Tọa độ gốc Cần Thơ
  static const LatLng canThoCenter = LatLng(10.0452, 105.7469);
  // Giới hạn khung nhìn quanh khu vực Cần Thơ (không cho kéo/zoom ra quá xa)
  // Bounding box tạm, có thể tinh chỉnh sau khi có GADM boundaries chính xác.
  static final LatLngBounds canThoBounds = LatLngBounds(
      const LatLng(9.85, 105.4), //Góc chéo trên
      const LatLng(10.25, 105.95) //Góc chéo dưới
  );

  final MapController _mapController = MapController();

  List<BoundaryFeature> _boundaries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBoundaries();
  }

  Future<void> _loadBoundaries() async {
    try {
      final data = await BoundaryApiService.getAllBoundaries();
      setState(() {
        _boundaries = data;
        _loading = false;
      });
    } catch (err) {
      setState(() {
        _error = err.toString();
        _loading = false;
      });
    }
  }


  // Sinh màu ổn định dựa theo tên phường/quận, để cùng 1 tên luôn ra cùng 1 màu
  // qua các lần load lại (thay vì random mỗi lần build).
  Color _colorForName(String name) {
    final hash = name.codeUnits.fold<int>(0, (prev, c) => prev + c);
    final random = Random(hash);
    return Color.fromRGBO(
      100 + random.nextInt(155),
      100 + random.nextInt(155),
      100 + random.nextInt(155),
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: canThoCenter,
              initialZoom: 12,
              minZoom: 8,
              maxZoom: 18,
              cameraConstraint: CameraConstraint.contain(bounds: canThoBounds),
            ),
            children: [
              TileLayer(
                urlTemplate:
                "https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
              ),
              PolygonLayer(
                polygons: _boundaries.expand((feature) {
                  final color = _colorForName(feature.name);
                  return feature.polygons.map(
                        (ring) => Polygon(
                      points: ring,
                      color: color.withOpacity(0.4),
                      borderColor: color,
                      borderStrokeWidth: 1.5,
                      label: feature.name,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Lỗi tải ranh giới: $_error'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
