import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/injection.dart' as di;

class WarehouseDashboardPage extends StatefulWidget {
  const WarehouseDashboardPage({super.key});

  @override
  State<WarehouseDashboardPage> createState() => _WarehouseDashboardPageState();
}

class _WarehouseDashboardPageState extends State<WarehouseDashboardPage> with SingleTickerProviderStateMixin {
  final ApiClient apiClient = di.sl<ApiClient>();
  late TabController _tabController;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _inventory = [];
  List<dynamic> _filteredInventory = [];
  List<dynamic> _pendingInbound = [];
  List<dynamic> _pendingOutbound = [];
  List<dynamic> _salesRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchInventory(),
        _fetchPendingInbound(),
        _fetchPendingOutbound(),
        _fetchSalesRequests(),
      ]);
    } catch (e) {
      _showError('Gagal mengambil data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchInventory() async {
    final response = await apiClient.client.get('warehouse/stock');
    setState(() {
      _inventory = (response.data as List<dynamic>?) ?? [];
      _filteredInventory = _inventory;
    });
  }

  Future<void> _fetchPendingInbound() async {
    final response = await apiClient.client.get('warehouse/transfers/pending');
    setState(() {
      _pendingInbound = (response.data as List<dynamic>?) ?? [];
    });
  }

  Future<void> _fetchPendingOutbound() async {
    final response = await apiClient.client.get('sales/transactions/status/VERIFIED');
    setState(() {
      _pendingOutbound = (response.data as List<dynamic>?) ?? [];
    });
  }

  Future<void> _fetchSalesRequests() async {
    final response = await apiClient.client.get('sales-transfers/pending');
    setState(() {
      _salesRequests = (response.data as List<dynamic>?) ?? [];
    });
  }

  void _filterInventory(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInventory = _inventory;
      } else {
        _filteredInventory = _inventory.where((item) {
          final productName = (item['product']['name'] ?? '').toString().toLowerCase();
          final sku = (item['product']['sku'] ?? '').toString().toLowerCase();
          return productName.contains(query.toLowerCase()) || sku.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // --- LOGIC: RECEIVE FROM FACTORY ---
  Future<void> _processInboundScan(String doNo) async {
    setState(() => _isLoading = true);
    try {
      final response = await apiClient.client.get('warehouse/transfers/do/$doNo');
      final transfer = response.data;
      if (mounted) _showReceiveDialog(transfer, doNo);
    } catch (e) {
      _showError('Surat Jalan tidak ditemukan.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReceiveDialog(Map<String, dynamic> tr, String doNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Terima dari Pabrik', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No. SJ: $doNo', style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailBox(tr['product']['name'], '${tr['quantity']} ${tr['product']['unit']}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _confirmReceive(doNo); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('TERIMA'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReceive(String doNo) async {
    try {
      await apiClient.client.post('warehouse/transfers/do/$doNo/receive');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Barang berhasil masuk stok!'), backgroundColor: Colors.green));
      _fetchAllData();
    } catch (e) { _showError('Gagal: $e'); }
  }

  // --- LOGIC: DISPATCH FOR SALES (INVOICE) ---
  Future<void> _processOutboundScan(String receiptNo) async {
    setState(() => _isLoading = true);
    try {
      final response = await apiClient.client.get('sales/transactions/receipt/$receiptNo');
      final transaction = response.data;
      if (mounted) _showDispatchSheet(transaction);
    } catch (e) { _showError('Nota tidak valid.'); }
    finally { setState(() => _isLoading = false); }
  }

  void _showDispatchSheet(Map<String, dynamic> tr) {
    final items = tr['items'] as List<dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('Kirim ke Sales (Invoice)', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900)),
            Text('NOTA: ${tr['receipt_no']}', style: GoogleFonts.outfit(color: Colors.blue)),
            const Divider(height: 40),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final it = items[index];
                  return ListTile(
                    title: Text(it['product']['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('${it['quantity']} ${it['product']['unit']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _confirmDispatch(tr['receipt_no']); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('KONFIRMASI PENGELUARAN'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDispatch(String receiptNo) async {
    try {
      await apiClient.client.post('warehouse/dispatch/invoice/$receiptNo');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Barang berhasil dikirim!'), backgroundColor: Colors.green));
      _fetchAllData();
    } catch (e) { _showError('Gagal: $e'); }
  }

  // --- LOGIC: APPROVE SALES REQUEST ---
  Future<void> _processSalesRequestApproval(String id) async {
    setState(() => _isLoading = true);
    try {
      await apiClient.client.patch('sales-transfers/$id/complete');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Permintaan stok disetujui!'), backgroundColor: Colors.green));
      _fetchAllData();
    } catch (e) { _showError('Gagal menyetujui: $e'); }
    finally { setState(() => _isLoading = false); }
  }

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false, pinned: true, elevation: 0,
            backgroundColor: const Color(0xFF1E293B),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderSummary(),
              title: Text('Gudang Command Center', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.tealAccent,
              tabs: [
                const Tab(text: 'STOK'),
                _buildTabWithBadge('DARI PABRIK', _pendingInbound.length),
                _buildTabWithBadge('UNTUK SALES', _pendingOutbound.length),
                _buildTabWithBadge('REQ SALES', _salesRequests.length),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInventoryTab(),
            _buildGenericListTab(_pendingInbound, 'Tidak ada kiriman masuk', (it) => _processInboundScan(it['delivery_order_no']), true),
            _buildGenericListTab(_pendingOutbound, 'Tidak ada invoice pending', (it) => _processOutboundScan(it['receipt_no']), false),
            _buildGenericListTab(_salesRequests, 'Tidak ada permintaan stok', (it) => _processSalesRequestApproval(it['id']), false, isRequest: true),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScanChoiceMenu,
        backgroundColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: const Text('SCAN OPERASI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTabWithBadge(String label, int count) {
    return Tab(
      child: Badge(
        label: Text(count.toString()),
        isLabelVisible: count > 0,
        child: Text(label),
      ),
    );
  }

  Widget _buildHeaderSummary() {
    int lowStock = _inventory.where((item) => (item['quantity'] ?? 0) <= (item['min_limit'] ?? 0)).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      alignment: Alignment.topRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatBox('SKU', _inventory.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          _buildStatBox('LOW', lowStock.toString(), Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(val, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8)),
      ]),
    );
  }

  Widget _buildInventoryTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          onChanged: _filterInventory,
          decoration: InputDecoration(hintText: 'Cari barang...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _fetchAllData,
          child: _filteredInventory.isEmpty ? _buildEmpty('Data kosong') : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredInventory.length,
            itemBuilder: (context, index) {
              final item = _filteredInventory[index];
              final isLow = (item['quantity'] ?? 0) <= (item['min_limit'] ?? 0);
              return _buildInvCard(item, isLow);
            },
          ),
        ),
      ),
    ]);
  }

  Widget _buildInvCard(Map<String, dynamic> item, bool isLow) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: isLow ? Border.all(color: Colors.red.shade100) : null),
      child: Row(children: [
        Icon(Icons.inventory_2_rounded, color: isLow ? Colors.red : Colors.blue),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['product']['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('SKU: ${item['product']['sku']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ])),
        Text('${item['quantity']} ${item['product']['unit']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: isLow ? Colors.red : Colors.black)),
      ]),
    );
  }

  Widget _buildGenericListTab(List<dynamic> list, String emptyMsg, Function(dynamic) onTap, bool isInbound, {bool isRequest = false}) {
    if (list.isEmpty) return _buildEmpty(emptyMsg);
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final it = list[index];
          String title = isInbound ? it['delivery_order_no'] : (isRequest ? it['employee']['first_name'] : it['store']['name']);
          String subtitle = isInbound ? 'Dari: ${it['from_factory']['name']}' : (isRequest ? 'Minta: ${it['product']['name']}' : 'Nota: ${it['receipt_no']}');
          String trailing = isRequest ? '${it['quantity']} ${it['product']['unit']}' : '';

          return Card(
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(subtitle),
              trailing: isRequest ? Text(trailing, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange)) : const Icon(Icons.chevron_right),
              onTap: () => onTap(it),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String msg) => Center(child: Text(msg, style: const TextStyle(color: Colors.grey)));

  Widget _buildDetailBox(String name, String qty) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      ]),
    );
  }

  void _showScanChoiceMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildScanItem('Terima Surat Jalan Pabrik', Colors.teal, () { Navigator.pop(context); _openScanner((v) => _processInboundScan(v)); }),
          _buildScanItem('Kirim Nota Sales Motoris', Colors.orange, () { Navigator.pop(context); _openScanner((v) => _processOutboundScan(v)); }),
          _buildScanItem('Approve Permintaan Stok Sales', Colors.blue, () { Navigator.pop(context); _openScanner((v) => _processSalesRequestApproval(v)); }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildScanItem(String label, Color col, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: col, child: const Icon(Icons.qr_code_scanner, color: Colors.white)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  void _openScanner(Function(String) onResult) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.black,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
        body: MobileScanner(onDetect: (cap) {
          final bc = cap.barcodes.first.rawValue;
          if (bc != null) { Navigator.pop(context); onResult(bc); }
        }),
      ),
    );
  }
}
