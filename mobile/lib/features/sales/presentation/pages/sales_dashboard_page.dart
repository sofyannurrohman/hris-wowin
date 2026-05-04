import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../widgets/senior_button.dart';
import './select_store_page.dart';
import './sales_history_page.dart';
import './visit_finalization_page.dart';
import './store_list_page.dart';
import './order_banner_page.dart';
import './route_planning_page.dart';
import './product_catalog_page.dart';
import './visit_schedule_page.dart';

import 'package:hris_app/features/sales/data/services/sales_api_service.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/network/api_client.dart';

class SalesDashboardPage extends StatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
  final _apiService = SalesApiService(apiClient: di.sl<ApiClient>());
  bool _isLoading = true;
  
  Map<String, dynamic>? _kpiData;
  List<dynamic> _pendingTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final kpi = await _apiService.getMyPerformance();
      final pending = await _apiService.getPendingTransactions();
      setState(() {
        _kpiData = kpi;
        _pendingTransactions = pending;
      });
    } catch (e) {
      debugPrint('Error fetching sales data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Classy Light Gray
      appBar: AppBar(
        title: Text(
          'SALES DASHBOARD',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'KE HRIS',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primaryRed),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    _buildTargetCard(),
                    const SizedBox(height: 32),
                    _buildVisitProgressCard(),
                    const SizedBox(height: 32),
                    _buildQuickAccess(),
                    const SizedBox(height: 40),
                    _buildFinalizationReport(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildTargetCard() {
    final targetOmzet = _kpiData?['items']?[0]?['score'] ?? 0.0;
    final achievedOmzet = _kpiData?['items']?[1]?['score'] ?? 0.0;
    final achievementPercentage = _kpiData?['achievement_percentage'] ?? 0.0;
    final sisa = targetOmzet - achievedOmzet;

    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.trending_up_rounded, size: 150, color: Colors.blueAccent.withOpacity(0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.auto_graph_rounded, color: Colors.blueAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PERFORMA OMZET',
                      style: GoogleFonts.outfit(color: Colors.blueGrey, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatter.format(targetOmzet),
                    style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 34),
                  ),
                ),
                Text(
                  'Target ditugaskan atasan',
                  style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildStatItem('Realisasi', formatter.format(achievedOmzet), Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatItem('Sisa', formatter.format(sisa < 0 ? 0 : sisa), AppColors.primaryRed)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatItem('Pencapaian', '${achievementPercentage.toStringAsFixed(1)}%', Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: targetOmzet > 0 ? (achievedOmzet / targetOmzet).clamp(0.0, 1.0) : 0,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildVisitProgressCard() {
    // We calculate this based on _pendingTransactions vs a hypothetical total
    // But since we have the new VisitPlan API, ideally we'd fetch it here too.
    // For now, let's show a beautiful summary card that links to VisitSchedulePage.
    
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VisitSchedulePage())),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('JADWAL KUNJUNGAN', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('Lihat Rencana Hari Ini', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Tetap on-track dengan rute PJP Anda.', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 1)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ),
      ],
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AKSES OPERASIONAL',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
          children: [
            _buildActionItem(Icons.storefront_rounded, 'Kunjungan', const Color(0xFF3B82F6)),
            _buildActionItem(Icons.shopping_cart_checkout_rounded, 'Buat Order', const Color(0xFF10B981)),
            _buildActionItem(Icons.view_list_rounded, 'Daftar Toko', const Color(0xFF6366F1)),
            _buildActionItem(Icons.menu_book_rounded, 'Katalog', const Color(0xFFEC4899)),
            _buildActionItem(Icons.art_track_rounded, 'Order Spanduk', const Color(0xFF8B5CF6)),
            _buildActionItem(Icons.history_edu_rounded, 'Riwayat', const Color(0xFFF59E0B)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        if (label == 'Kunjungan') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VisitSchedulePage()));
        } else if (label == 'Buat Order') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectStorePage(isQuickOrder: true)));
        } else if (label == 'Daftar Toko') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreListPage()));
        } else if (label == 'Katalog') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductCatalogPage()));
        } else if (label == 'Riwayat') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalesHistoryPage()));
        } else if (label == 'Order Spanduk') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderBannerPage()));
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizationReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FINALISASI LAPORAN',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5),
            ),
            Text(
              'Hari Ini',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blueAccent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            children: [
              if (_pendingTransactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Belum ada data kunjungan yang harus difinalisasi.', style: GoogleFonts.outfit(color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                )
              else
                ..._pendingTransactions.map((txn) {
                  final storeName = txn['store']?['name'] ?? 'Toko Tidak Diketahui';
                  final amount = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(txn['total_amount'] ?? 0);
                  final time = DateFormat('HH:mm').format(DateTime.parse(txn['created_at']));
                  final isVerified = txn['status'] == 'VERIFIED';
                  
                  return Column(
                    children: [
                      _buildFinalizationItem(storeName, amount, time, isVerified, notes: txn['notes'],
                        onTap: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => VisitFinalizationPage(
                            storeName: storeName, 
                            transactionId: txn['id'],
                            receiptPath: txn['receipt_image_url'],
                            notes: txn['notes'],
                          )));
                          if (result == true) {
                            _fetchData(); // reload on success
                          }
                        }
                      ),
                      const Divider(height: 1, indent: 32, endIndent: 32),
                    ],
                  );
                }),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SeniorButton(
                  text: 'SUBMIT SEMUA DATA',
                  icon: Icons.send_rounded,
                  color: AppColors.primaryRed,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinalizationItem(String store, String amount, String time, bool isVerified, {String? notes, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.receipt_long_rounded, color: isVerified ? Colors.blueAccent : Colors.orange, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text('Scan pada pukul $time', style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.w500)),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Alasan: $notes', 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVerified ? 'AUTO-FILL OK' : 'NEED REVIEW',
                    style: GoogleFonts.outfit(color: isVerified ? Colors.green : Colors.orange, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32))),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'SALES OPERATION',
                  style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text(
                  'PT Wowin Purnomo',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildDrawerItem(Icons.storefront_rounded, 'Daftar Toko', () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreListPage()));
                }),
                _buildDrawerItem(Icons.map_rounded, 'Rute Optimal', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutePlanningPage()));
                }),
                _buildDrawerItem(Icons.menu_book_rounded, 'Katalog Produk Kecap', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductCatalogPage()));
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
                ),
                _buildDrawerItem(Icons.support_agent_rounded, 'Bantuan Lapangan', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF64748B), size: 20),
      ),
      title: Text(
        title, 
        style: GoogleFonts.outfit(color: const Color(0xFF334155), fontWeight: FontWeight.w700, fontSize: 14),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
