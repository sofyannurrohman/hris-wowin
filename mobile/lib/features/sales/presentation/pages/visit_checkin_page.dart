import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/features/sales/presentation/pages/visit_transaction_page.dart';
import 'package:hris_app/core/database/database.dart';
import 'package:hris_app/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:drift/drift.dart' hide Column;
import 'package:path_provider/path_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';

class VisitCheckinPage extends StatefulWidget {
  final StoreModel store;
  const VisitCheckinPage({super.key, required this.store});

  @override
  State<VisitCheckinPage> createState() => _VisitCheckinPageState();
}

class _VisitCheckinPageState extends State<VisitCheckinPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isTaking = false;
  String? _capturedPath;
  Uint8List? _capturedBytes;
  String _address = 'Mengambil lokasi...';
  String _timestamp = '';
  double _lat = 0.0, _lng = 0.0;

  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _getLocation();
    _timestamp = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    // Prefer front camera
    final front = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    _controller = CameraController(front, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      String readableAddress = 'GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      try {
        // Set locale to ensure consistent results
        try {
          await setLocaleIdentifier("id_ID");
        } catch (_) {}

        // Small delay to ensure GPS provider is ready for geocoding
        await Future.delayed(const Duration(milliseconds: 500));

        List<Placemark>? placemarks;
        int retries = 0;
        while (retries < 2 && (placemarks == null || placemarks.isEmpty)) {
          try {
            placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude)
                .timeout(const Duration(seconds: 5));
          } catch (e) {
            debugPrint('Geocoding retry $retries error: $e');
          }
          if (placemarks == null || placemarks.isEmpty) {
            retries++;
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (placemarks != null && placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          List<String> components = [
            place.street ?? '',
            place.subLocality ?? '',
            place.locality ?? '',
            place.subAdministrativeArea ?? '',
          ].where((s) => s.isNotEmpty && !s.contains('null')).toList();
          
          if (components.isNotEmpty) {
            readableAddress = '${components.join(', ')} (GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})';
          }
        } else {
          // SYSTEM GEOCODING FAILED -> FALLBACK TO NOMINATIM (OSM)
          debugPrint('System geocoding failed, trying Nominatim fallback...');
          try {
            final dio = Dio();
            // Use a custom User-Agent as required by Nominatim Policy
            final response = await dio.get(
              'https://nominatim.openstreetmap.org/reverse',
              queryParameters: {
                'lat': pos.latitude,
                'lon': pos.longitude,
                'format': 'json',
                'addressdetails': 1,
              },
              options: Options(headers: {'User-Agent': 'WowinSuperApp/1.0'}),
            ).timeout(const Duration(seconds: 5));

            if (response.statusCode == 200 && response.data != null) {
              final addr = response.data['address'];
              if (addr != null) {
                // Prioritize specific components for a detailed address
                final List<String> osmComponents = [
                  addr['house_number'] ?? addr['house_name'] ?? addr['building'] ?? '',
                  addr['road'] ?? addr['amenity'] ?? addr['industrial'] ?? '',
                  addr['neighbourhood'] ?? addr['suburb'] ?? addr['city_block'] ?? addr['quarter'] ?? '',
                  addr['village'] ?? addr['hamlet'] ?? addr['town'] ?? addr['city_district'] ?? addr['city'] ?? addr['municipality'] ?? '',
                  addr['county'] ?? '',
                  addr['postcode'] ?? '',
                ].where((s) => s != null && s.toString().isNotEmpty).map((s) => s.toString()).toList();
                
                if (osmComponents.isNotEmpty) {
                  readableAddress = '${osmComponents.join(', ')} (GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})';
                  debugPrint('Nominatim detailed success: $readableAddress');
                } else if (response.data['display_name'] != null) {
                  // Final fallback to the pre-formatted display_name from OSM
                  readableAddress = '${response.data['display_name']} (GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})';
                }
              }
            }
          } catch (osmError) {
            debugPrint('Nominatim fallback error: $osmError');
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding ultimate error: $e');
      }

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _address = readableAddress;
      });
    } catch (_) {
      setState(() => _address = 'Lokasi tidak tersedia');
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_isInitialized || _isTaking) return;
    setState(() => _isTaking = true);

    try {
      final xfile = await _controller!.takePicture();
      final bytes = await xfile.readAsBytes();

      // Burn watermark onto the captured image using canvas
      final resultBytes = await _burnWatermark(bytes);
      
      String pathOrBase64 = '';
      if (kIsWeb) {
        // On Web, convert to Base64 for storage in local DB
        pathOrBase64 = 'data:image/png;base64,${base64Encode(resultBytes)}';
      } else {
        final dir = await getTemporaryDirectory();
        final outPath = '${dir.path}/checkin_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(outPath).writeAsBytes(resultBytes);
        pathOrBase64 = outPath;
      }

      setState(() {
        _capturedBytes = resultBytes;
        _capturedPath = pathOrBase64;
      });
    } catch (e) {
      debugPrint('Camera error: $e');
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }

  Future<Uint8List> _burnWatermark(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImg = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, srcImg.width.toDouble(), srcImg.height.toDouble()));

    // Draw original image
    canvas.drawImage(srcImg, Offset.zero, Paint());

    // Draw watermark background bar at bottom
    final barPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final barHeight = srcImg.height * 0.22;
    canvas.drawRect(
      Rect.fromLTWH(0, srcImg.height - barHeight, srcImg.width.toDouble(), barHeight),
      barPaint,
    );

    // Draw text watermark
    void drawText(String text, double y, double fontSize, {Color color = Colors.white, FontWeight weight = FontWeight.bold}) {
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: fontSize,
        fontWeight: weight,
      ))
        ..pushStyle(ui.TextStyle(color: color, fontWeight: weight))
        ..addText(text);
      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: srcImg.width.toDouble()));
      canvas.drawParagraph(paragraph, Offset(0, y));
    }

    final topY = srcImg.height - barHeight + 30;
    drawText(widget.store.name.toUpperCase(), topY, srcImg.width * 0.04, color: Colors.white, weight: FontWeight.bold);
    drawText(_address, topY + srcImg.width * 0.05, srcImg.width * 0.03, color: Colors.white70);
    drawText('Store Ref: ${widget.store.address}', topY + srcImg.width * 0.09, srcImg.width * 0.025, color: Colors.white.withOpacity(0.5));
    drawText(_timestamp, topY + srcImg.width * 0.13, srcImg.width * 0.03, color: Colors.yellowAccent);

    final picture = recorder.endRecording();
    final resultImg = await picture.toImage(srcImg.width, srcImg.height);
    final byteData = await resultImg.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _capturedBytes != null ? _buildPreview() : _buildCamera(),
    );
  }

  Widget _buildCamera() {
    return Stack(
      children: [
        if (_isInitialized && _controller != null)
          SizedBox.expand(child: CameraPreview(_controller!))
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
            child: Column(
              children: [
                Text('STEP 2: SELFIE CHECK-IN', style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(widget.store.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(widget.store.address, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),

        // Watermark preview at bottom
        Positioned(
          bottom: 130, left: 0, right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(widget.store.name.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                Text(_address, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                Text(_timestamp, style: GoogleFonts.outfit(color: Colors.yellowAccent, fontSize: 11)),
              ],
            ),
          ),
        ),

        // Capture button
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _takePhoto,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20)],
                ),
                child: _isTaking ? const CircularProgressIndicator(color: Colors.black) : const Icon(Icons.camera_alt_rounded, size: 36, color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.memory(_capturedBytes!, fit: BoxFit.cover),
        ),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
            child: Column(
              children: [
                Text('PRATINJAU FOTO', style: GoogleFonts.outfit(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('Apakah foto sudah jelas?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),

        // Action buttons
        Positioned(
          bottom: 40, left: 20, right: 20,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _capturedPath = null;
                    _capturedBytes = null;
                  }),
                  icon: const Icon(Icons.replay_rounded, color: Colors.white),
                  label: Text('FOTO ULANG', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final AppDatabase db = di.sl<AppDatabase>();
                    await db.into(db.localCheckins).insert(LocalCheckinsCompanion.insert(
                      storeId: widget.store.id,
                      storeName: widget.store.name,
                      latitude: _lat,
                      longitude: _lng,
                      selfiePath: _capturedPath!,
                      createdAt: DateTime.now(),
                      syncStatus: const Value('pending'),
                    ));
                    
                    // Trigger sync in background
                    di.sl<SyncBloc>().add(SyncDataRequested());

                    if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => VisitTransactionPage(
                        store: widget.store, 
                        selfiePath: _capturedPath!,
                        selfieBytes: _capturedBytes,
                      )));
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text('LANJUT', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
