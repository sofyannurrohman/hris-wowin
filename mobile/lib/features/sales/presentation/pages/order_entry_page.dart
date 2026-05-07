import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:intl/intl.dart';
import 'package:hris_app/core/database/database.dart';
import './visit_checkout_page.dart';

class OrderEntryPage extends StatefulWidget {
  final StoreModel store;
  final String selfiePath;
  final String companyId;
  final String companyName;

  const OrderEntryPage({
    super.key,
    required this.store,
    required this.selfiePath,
    required this.companyId,
    required this.companyName,
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
  final Map<String, int> _cart = {}; // productId -> quantity
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // Fetch from local Drift DB
      final products = await (db.select(db.products)
          ..where((t) => t.companyId.equals(widget.companyId))).get();
      
      if (mounted) {
        setState(() {
          _allProducts = products.map((p) => {
            'id': p.id,
            'name': p.name,
            'selling_price': p.sellingPrice,
            'sku': p.sku,
            'unit': p.unit,
          }).toList();
          _filteredProducts = _allProducts;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat produk lokal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts = _allProducts.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final sku = (p['sku'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) || sku.contains(query.toLowerCase());
      }).toList();
    });
  }

  double get _totalAmount {
    double total = 0;
    _cart.forEach((id, qty) {
      final product = _allProducts.firstWhere((p) => p['id'] == id);
      total += (product['selling_price'] ?? 0) * qty;
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
            Text('Input Pesanan', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: Colors.white,
            child: Text(
              'Entitas: ${widget.companyName}',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
          _buildSearchBar(),
          Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildProductList()),
          _buildBottomSummary(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: TextField(
        onChanged: _filterProducts,
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] ?? 'Unknown Product', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B))),
                    Text('SKU: ${p['sku'] ?? '-'}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey)),
                    const SizedBox(height: 4),
                    Text(_currency.format(p['selling_price'] ?? 0), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 14)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: qty > 0 ? () => setState(() => _cart[id] = qty - 1) : null,
                      icon: Icon(Icons.remove_circle_outline_rounded, color: qty > 0 ? Colors.redAccent : Colors.grey, size: 20),
                    ),
                    Text('$qty', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B))),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _cart[id] = qty + 1),
                      icon: const Icon(Icons.add_circle_rounded, color: Colors.green, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                  Text('Total Pesanan:', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                  Text(_currency.format(_totalAmount), style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('${_cart.values.fold(0, (sum, q) => sum + q)} Item', style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.w800, fontSize: 12)),
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

  void _proceedToCheckout() {
    final List<Map<String, dynamic>> items = [];
    _cart.forEach((id, qty) {
      if (qty > 0) {
        final p = _allProducts.firstWhere((prod) => prod['id'] == id);
        items.add({
          'product_id': id,
          'quantity': qty,
          'price': p['selling_price'],
          'product_name': p['name'],
        });
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisitCheckoutPage(
          store: widget.store,
          selfiePath: widget.selfiePath,
          companyId: widget.companyId,
          companyName: widget.companyName,
          items: items,
          totalAmount: _totalAmount,
          receiptPath: null,
        ),
      ),
    );
  }
}
