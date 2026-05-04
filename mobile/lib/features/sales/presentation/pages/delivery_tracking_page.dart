import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hris_app/features/sales/presentation/pages/optimal_route_map_page.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryTrackingPage extends StatefulWidget {
  const DeliveryTrackingPage({super.key});

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  bool _isScanning = true;
  bool _isLoading = false;
  Map<String, dynamic>? _batchData;
  final MobileScannerController _scannerController = MobileScannerController();

  Future<void> _fetchBatch(String doNo) async {
    setState(() {
      _isLoading = true;
      _isScanning = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final baseUrl = 'http://localhost:8080/api/v1'; // Should use env config

      final response = await Dio().get(
        '$baseUrl/delivery/batch/$doNo',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        _batchData = response.data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data SJ: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isScanning = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateItemStatus(String itemID, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final baseUrl = 'http://localhost:8080/api/v1';

      await Dio().post(
        '$baseUrl/delivery/items/$itemID/confirm',
        data: {'status': status, 'notes': 'Diterima oleh toko'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Refresh data
      _fetchBatch(_batchData!['delivery_order_no']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isScanning ? 'Scan Surat Jalan' : 'Detail Pengiriman',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
        actions: [
          if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.blueAccent),
              onPressed: () => setState(() {
                _isScanning = true;
                _batchData = null;
              }),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isScanning
              ? _buildScanner()
              : _batchData == null
                  ? _buildEmptyState()
                  : _buildBatchDetail(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _fetchBatch(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Arahkan kamera ke barcode Surat Jalan',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_shipping_outlined, size: 80, color: Colors.slate-200),
          const SizedBox(height: 16),
          Text(
            'Belum ada data pengiriman',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.slate-400),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchDetail() {
    final items = _batchData!['items'] as List;
    final stores = items.map((i) => StoreModel.fromJson(i['sales_transaction']['store'])).toList();

    return Column(
      children: [
        // Header Info
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NOMOR SURAT JALAN', style: GoogleFonts.outfit(fontSize: 10, color: Colors.slate-400, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      Text(_batchData!['delivery_order_no'], style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _batchData!['status'],
                      style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OptimalRouteMapPage(stores: stores)),
                  );
                },
                icon: const Icon(Icons.map_rounded),
                label: const Text('LIHAT RUTE OPTIMAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),

        // List of Stores
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final store = item['sales_transaction']['store'];
              final isDelivered = item['status'] == 'DELIVERED';

              return Container(
                margin: const EdgeInsets.bottom(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDelivered ? Colors.green.withOpacity(0.2) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDelivered ? Colors.green.withOpacity(0.1) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            color: isDelivered ? Colors.green : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(store['address'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.slate-500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (!isDelivered)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.blueAccent, size: 32),
                        onPressed: () => _updateItemStatus(item['id'], 'DELIVERED'),
                      )
                    else
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
