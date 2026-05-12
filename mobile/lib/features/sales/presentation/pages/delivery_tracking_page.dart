import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hris_app/features/sales/presentation/pages/optimal_route_map_page.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/core/utils/constants.dart';
import 'package:hris_app/injection.dart' as di;

class DeliveryTrackingPage extends StatefulWidget {
  final bool initialScan;
  final bool autoShowMap;

  const DeliveryTrackingPage({
    super.key, 
    this.initialScan = false, 
    this.autoShowMap = false,
  });

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  bool _isScanning = false;
  bool _isLoading = false;
  bool _showTasks = true;
  List<dynamic> _tasks = [];
  Map<String, dynamic>? _batchData;
  final MobileScannerController _scannerController = MobileScannerController();
  final ApiClient apiClient = di.sl<ApiClient>();

  @override
  void initState() {
    super.initState();
    if (widget.initialScan) {
      _isScanning = true;
      _showTasks = false;
    } else {
      _fetchTasks();
    }
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _showTasks = true;
      _isScanning = false;
    });

    try {
      final response = await apiClient.client.get('delivery/tasks');

      setState(() {
        _tasks = response.data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil tugas: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBatch(String doNo) async {
    setState(() {
      _isLoading = true;
      _isScanning = false;
      _showTasks = false;
    });

    try {
      final response = await apiClient.client.get('delivery/batch/$doNo');

      setState(() {
        _batchData = response.data;
      });

      if (widget.autoShowMap && mounted) {
        final items = _batchData!['items'] as List;
        final stores = items.map((i) => StoreModel.fromJson(i['sales_transaction']['store'])).toList();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OptimalRouteMapPage(stores: stores)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data SJ: $e'), backgroundColor: Colors.red),
      );
      setState(() => _showTasks = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateItemStatus(String itemID, String status) async {
    try {
      await apiClient.client.post(
        'delivery/items/$itemID/confirm',
        data: {'status': status, 'notes': 'Diterima oleh toko'},
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
          _showTasks ? 'Tugas Pengiriman' : (_isScanning ? 'Scan Surat Jalan' : 'Detail Pengiriman'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
        actions: [
          if (!_showTasks)
            IconButton(
              icon: const Icon(Icons.list_alt_rounded, color: Colors.blueAccent),
              onPressed: () => setState(() {
                _showTasks = true;
                _isScanning = false;
                _batchData = null;
              }),
            ),
          if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.blueAccent),
              onPressed: () => setState(() {
                _isScanning = true;
                _showTasks = false;
                _batchData = null;
              }),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showTasks
              ? _buildTaskList()
              : _isScanning
                  ? _buildScanner()
                  : _batchData == null
                      ? _buildEmptyState()
                      : _buildBatchDetail(),
    );
  }

  Widget _buildTaskList() {
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 80, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Text(
              'Tidak ada tugas pengiriman',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final status = task['status'];
          final doNo = task['delivery_order_no'];
          final itemCount = (task['items'] as List).length;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
            shadowColor: Colors.black12,
            child: InkWell(
              onTap: () => _fetchBatch(doNo),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doNo,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 12),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: _getStatusColor(status), fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tugas Pengiriman #$doNo',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          '$itemCount Toko Tujuan',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Hari Ini',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAITING': return Colors.orange;
      case 'IN_TRANSIT': return Colors.blue;
      case 'DELIVERED': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null) {
                if (code.startsWith('SJ-')) {
                   _fetchBatch(code);
                } else if (code.contains('/') || code.startsWith('INV') || code.startsWith('WOW')) {
                   _confirmByReceipt(code);
                } else {
                   _fetchBatch(code);
                }
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
                'Arahkan kamera ke barcode SJ atau Nota',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmByReceipt(String receiptNo) async {
    setState(() => _isLoading = true);
    try {
      await apiClient.client.post(
        'delivery/items/confirm-by-receipt',
        data: {'receipt_no': receiptNo, 'notes': 'Diterima via Scan Nota Universal'},
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nota $receiptNo berhasil dikonfirmasi!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      if (_batchData != null) {
        _fetchBatch(_batchData!['delivery_order_no']);
      } else {
        _fetchTasks();
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal konfirmasi nota: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showUpdateCashDialog(double currentCash) {
    final TextEditingController controller = TextEditingController(text: currentCash.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Uang Dibawa', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah Uang (Rp)',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context);
              _updateCash(amount);
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCash(double amount) async {
    if (_batchData == null) return;
    setState(() => _isLoading = true);
    try {
      await apiClient.client.post(
        'delivery/batch/${_batchData!['id']}/cash',
        data: {'amount': amount},
      );
      _fetchBatch(_batchData!['delivery_order_no']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update uang: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_shipping_outlined, size: 80, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Text(
            'Belum ada data pengiriman',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchDetail() {
    final items = _batchData!['items'] as List;
    final stores = items.map((i) => StoreModel.fromJson(i['sales_transaction']['store'])).toList();
    final deliveredCount = items.where((i) => i['status'] == 'DELIVERED').length;
    final progress = items.isEmpty ? 0.0 : deliveredCount / items.length;
    final totalCash = (_batchData!['total_cash_collected'] ?? 0.0).toDouble();

    return Column(
      children: [
        // Header Info
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              // Progress Section
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NOMOR SURAT JALAN', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 1)),
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
              const SizedBox(height: 16),
              // Cash Tracker Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.payments_rounded, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL UANG DIBAWA', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalCash),
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
                      onPressed: () => _showUpdateCashDialog(totalCash),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                margin: const EdgeInsets.only(bottom: 16),
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
                          Text(store['address'], style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
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
