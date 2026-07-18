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
  //Tọa độ gốc Cần Thơ
  static const LatLng canThoCenter = LatLng(10.0452, 105.7469);
  // Giới hạn khung nhìn quanh khu vực Cần Thơ (không cho kéo/zoom ra quá xa)
  // Bounding box tạm, có thể tinh chỉnh sau khi có GADM boundaries chính xác.
  static final LatLngBounds canThoBounds = LatLngBounds(
      const LatLng(9.0, 100.4), //Góc chéo trên
      const LatLng(10.25, 105.95) //Góc chéo dưới
  );

  final MapController _mapController = MapController();

  List<BoundaryFeature> _boundaries = [];
  List<OutageWardGroup> _outageGroups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final boundariesFuture = BoundaryApiService.getAllBoundaries();
      final outagesFuture = OutageMapApiService.getOutagesByWard();

      final boundaries = await boundariesFuture;
      final outageGroups = await outagesFuture;

      setState(() {
        _boundaries = boundaries;
        _outageGroups = outageGroups;
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

  void _showOutageDetails(OutageWardGroup group) {
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.wardName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (group.isApproximateLocation)
                        const Tooltip(
                          message: 'Vị trí gần đúng (chưa xác định chi tiết khu vực)',
                          child: Icon(Icons.info_outline, size: 18, color: Colors.orange),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: group.outages.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final outage = group.outages[index];
                      return _OutageDetailTile(outage: outage);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
              MarkerLayer(
                markers: _outageGroups.map((group) {
                  return Marker(
                    point: LatLng(group.lat, group.lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showOutageDetails(group),
                      child: Icon(
                        Icons.bolt,
                        color: group.isApproximateLocation
                            ? Colors.orange
                            : Colors.red,
                        size: 32,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 4),
                        ],
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
                  child: Text('Lỗi tải ranh giới: $_error'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class _OutageDetailTile extends StatelessWidget {
  final OutageItem outage;

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