import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCatalogPage extends StatelessWidget {
  const ProductCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Icon(Icons.menu_book_rounded, size: 250, color: Colors.white.withOpacity(0.05)),
                  ),
                ],
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PT WOWIN KECAP', style: GoogleFonts.outfit(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text('Katalog Produk', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProductCard(
                  context: context,
                  title: 'Kecap Manis Wowin Premium',
                  category: 'Kecap Manis',
                  description: 'Kecap manis legendaris dengan resep otentik sejak 1928. Dibuat dari kedelai hitam pilihan dan gula merah asli untuk menghasilkan rasa manis gurih yang kaya.',
                  imagePath: 'assets/kecap_manis_wowin_1777446817239.png',
                  sizes: ['Botol 300ml', 'Botol 600ml', 'Pouch 250ml', 'Pouch 520ml', 'Jerigen 6kg'],
                  color: const Color(0xFF451A03), // Dark brown
                ),
                const SizedBox(height: 24),
                _buildProductCard(
                  context: context,
                  title: 'Kecap Asin Wowin',
                  category: 'Kecap Asin',
                  description: 'Kecap asin dengan profil rasa gurih yang ringan dan seimbang. Sangat cocok untuk masakan tumis, marinasi daging, atau sebagai bumbu cocolan pelengkap hidangan.',
                  imagePath: 'assets/kecap_asin_wowin_1777446836873.png',
                  sizes: ['Botol 250ml', 'Botol 500ml', 'Jerigen 5kg'],
                  color: const Color(0xFFB45309), // Amber/light brown
                ),
                const SizedBox(height: 24),
                _buildProductCard(
                  context: context,
                  title: 'Saus Sambal Asli Wowin',
                  category: 'Saus & Bumbu',
                  description: 'Saus sambal pedas mantap yang diracik dari cabai merah segar pilihan. Menghadirkan sensasi pedas yang membakar dengan sedikit sentuhan rasa manis asam yang segar.',
                  imagePath: 'assets/saus_sambal_wowin_1777446854511.png',
                  sizes: ['Botol Kaca 300g', 'Botol Plastik 135ml', 'Sachet 9g'],
                  color: const Color(0xFFDC2626), // Red
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required String title,
    required String category,
    required String description,
    required String imagePath,
    required List<String> sizes,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Hero(
                      tag: title,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.blueGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tersedia dalam ukuran:',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sizes.map((size) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        size,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
