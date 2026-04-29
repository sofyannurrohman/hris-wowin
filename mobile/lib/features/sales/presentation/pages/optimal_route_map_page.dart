import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'dart:math' show cos, sqrt, asin, sin, pi;

class OptimalRouteMapPage extends StatefulWidget {
  final List<StoreModel> stores;

  const OptimalRouteMapPage({super.key, required this.stores});

  @override
  State<OptimalRouteMapPage> createState() => _OptimalRouteMapPageState();
}

class _OptimalRouteMapPageState extends State<OptimalRouteMapPage> {
  bool _isLoading = true;
  LatLng? _currentLocation;
  List<StoreModel> _orderedStores = [];
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    setState(() => _isLoading = true);
    try {
      // Get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS tidak aktif');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Izin lokasi ditolak');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _currentLocation = LatLng(position.latitude, position.longitude);

      // Nearest Neighbor Algorithm
      List<StoreModel> unvisited = List.from(widget.stores);
      LatLng currentPos = _currentLocation!;
      List<StoreModel> ordered = [];
      List<LatLng> points = [currentPos];

      while (unvisited.isNotEmpty) {
        // Find nearest
        StoreModel? nearest;
        double minDistance = double.infinity;
        
        for (var store in unvisited) {
          double dist = _haversineDistance(currentPos, LatLng(store.latitude!, store.longitude!));
          if (dist < minDistance) {
            minDistance = dist;
            nearest = store;
          }
        }

        ordered.add(nearest!);
        currentPos = LatLng(nearest.latitude!, nearest.longitude!);
        points.add(currentPos);
        unvisited.remove(nearest);
      }

      setState(() {
        _orderedStores = ordered;
        _routePoints = points;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) * cos(p2.latitude * p) *
            (1 - cos((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HASIL OPTIMASI', style: GoogleFonts.outfit(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text('Rute Kunjungan', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null
              ? const Center(child: Text('Gagal mendapatkan lokasi saat ini'))
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentLocation!,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wowin.hris_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4.0,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Current Location
                        Marker(
                          point: _currentLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.my_location_rounded, color: Colors.blueAccent, size: 36),
                        ),
                        // Stores
                        for (int i = 0; i < _orderedStores.length; i++)
                          Marker(
                            point: LatLng(_orderedStores[i].latitude!, _orderedStores[i].longitude!),
                            width: 60,
                            height: 60,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                  ),
                                ),
                                const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 24),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
