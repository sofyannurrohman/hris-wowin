import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:intl/intl.dart';
import 'package:hris_app/core/database/database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:drift/drift.dart' hide Column;
import './visit_checkout_page.dart';
import 'package:hris_app/features/sync/data/repositories/sync_repository.dart';

class OrderEntryPage extends StatefulWidget {
  final StoreModel store;
  final String selfiePath;
  final Uint8List? selfieBytes;
  final String companyId;
  final String companyName;
  final String jobPositionTitle;

  const OrderEntryPage({
    super.key,
    required this.store,
    required this.selfiePath,
    this.selfieBytes,
    required this.companyId,
    required this.companyName,
    required this.jobPositionTitle,
  });

  @override
  State<OrderEntryPage> createState() => _OrderEntryPageState();
}

class _OrderEntryPageState extends State<OrderEntryPage> {
  final ApiClient apiClient = di.sl<ApiClient>();
  final AppDatabase db = di.sl<AppDatabase>();
  final NumberFormat _currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';
  
  final Map<String, int> _cart = {};
  final Map<String, TextEditingController> _bulkQtyControllers = {};
  final Map<String, TextEditingController> _looseQtyControllers = {};
  final Map<String, TextEditingController> _bulkUnitNameControllers = {};
  final Map<String, TextEditingController> _baseUnitNameControllers = {};
  final Map<String, TextEditingController> _multiplierControllers = {};
  
  List<String> _unitOptions = [];
  
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _unitOptions = ['PCS', 'KRT', 'KARDUS', 'BAL', 'KRAT', 'PACK', 'LUSIN', 'BOX', 'BTL', 'SCH', 'CRT'];
    _bulkQtyControllers.clear();
    _looseQtyControllers.clear();
    _bulkUnitNameControllers.clear();
    _baseUnitNameControllers.clear();
    _multiplierControllers.clear();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (var ctrl in _bulkQtyControllers.values) ctrl.dispose();
    for (var ctrl in _looseQtyControllers.values) ctrl.dispose();
    for (var ctrl in _bulkUnitNameControllers.values) ctrl.dispose();
    for (var ctrl in _baseUnitNameControllers.values) ctrl.dispose();
    for (var ctrl in _multiplierControllers.values) ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      try {
        await di.sl<SyncRepository>().pullMasterData();
      } catch (e) {
        print('DEBUG: pullMasterData failed or offline: $e');
      }

      var companyProducts = await (db.select(db.products)
          ..where((t) => t.companyId.equals(widget.companyId))).get();
      
      final stocks = await db.select(db.salesStock).get();

      final pendingTrxs = await (db.select(db.localTransactions)
          ..where((t) => t.syncStatus.equals('pending'))).get();
      final pendingLocalIds = pendingTrxs.map((t) => t.localId).toList();
      final Map<String, int> pendingReduction = {};
      
      if (pendingLocalIds.isNotEmpty) {
        final pendingItems = await (db.select(db.localTransactionItems)
            ..where((t) => t.transactionLocalId.isIn(pendingLocalIds))).get();
        for (var item in pendingItems) {
          pendingReduction[item.productId] = (pendingReduction[item.productId] ?? 0) + item.quantity;
        }
      }

      final stockProductIds = stocks.map((s) => s.productId).toList();
      
      var products = List<Product>.from(companyProducts);
      if (stockProductIds.isNotEmpty) {
        var stockProducts = await (db.select(db.products)
            ..where((t) => t.id.isIn(stockProductIds))).get();
            
        final Map<String, Product> productMap = {for (var p in products) p.id: p};
        for (var p in stockProducts) {
          productMap[p.id] = p;
        }
        products = productMap.values.toList();
      }

      if (products.isEmpty) {
        products = await db.select(db.products).get();
      }
      
      final Map<String, int> stockMap = {
        for (var s in stocks) 
          s.productId: (s.quantity - (pendingReduction[s.productId] ?? 0)).clamp(0, 999999)
      };

