import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../models/BoundaryFeature.dart';
import '../models/OutageItem.dart';
import '../services/electric_services/boundary_api_service.dart';
import '../services/electric_services/outage_map_api_service.dart';

class ElectricPage extends StatefulWidget {
  const ElectricPage({super.key});

  @override
  State<ElectricPage> createState() => _ElectricPageState();
}

class _ElectricPageState extends State<ElectricPage> {
  static const LatLng canThoCenter = LatLng(10.0452, 105.7469);
  static final LatLngBounds canThoBounds = LatLngBounds(
    const LatLng(9.0, 100.4),
    const LatLng(10.4, 105.95),
  );

  // Ngưỡng zoom chuyển từ "tổng hợp theo phường" sang "chi tiết" - chỉnh
  // lại số này sau khi test thực tế xem mức nào thấy rõ đường/khu vực.
  static const double detailZoomThreshold = 14.0;

  final MapController _mapController = MapController();
  double _currentZoom = 12;

  List<BoundaryFeature> _boundaries = [];
  List<OutagePointGroup> _wardSummaries = [];
  List<OutageAreaFeature> _roadAreas = [];
  List<OutageAreaFeature> _placeAreas = [];
  List<OutagePointGroup> _fallbackPoints = [];
  bool _loading = true;
  String? _error;

  bool get _isDetailZoom => _currentZoom >= detailZoomThreshold;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final boundariesFuture = BoundaryApiService.getAllBoundaries();
      final outageFuture = OutageMapApiService.getOutagesByWard();

      final boundaries = await boundariesFuture;
      final outageResult = await outageFuture;

      setState(() {
        _boundaries = boundaries;
        _wardSummaries = outageResult.wardSummaries;
        _roadAreas = outageResult.roadAreas;
        _placeAreas = outageResult.placeAreas;
        _fallbackPoints = outageResult.points;
        _loading = false;
      });
    } catch (err) {
      setState(() {
        _error = err.toString();
        _loading = false;
      });
    }
  }

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

  void _showOutageDetailsGroup(OutagePointGroup group) {
    _showOutageListSheet(group.label, group.outages);
  }

  void _showOutageDetailsSingle(String label, OutageDetailItem outage) {
    _showOutageListSheet(label, [outage]);
  }

  void _showOutageListSheet(String title, List<OutageDetailItem> outages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$title (${outages.length} lịch cúp điện)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: outages.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) => _OutageDetailTile(outage: outages[index]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;
      final intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  void _handleMapTap(LatLng point) {
    if (!_isDetailZoom) return;

    for (final area in [..._roadAreas, ..._placeAreas]) {
      for (final ring in area.polygons) {
        if (_pointInPolygon(point, ring)) {
          _showOutageDetailsSingle(area.label, area.outage);
          return;
        }
      }
    }
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
              onMapEvent: (event) {
                final newZoom = event.camera.zoom;
                if ((newZoom - _currentZoom).abs() > 0.05) {
                  setState(() => _currentZoom = newZoom);
                }
              },
              onTap: (tapPosition, point) => _handleMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
              ),

              // --- ZOOM XA: tô màu ranh giới phường ---
              if (!_isDetailZoom)
                PolygonLayer(
                  polygons: _boundaries.expand((feature) {
                    final color = _colorForName(feature.name);
                    return feature.polygons.map(
                          (ring) => Polygon(
                        points: ring,
                        color: color.withOpacity(0.4),
                        borderColor: color,
                        borderStrokeWidth: 1.5,
                        label: _currentZoom >= 11 ? feature.name : null,
                      ),
                    );
                  }).toList(),
                ),

              // --- ZOOM SÂU: tô vàng/cam đường + khu vực cụ thể ---
              if (_isDetailZoom)
                PolygonLayer(
                  polygons: [..._roadAreas, ..._placeAreas].expand((area) {
                    final fillColor = area.color == 'yellow' ? Colors.amber : Colors.deepOrange;
                    return area.polygons.map(
                          (ring) => Polygon(
                        points: ring,
                        color: fillColor.withOpacity(0.5),
                        borderColor: fillColor,
                        borderStrokeWidth: 1.5,
                      ),
                    );
                  }).toList(),
                ),

              // --- ZOOM XA: 1 marker gộp cho mỗi phường ---
              if (!_isDetailZoom)
                MarkerLayer(
                  markers: _wardSummaries.map((group) {
                    return Marker(
                      point: LatLng(group.lat, group.lng),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showOutageDetailsGroup(group),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: Colors.red,
                              size: 32,
                              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${group.outages.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // --- ZOOM SÂU: marker fallback cho outage chưa match road/place ---
              if (_isDetailZoom)
                MarkerLayer(
                  markers: _fallbackPoints.map((group) {
                    return Marker(
                      point: LatLng(group.lat, group.lng),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showOutageDetailsGroup(group),
                        child: const Icon(
                          Icons.bolt,
                          color: Colors.orange,
                          size: 28,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
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
                  child: Text('Lỗi tải dữ liệu: $_error'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutageDetailTile extends StatelessWidget {
  final OutageDetailItem outage;

  const _OutageDetailTile({required this.outage});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              outage.timeRangeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (outage.status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  outage.status!,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(outage.areaText, style: const TextStyle(fontSize: 14)),
        if (outage.reason != null) ...[
          const SizedBox(height: 4),
          Text(
            'Lý do: ${outage.reason}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
        if (outage.powerCompany != null) ...[
          const SizedBox(height: 2),
          Text(
            outage.powerCompany!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}