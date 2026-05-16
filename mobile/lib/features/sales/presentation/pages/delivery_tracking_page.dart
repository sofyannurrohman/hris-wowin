import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hris_app/features/sales/presentation/pages/delivery_checkout_page.dart';
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
  final String? deliveryOrderNo;

  const DeliveryTrackingPage({
    super.key, 
    this.initialScan = false, 
    this.autoShowMap = false,
    this.deliveryOrderNo,
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
    if (widget.deliveryOrderNo != null) {
      _fetchBatch(widget.deliveryOrderNo!);
    } else if (widget.initialScan) {
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
        final List<StoreModel> stores = items.map((i) {
          final storeData = (i['sales_order'] != null) ? i['sales_order']['store'] : i['sales_transaction']['store'];
          return StoreModel.fromJson(storeData);
        }).toList();
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
            if (_isLoading) return; // Use existing _isLoading as a lock
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null) {
                if (code.startsWith('SJ-')) {
                   _fetchBatch(code);
                } else {
                   _openCheckoutForCode(code);
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

  Future<void> _openCheckoutForCode(String code) async {
    setState(() => _isLoading = true);
    
    // If we have a batch open, try to find the item in the batch
    if (_batchData != null) {
      final items = _batchData!['items'] as List;
      final matchedItem = items.cast<Map<String, dynamic>>().firstWhere(
        (item) {
          final soNumber = item['sales_order']?['so_number'];
          final invoiceNo = item['sales_transaction']?['invoice_no'];
          final itemId = item['id'];
          return soNumber == code || invoiceNo == code || itemId == code;
        },
        orElse: () => <String, dynamic>{},
      );

      if (matchedItem.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _isScanning = false;
        });
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryCheckoutPage(
              deliveryItem: matchedItem,
              onSuccess: () => _fetchBatch(_batchData!['delivery_order_no']),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data Nota tidak ditemukan di Surat Jalan ini. Silakan scan Surat Jalan utamanya terlebih dahulu.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final List<StoreModel> stores = items.map((i) {
      final storeData = (i['sales_order'] != null) ? i['sales_order']['store'] : i['sales_transaction']['store'];
      return StoreModel.fromJson(storeData);
    }).toList();
    final deliveredCount = items.where((i) => i['status'] == 'DELIVERED').length;
    final progress = items.isEmpty ? 0.0 : deliveredCount / items.length;
    final totalCash = (_batchData!['total_cash_collected'] ?? 0.0).toDouble();
    final totalTransfer = (_batchData!['total_transfer_collected'] ?? 0.0).toDouble();

    return RefreshIndicator(
      onRefresh: () => _fetchBatch(_batchData!['delivery_order_no']),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                // Collection Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildCollectionRow(
                        icon: Icons.payments_rounded,
                        color: Colors.green,
                        label: 'TOTAL TUNAI (CASH)',
                        amount: totalCash,
                        onEdit: () => _showUpdateCashDialog(totalCash),
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildCollectionRow(
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.blueAccent,
                        label: 'TOTAL TRANSFER (DIGITAL)',
                        amount: totalTransfer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildManifestSummary(items),
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

          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DAFTAR TOKO TUJUAN',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5),
                ),
                Text(
                  '${items.length} Outlet',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueAccent),
                ),
              ],
            ),
          ),

          // List of Stores
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final store = (item['sales_order'] != null) ? item['sales_order']['store'] : item['sales_transaction']['store'];
                final isDelivered = item['status'] == 'DELIVERED';
                final lat = store['latitude'];
                final lng = store['longitude'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: isDelivered ? Colors.green.withOpacity(0.2) : Colors.transparent),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryCheckoutPage(
                              deliveryItem: item,
                              onSuccess: () => _fetchBatch(_batchData!['delivery_order_no']),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                  Text(store['name'] ?? 'Toko Tanpa Nama', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                                  Text(store['address'] ?? 'Alamat tidak tersedia', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            if (lat != null && lng != null)
                              IconButton(
                                icon: const Icon(Icons.near_me_rounded, color: Colors.blueAccent, size: 24),
                                onPressed: () async {
                                  final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  }
                                },
                                tooltip: 'Navigasi ke Toko',
                              ),
                            if (!isDelivered)
                              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 16)
                            else
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCollectionRow({
    required IconData icon,
    required Color color,
    required String label,
    required double amount,
    VoidCallback? onEdit,
  }) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              Text(
                formatter.format(amount),
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 20),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _buildManifestSummary(List<dynamic> items) {
    Map<String, Map<String, dynamic>> manifest = {};
    int totalInitial = 0;
    int totalOnTruck = 0;

    for (var item in items) {
      final soItems = item['sales_order']?['items'] ?? [];
      final bool isDelivered = item['status'] == 'DELIVERED';
      
      for (var soItem in soItems) {
        final productName = soItem['product']?['name'] ?? 'Produk';
        final ordered = (soItem['ordered_quantity'] ?? 0) as int;
        final actual = (soItem['actual_quantity'] ?? ordered) as int;
        final ret = isDelivered ? (ordered - actual) : 0;
        
        // Stock on Truck calculation:
        // If pending: the whole 'ordered' quantity is still on truck.
        // If delivered: only the 'ret' (returned) quantity is back on truck.
        final currentOnTruck = isDelivered ? ret : ordered;

        if (!manifest.containsKey(productName)) {
          manifest[productName] = {
            'initial': 0, 
            'onTruck': 0, 
            'returned': 0,
            'uom': soItem['product']?['uom'] ?? 'Unit'
          };
        }
        manifest[productName]!['initial'] += ordered;
        manifest[productName]!['onTruck'] += currentOnTruck;
        manifest[productName]!['returned'] += ret;
        
        totalInitial += ordered;
        totalOnTruck += currentOnTruck;
      }
    }

    if (manifest.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'GUDANG BERJALAN (MANIFEST)',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1),
          ),
          subtitle: Text(
            'Sisa di Truk: $totalOnTruck item (Awal: $totalInitial)',
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blueGrey),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.blueAccent, size: 18),
          ),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  const Divider(height: 1),
                  ...manifest.entries.map((entry) {
                    final data = entry.value;
                    final hasRetur = data['returned'] > 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.key, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1E293B))),
                                Text(
                                  'Awal: ${data['initial']} ${data['uom']} ${hasRetur ? "• Retur: ${data['returned']}" : ""}',
                                  style: GoogleFonts.outfit(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${data['onTruck']} ${data['uom']}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15, color: data['onTruck'] > 0 ? Colors.blueAccent : Colors.grey),
                              ),
                              Text('DI TRUK', style: GoogleFonts.outfit(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