      if (mounted) {
        final cats = products.map((p) => p.category ?? 'Uncategorized').toSet().toList();
        cats.sort();
        
        setState(() {
          _allProducts = products.map((p) => {
            'id': p.id,
            'name': p.name,
            'selling_price': p.sellingPrice,
            'sku': p.sku,
            'unit': p.unit,
            'pcs_per_unit': p.pcsPerUnit,
            'category': p.category ?? 'Uncategorized',
            'stock': stockMap[p.id] ?? 0,
          }).toList();
          _categories = ['Semua', ...cats];
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat produk: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesSearch = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || 
                              p['sku'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'Semua' || p['category'] == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _loadLastOrder() async {
    setState(() => _isLoading = true);
    try {
      final lastTxn = await (db.select(db.localTransactions)
        ..where((t) => t.storeId.equals(widget.store.id))
        ..where((t) => t.companyId.equals(widget.companyId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
        ..limit(1)).getSingleOrNull();

      if (lastTxn != null) {
        final items = await (db.select(db.localTransactionItems)
          ..where((t) => t.transactionLocalId.equals(lastTxn.localId))).get();
        
        if (mounted) {
          setState(() {
            _cart.clear();
            for (final item in items) {
              final id = item.productId;
              final qty = item.quantity;
              _cart[id] = qty;
              
              if (_bulkQtyControllers.containsKey(id)) {
                _bulkQtyControllers[id]!.text = (qty ~/ item.piecesPerUnit).toString();
              }
              if (_looseQtyControllers.containsKey(id)) {
                _looseQtyControllers[id]!.text = (qty % item.piecesPerUnit).toString();
              }
              if (_bulkUnitNameControllers.containsKey(id)) {
                _bulkUnitNameControllers[id]!.text = item.unit;
              }
              if (_multiplierControllers.containsKey(id)) {
                _multiplierControllers[id]!.text = item.piecesPerUnit.toString();
              }
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✓ Berhasil menyalin pesanan terakhir!'),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada riwayat pesanan untuk toko ini.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat riwayat: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Scan Barcode Produk', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    if (code != null) {
                      Navigator.pop(context);
                      setState(() {
                        _searchCtrl.text = code;
                        _searchQuery = code;
                        _applyFilters();
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  double get _totalAmount {
    double total = 0;
    _cart.forEach((id, qty) {
      final product = _allProducts.firstWhere((p) => p['id'] == id, orElse: () => <String, dynamic>{});
      if (product.isNotEmpty) {
        total += (product['selling_price'] ?? 0) * qty;
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            Text('LANGKAH 4 DARI 5', style: GoogleFonts.outfit(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text('Input Pesanan Digital', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
            onPressed: _fetchProducts,
          ),
          TextButton.icon(
            onPressed: _loadLastOrder,
            icon: const Icon(Icons.history_rounded, size: 18, color: Colors.blueAccent),
            label: Text('PESAN ULANG', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueAccent)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: Text('Entitas: ${widget.companyName}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                Text(widget.store.name, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
              ],
            ),
          ),
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildProductList()),
          _buildBottomSummary(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                _searchQuery = val;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Cari nama produk atau SKU...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _openScanner,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: ChoiceChip(
              label: Text(cat, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? Colors.white : Colors.blueGrey)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = cat;
                  _applyFilters();
                });
              },
              selectedColor: Colors.blueAccent,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide.none,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Text('Produk tidak ditemukan', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final p = _filteredProducts[index];
        final id = p['id'];
        final qty = _cart[id] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] ?? 'Unknown Product', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B))),
                        Text('SKU: ${p['sku'] ?? '-'} • ${p['category']}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currency.format(p['selling_price'] ?? 0), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: (p['stock'] as int) > 0 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          (p['stock'] as int) > 0 ? 'Stok: ${p['stock']}' : 'Katalog',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: (p['stock'] as int) > 0 ? Colors.green : Colors.orange.shade800)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              _buildDualInputRow(
                productId: id,
                qty: qty,
                p: p,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDualInputRow({
    required String productId,
    required int qty,
    required Map<String, dynamic> p,
  }) {
    final multiplier = int.tryParse(_multiplierControllers[productId]?.text ?? '1') ?? 1;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _buildMiniBtn(Icons.remove, () => _updateDualQty(productId, -1, true, multiplier)),
                  Expanded(
                    child: TextField(
                      controller: _getBulkQtyCtrl(productId, qty, multiplier),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (val) => _onQtyTyped(productId),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B)),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                    ),
                  ),
                  _buildMiniBtn(Icons.add, () => _updateDualQty(productId, 1, true, multiplier), isPlus: true),
                  const SizedBox(width: 4),
                  _buildSmallUnitDropdown(productId, _getBulkUnitNameCtrl(productId, p['unit'])),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('@', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(
                    width: 25,
                    child: TextField(
                      controller: _getMultiplierCtrl(productId, p['pcs_per_unit']),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (val) => _onQtyTyped(productId),
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange.shade800),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, indent: 8, endIndent: 8, color: Color(0xFFE2E8F0)),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _getLooseQtyCtrl(productId, qty, multiplier),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (val) => _onQtyTyped(productId),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B)),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                    ),
                  ),
                  Text('PCS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueGrey)),
                  _buildMiniBtn(Icons.add, () => _updateDualQty(productId, 1, false, multiplier), isPlus: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDualQty(String productId, int delta, bool isBulk, int multiplier) {
    final currentTotal = _cart[productId] ?? 0;
    int bulk = currentTotal ~/ (multiplier > 0 ? multiplier : 1);
    int loose = currentTotal % (multiplier > 0 ? multiplier : 1);

    if (isBulk) {
      bulk = (bulk + delta).clamp(0, 9999);
    } else {
      loose = (loose + delta).clamp(0, 9999);
    }

    final newTotal = (bulk * multiplier) + loose;
    setState(() {
      _cart[productId] = newTotal;
      _bulkQtyControllers[productId]?.text = bulk.toString();
      _looseQtyControllers[productId]?.text = loose.toString();
    });
  }

  Widget _buildSmallUnitDropdown(String productId, TextEditingController unitCtrl) {
    final currentUnit = unitCtrl.text.toUpperCase();
    final List<String> options = List.from(_unitOptions);
    if (!options.contains(currentUnit)) options.add(currentUnit);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentUnit,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 10, color: Colors.blueAccent),
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueAccent),
        onChanged: (val) {
          if (val != null) setState(() { unitCtrl.text = val; });
        },
        items: options.map((v) => DropdownMenuItem(value: v, child: Text(v, style: GoogleFonts.outfit(fontSize: 10)))).toList(),
      ),
    );
  }

  Widget _buildMiniBtn(IconData icon, VoidCallback onTap, {bool isPlus = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: isPlus ? Colors.blueAccent.withOpacity(0.05) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 12, color: isPlus ? Colors.blueAccent : const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Pesanan Digital:', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                  Text(_currency.format(_totalAmount), style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('${_cart.values.fold(0, (sum, q) => sum + q)} Item', style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _cart.values.any((q) => q > 0) ? _proceedToCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text('LANJUT KE CHECKOUT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController _getBulkQtyCtrl(String productId, int totalPcs, int multiplier) {
    if (!_bulkQtyControllers.containsKey(productId)) {
      final bulkQty = totalPcs ~/ (multiplier > 0 ? multiplier : 1);
      _bulkQtyControllers[productId] = TextEditingController(text: bulkQty > 0 ? '$bulkQty' : '0');
    }
    return _bulkQtyControllers[productId]!;
  }

  TextEditingController _getLooseQtyCtrl(String productId, int totalPcs, int multiplier) {
    if (!_looseQtyControllers.containsKey(productId)) {
      final looseQty = totalPcs % (multiplier > 0 ? multiplier : 1);
      _looseQtyControllers[productId] = TextEditingController(text: looseQty > 0 ? '$looseQty' : '0');
    }
    return _looseQtyControllers[productId]!;
  }

  TextEditingController _getBulkUnitNameCtrl(String productId, String? defaultUnit) {
    if (!_bulkUnitNameControllers.containsKey(productId)) {
      _bulkUnitNameControllers[productId] = TextEditingController(text: defaultUnit ?? 'KRT');
    }
    return _bulkUnitNameControllers[productId]!;
  }

  TextEditingController _getBaseUnitNameCtrl(String productId) {
    if (!_baseUnitNameControllers.containsKey(productId)) {
      _baseUnitNameControllers[productId] = TextEditingController(text: 'PCS');
    }
    return _baseUnitNameControllers[productId]!;
  }

  TextEditingController _getMultiplierCtrl(String productId, int defaultMultiplier) {
    if (!_multiplierControllers.containsKey(productId)) {
      _multiplierControllers[productId] = TextEditingController(text: '$defaultMultiplier');
    }
    return _multiplierControllers[productId]!;
  }

  void _onQtyTyped(String productId) {
    final multiplier = int.tryParse(_multiplierControllers[productId]?.text ?? '1') ?? 1;
    final bulkStr = _bulkQtyControllers[productId]?.text ?? '0';
    final looseStr = _looseQtyControllers[productId]?.text ?? '0';
    final bulk = int.tryParse(bulkStr) ?? 0;
    final loose = int.tryParse(looseStr) ?? 0;
    setState(() {
      _cart[productId] = (bulk * multiplier) + loose;
    });
  }

  void _proceedToCheckout() {
    final List<Map<String, dynamic>> items = [];
    _cart.forEach((id, qty) {
      if (qty > 0) {
        final p = _allProducts.firstWhere((prod) => prod['id'] == id);
        final bulkUnit = _bulkUnitNameControllers[id]?.text ?? 'KRT';
        final baseUnit = _baseUnitNameControllers[id]?.text ?? 'PCS';
        final multiplier = int.tryParse(_multiplierControllers[id]?.text ?? '1') ?? 1;
        final bulkQty = qty ~/ (multiplier > 0 ? multiplier : 1);
        final looseQty = qty % (multiplier > 0 ? multiplier : 1);
        String displayUnit = baseUnit;
        int orderedQty = qty;
        if (multiplier > 1 && bulkQty > 0) {
          displayUnit = bulkUnit;
          orderedQty = bulkQty;
        }
        items.add({
          'product_id': id,
          'quantity': qty,
          'ordered_quantity': orderedQty,
          'unit': displayUnit,
          'pieces_per_unit': multiplier,
          'price': p['selling_price'],
          'product_name': p['name'],
          'breakdown': multiplier > 1 
              ? '$bulkQty $bulkUnit + $looseQty $baseUnit' 
              : '$qty $baseUnit',
        });
      }
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisitCheckoutPage(
          store: widget.store,
          selfiePath: widget.selfiePath,
          selfieBytes: widget.selfieBytes,
          companyId: widget.companyId,
          companyName: widget.companyName,
          items: items,
          totalAmount: _totalAmount,
          receiptPath: null,
          jobPositionTitle: widget.jobPositionTitle,
        ),
      ),
    );
  }
}
