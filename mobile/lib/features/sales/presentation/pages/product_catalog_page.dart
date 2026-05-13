import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/sales/data/models/product_model.dart';
import 'package:hris_app/features/sales/data/services/sales_api_service.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/database/database.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/sync/data/repositories/sync_repository.dart';
import 'package:intl/intl.dart';

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  final _apiService = SalesApiService(apiClient: di.sl<ApiClient>());
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final db = di.sl<AppDatabase>();
      
      // Pull latest from backend first (fails silently if offline)
      await di.sl<SyncRepository>().pullMasterData();
      
      final products = await db.select(db.products).get();
      if (mounted) {
        setState(() {
          _allProducts = products.map((p) => ProductModel(
            id: p.id,
            name: p.name,
            sellingPrice: p.sellingPrice,
            sku: p.sku ?? '',
            unit: p.unit ?? '',
            category: p.category ?? '',
            brand: 'Wowin',
            description: '',
            imageUrl: p.imageUrl ?? '',
            warehouseStock: p.warehouseStock,
          )).toList();
          _filteredProducts = List.from(_allProducts);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      final q = query.trim().toLowerCase();
      if (q == '') {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts = _allProducts
            .where((p) {
              final name = p.name.toLowerCase();
              final sku = p.sku.toLowerCase();
              final cat = p.category.toLowerCase();
              return name.contains(q) || sku.contains(q) || cat.contains(q);
            })
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light Slate
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        color: const Color(0xFF059669),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
              )
            else if (_error != null)
              _buildErrorState()
            else if (_filteredProducts.length == 0)
              _buildEmptyState()
            else
              _buildProductGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF064E3B), // Dark Wowin Green
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.inventory_2_rounded, size: 150, color: Colors.white.withOpacity(0.05)),
            ),
          ],
        ),
        title: Text(
          'KATALOG PRODUK',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 64),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama produk atau SKU...',
                hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey.shade300),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF059669)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildCompactProductCard(_filteredProducts[index]),
          childCount: _filteredProducts.length,
        ),
      ),
    );
  }

  Widget _buildCompactProductCard(ProductModel product) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    
    // Stock Status Logic
    Color stockColor = const Color(0xFF10B981); // Available
    String stockLabel = 'Tersedia';
    if (product.warehouseStock <= 0) {
      stockColor = const Color(0xFFEF4444); // Out of stock
      stockLabel = 'Habis';
    } else if (product.warehouseStock < 10) {
      stockColor = const Color(0xFFF59E0B); // Low stock
      stockLabel = 'Stok Menipis';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Image Section
          Expanded(
            flex: 12,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF8FAFC),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Hero(
                        tag: product.id,
                        child: (product.imageUrl != '')
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, size: 32, color: Colors.grey),
                              )
                            : const Icon(Icons.image_not_supported_outlined, size: 32, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        product.category,
                        style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info Section
          Expanded(
            flex: 11,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.sku,
                        style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(product.sellingPrice),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
                      ),
                      const SizedBox(height: 6),
                      // Stock Indicator
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$stockLabel (${product.warehouseStock})',
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: stockColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text('Gagal memuat produk', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchProducts,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.blueGrey.shade200, size: 64),
            const SizedBox(height: 16),
            Text('Produk tidak ditemukan', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), fontSize: 18)),
            const SizedBox(height: 8),
            Text('Coba kata kunci lain atau perbarui katalog', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}
