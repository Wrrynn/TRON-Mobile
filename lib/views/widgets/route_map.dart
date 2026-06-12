import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../config/app_theme.dart';
import '../../models/destination.dart';
import 'glass.dart';

/// Peta rute perjalanan untuk halaman detail — menampilkan destinasi sebagai
/// marker bernomor + garis rute. Mencoba routing OSRM (jalur jalan sebenarnya)
/// seperti web app; jika gagal, fallback ke garis lurus "estimasi".
class RouteMap extends StatefulWidget {
  final List<Destination> destinations;
  final double height;

  const RouteMap({super.key, required this.destinations, this.height = 220});

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  static const _tileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  List<LatLng> _points = [];
  List<LatLng> _route = [];
  bool _estimated = true;

  List<Destination> get _valid =>
      widget.destinations.where((d) => d.lat != null && d.lng != null).toList();

  @override
  void initState() {
    super.initState();
    _points = _valid.map((d) => LatLng(d.lat!, d.lng!)).toList();
    _route = List.of(_points);
    if (_points.length >= 2) _fetchOsrm();
  }

  Future<void> _fetchOsrm() async {
    try {
      final coords = _points.map((p) => '${p.longitude},${p.latitude}').join(';');
      final res = await http
          .get(Uri.parse(
              'https://router.project-osrm.org/route/v1/foot/$coords?overview=full&geometries=geojson'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final coordsList =
              routes.first['geometry']['coordinates'] as List;
          final pts = coordsList
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted && pts.isNotEmpty) {
            setState(() {
              _route = pts;
              _estimated = false;
            });
          }
        }
      }
    } catch (_) {/* tetap pakai garis estimasi */}
  }

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCameraFit: _points.length == 1
                    ? null
                    : CameraFit.coordinates(
                        coordinates: _points,
                        padding: const EdgeInsets.all(44),
                        maxZoom: 14,
                      ),
                initialCenter: _points.first,
                initialZoom: 12,
                backgroundColor: const Color(0xFF1B2533),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.tripmo.mobile',
                ),
                if (_route.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route,
                        strokeWidth: 8,
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      ),
                      Polyline(
                        points: _route,
                        strokeWidth: 3,
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < _points.length; i++)
                      Marker(
                        point: _points[i],
                        width: 30,
                        height: 30,
                        child: _RouteDot(
                          index: i,
                          total: _points.length,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_estimated && _points.length >= 2)
              Positioned(
                left: 10,
                bottom: 10,
                child: GlassPill(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.timeline_rounded, size: 13, color: Color(0xFFF59E0B)),
                      SizedBox(width: 5),
                      Text('Jalur estimasi',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final int index;
  final int total;
  const _RouteDot({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    final isStart = index == 0;
    final isEnd = index == total - 1;
    final color = isStart
        ? AppColors.purple
        : isEnd
            ? const Color(0xFFE8410A)
            : AppColors.purple.withValues(alpha: 0.6);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
        ],
      ),
      child: Text(
        '${index + 1}',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
