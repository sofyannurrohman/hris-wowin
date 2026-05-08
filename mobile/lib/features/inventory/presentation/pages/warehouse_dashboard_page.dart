import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
      if (response.data is Map && response.data.containsKey('data')) {
        _inventory = (response.data['data'] as List<dynamic>?) ?? [];
      } else {
        _inventory = (response.data as List<dynamic>?) ?? [];
      }
      _filteredInventory = _inventory;
    });
  }

  Future<void> _fetchPendingInbound() async {
    final response = await apiClient.client.get('warehouse/transfers/pending');
    setState(() {
      if (response.data is Map && response.data.containsKey('data')) {
        _pendingInbound = (response.data['data'] as List<dynamic>?) ?? [];
      } else {
        _pendingInbound = (response.data as List<dynamic>?) ?? [];
      }
    });
  }

  Future<void> _fetchPendingOutbound() async {
    final response = await apiClient.client.get('sales/transactions/status/VERIFIED');
    setState(() {
      if (response.data is Map && response.data.containsKey('data')) {
        _pendingOutbound = (response.data['data'] as List<dynamic>?) ?? [];
      } else {
        _pendingOutbound = (response.data as List<dynamic>?) ?? [];
      }
    });
  }

  Future<void> _fetchSalesRequests() async {
    final response = await apiClient.client.get('sales-transfers/pending');
    setState(() {
      if (response.data is Map && response.data.containsKey('data')) {
        _salesRequests = (response.data['data'] as List<dynamic>?) ?? [];
      } else {
        _salesRequests = (response.data as List<dynamic>?) ?? [];
      }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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

  // --- UTILS ---
  String _formatStock(dynamic qty, dynamic product) {
    if (qty == null) return '0';
    final q = qty is num ? qty : double.tryParse(qty.toString()) ?? 0;
    final p = product ?? {};
    final unit = (p['unit'] ?? 'Unit').toString();
    final itemsPerUnit = p['items_per_unit'] ?? p['pcs_per_unit'] ?? 0;

    if (itemsPerUnit > 1) {
      final major = (q / itemsPerUnit).floor();
      final pcs = (q % itemsPerUnit).toInt();
      
      List<String> parts = [];
      if (major > 0) parts.add('$major $unit');
      if (pcs > 0) parts.add('$pcs Pcs');
      
      return parts.isEmpty ? '0 Pcs' : parts.join(' ');
    }
    
    return '$q $unit';
  }

  void _showReceiveDialog(Map<String, dynamic> tr, String doNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(Icons.download_for_offline_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Text('Terima Barang', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfirmasi penerimaan barang dari pabrik dengan nomor Surat Jalan:', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withOpacity(0.2))),
              child: Text(doNo, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            _buildDetailBox(tr['product']?['name'] ?? 'Produk Tidak Diketahui', '${tr['quantity'] ?? 0} ${tr['product']?['unit'] ?? 'Unit'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('BATAL', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textTertiary))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _confirmReceive(doNo); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(120, 48)),
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
      Map<String, dynamic> transaction;
      if (response.data is Map && response.data.containsKey('data')) {
        transaction = response.data['data'];
      } else {
        transaction = response.data;
      }
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
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grayBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Kirim ke Sales (Invoice)', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('NOTA: ${tr['receipt_no']}', style: GoogleFonts.plusJakartaSans(color: AppColors.info, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.grayLight),
                itemBuilder: (context, index) {
                  final it = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.grayLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        Expanded(child: Text(it['product']?['name'] ?? 'Produk', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                        Text('${it['quantity'] ?? 0} ${it['product']?['unit'] ?? 'Unit'}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _confirmDispatch(tr['receipt_no']); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(double.infinity, 64)),
                child: const Text('KONFIRMASI PENGELUARAN'),
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
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            floating: false, pinned: true, elevation: 0,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('ADMINISTRASI GUDANG', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderContent(),
              collapseMode: CollapseMode.pin,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryRed,
                  indicatorWeight: 4,
                  labelColor: AppColors.primaryRed,
                  unselectedLabelColor: AppColors.textTertiary,
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: [
                    const Tab(text: 'INVENTORY'),
                    _buildTabWithBadge('INBOUND', _pendingInbound.length),
                    _buildTabWithBadge('OUTBOUND', _pendingOutbound.length + _salesRequests.length),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Container(
          color: Colors.white,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInventoryTab(),
              _buildInboundTab(),
              _buildOutboundTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScanChoiceMenu,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: Text('SCAN OPERASI', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildTabWithBadge(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(10)),
              child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    int lowStock = _inventory.where((item) => (item['quantity'] ?? 0) <= (item['min_limit'] ?? 0)).length;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildSummaryCard('TOTAL SKU', _inventory.length.toString(), Icons.category_rounded, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('LOW STOCK', lowStock.toString(), Icons.warning_amber_rounded, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('PENDING', (_pendingInbound.length + _pendingOutbound.length + _salesRequests.length).toString(), Icons.pending_actions_rounded, Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          Text(label, style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 7, letterSpacing: 0.2)),
        ],
      ),
    );
  }


  Widget _buildInventoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: TextField(
            controller: _searchController,
            onChanged: _filterInventory,
            decoration: InputDecoration(
              hintText: 'Cari barang di gudang...',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAllData,
            color: AppColors.primaryRed,
            child: _filteredInventory.isEmpty 
                ? _buildEmptyState(Icons.inventory_2_outlined, 'Belum ada data barang')
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredInventory.length,
                    itemBuilder: (context, index) {
                      final item = _filteredInventory[index];
                      final qty = (item['quantity'] ?? 0);
                      final min = (item['min_limit'] ?? 0);
                      final isLow = qty <= min;
                      final isOut = qty <= 0;
                      
                      return _buildInventoryCard(item, isLow, isOut);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item, bool isLow, bool isOut) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isOut ? AppColors.error.withOpacity(0.2) : (isLow ? Colors.orange.withOpacity(0.2) : AppColors.grayBorder)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOut ? AppColors.error.withOpacity(0.1) : (isLow ? Colors.orange.withOpacity(0.1) : AppColors.grayLight),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOut ? Icons.block_flipped : (isLow ? Icons.warning_amber_rounded : Icons.inventory_2_rounded),
              color: isOut ? AppColors.error : (isLow ? Colors.orange : AppColors.textSecondary),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['product']?['name'] ?? 'Produk Tanpa Nama', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('SKU: ${item['product']?['sku'] ?? '-'}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                    if (item['product'] != null && (item['product']['items_per_unit'] != null || item['product']['pcs_per_unit'] != null)) ...[
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.grayBorder, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('1 ${item['product']['unit'] ?? 'Unit'} = ${item['product']['items_per_unit'] ?? item['product']['pcs_per_unit']} Pcs', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatStock(item['quantity'], item['product']), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16, color: isOut ? AppColors.error : (isLow ? Colors.orange : AppColors.textPrimary))),
              Text('STOK AKTIF', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInboundTab() {
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      color: AppColors.primaryRed,
      child: _pendingInbound.isEmpty
          ? _buildEmptyState(Icons.download_for_offline_outlined, 'Semua kiriman pabrik sudah diterima')
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _pendingInbound.length,
              itemBuilder: (context, index) {
                final it = _pendingInbound[index];
                return _buildTaskCard(
                  title: it['delivery_order_no'] ?? 'NO DO',
                  subtitle: 'Dari: ${it['from_factory']?['name'] ?? 'Pabrik'}',
                  type: 'PABRIK',
                  date: it['created_at'] ?? DateTime.now().toIso8601String(),
                  color: AppColors.success,
                  onTap: () => _processInboundScan(it['delivery_order_no'] ?? ''),
                );
              },
            ),
    );
  }

  Widget _buildOutboundTab() {
    final allOutbound = [..._pendingOutbound, ..._salesRequests];
    
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      color: AppColors.primaryRed,
      child: allOutbound.isEmpty
          ? _buildEmptyState(Icons.upload_file_rounded, 'Tidak ada pengeluaran barang pending')
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: allOutbound.length,
              itemBuilder: (context, index) {
                final it = allOutbound[index];
                final isRequest = it.containsKey('employee'); // sales request has employee
                
                return _buildTaskCard(
                  title: isRequest ? (it['employee']?['first_name'] ?? 'Sales').toUpperCase() : (it['store']?['name'] ?? 'Toko').toUpperCase(),
                  subtitle: isRequest ? 'Request: ${it['product']?['name'] ?? 'Produk'}' : 'Kirim Nota: ${it['receipt_no'] ?? '-'}',
                  type: isRequest ? 'STOK SALES' : 'SALES ORDER',
                  date: it['created_at'] ?? DateTime.now().toIso8601String(),
                  color: isRequest ? Colors.deepOrange : AppColors.info,
                  trailing: isRequest ? _formatStock(it['quantity'], it['product']) : null,
                  onTap: () => isRequest 
                      ? _processSalesRequestApproval(it['id'])
                      : _openScanner((v) => _processOutboundScan(v)),
                );
              },
            ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required String type,
    required String date,
    required Color color,
    String? trailing,
    required VoidCallback onTap,
  }) {
    final formattedDate = DateFormat('dd MMM, HH:mm').format(DateTime.parse(date));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grayBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(type, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 10),
                        Text(formattedDate, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (trailing != null)
                Text(trailing, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15, color: color))
              else
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.grayBorder),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDetailBox(String name, String qty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.grayLight, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          Text(qty, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppColors.info, fontSize: 16)),
        ],
      ),
    );
  }

  void _showScanChoiceMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grayBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('OPERASI GUDANG', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1)),
              const SizedBox(height: 20),
              _buildScanItem('Terima Surat Jalan Pabrik', AppColors.success, Icons.download_for_offline_rounded, () { 
                Navigator.pop(context); 
                _openScanner((v) => _processInboundScan(v)); 
              }),
              const SizedBox(height: 12),
              _buildScanItem('Kirim Nota Sales Motoris', AppColors.info, Icons.upload_file_rounded, () { 
                Navigator.pop(context); 
                _openScanner((v) => _processOutboundScan(v)); 
              }),
              const SizedBox(height: 12),
              _buildScanItem('Approve Stok Sales', Colors.orange, Icons.fact_check_rounded, () { 
                Navigator.pop(context); 
                _openScanner((v) => _processSalesRequestApproval(v)); 
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanItem(String label, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _openScanner(Function(String) onResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (cap) {
                final bc = cap.barcodes.first.rawValue;
                if (bc != null) {
                  Navigator.pop(context);
                  onResult(bc);
                }
              },
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
