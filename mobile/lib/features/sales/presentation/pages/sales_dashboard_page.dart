import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import './select_store_page.dart';
import './sales_history_page.dart';
import './store_list_page.dart';
import './order_banner_page.dart';
import './route_planning_page.dart';
import './product_catalog_page.dart';
import './visit_schedule_page.dart';
import './delivery_tracking_page.dart';
import './sales_stock_request_page.dart';
import 'package:hris_app/features/sales/data/services/sales_api_service.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/network/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_state.dart';
import 'package:hris_app/core/database/database.dart';
import './digital_receipt_page.dart';

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
  List<dynamic> _todayVisitPlans = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final db = di.sl<AppDatabase>();
      
      // 1. Fetch Remote Data
      final kpi = await _apiService.getMyPerformance();
      final visits = await _apiService.getVisitPlans(date: DateFormat('yyyy-MM-dd').format(DateTime.now()));
      
      // 2. Fetch Local Pending Transactions
      final localPending = await (db.select(db.localTransactions)
          ..where((t) => t.syncStatus.equals('pending')))
        .get();

      // 3. Fetch Remote Pending (for reconciliation)
      final remotePending = await _apiService.getPendingTransactions();

      if (mounted) {
        setState(() {
          _kpiData = kpi;
          _todayVisitPlans = visits ?? [];
          
          // Combine local and remote pending
          _pendingTransactions = [
            ...localPending.map((t) => {
              'id': t.localId,
              'receipt_no': t.receiptNo ?? 'PENDING (OFFLINE)',
              'store': {'name': t.storeName},
              'total_amount': t.totalAmount,
              'status': 'PENDING',
              'is_local': true,
            }),
            ...(remotePending ?? []),
          ];
        });
      }
    } catch (e) {
      debugPrint('Error fetching sales data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSwipeableHeader() {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            pageSnapping: true,
            onPageChanged: (v) => setState(() => _currentPage = v),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildTargetCard(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildVisitSummaryCard(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildVisitSummaryCard() {
    final List<dynamic> visits = _todayVisitPlans;
    final int totalVisits = visits.length;
    final int completedVisits = visits.fold<int>(0, (prev, element) {
      if (element is Map && element['status'] == 'COMPLETED') return prev + 1;
      return prev;
    });
    final double progress = totalVisits > 0 ? completedVisits / totalVisits : 0.0;

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VisitSchedulePage())),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF065F46).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: const Color(0xFF059669).withOpacity(0.1), width: 1.5),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(Icons.route_rounded, size: 100, color: const Color(0xFF10B981).withOpacity(0.04)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF059669), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'RENCANA KUNJUNGAN',
                            style: GoogleFonts.outfit(color: const Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                      Text(
                        '${DateFormat('dd MMM').format(DateTime.now())}',
                        style: GoogleFonts.outfit(color: const Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$completedVisits / $totalVisits', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 24)),
                            Text('Toko dikunjungi hari ini', style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Container(
                        width: 50, height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFFECFDF5),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              strokeWidth: 6,
                            ),
                            Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF059669))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text('LIHAT JADWAL LENGKAP', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9), // Clean Light Mint
      appBar: AppBar(
        title: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            String companyName = 'WOWIN PT';
            if (state is ProfileLoaded) {
              companyName = state.profile['company']?['name'] ?? 'WOWIN PT';
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SALES PERFORMANCE',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14, letterSpacing: 1),
                ),
                Text(
                  companyName.toUpperCase(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF10B981), fontSize: 8, letterSpacing: 1),
                ),
              ],
            );
          },
        ),
        backgroundColor: const Color(0xFF064E3B), // Elegant Dark Green
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 100,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'KE HRIS',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ),
        actions: [
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              return IconButton(
                onPressed: state is SyncInProgress ? null : () {
                  context.read<SyncBloc>().add(SyncMasterDataRequested());
                },
                icon: state is SyncInProgress 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync_rounded, color: Colors.white),
                tooltip: 'Sinkronisasi Data Master',
              );
            },
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeliveryTrackingPage())),
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state is SyncMasterDataSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Data Master berhasil diperbarui!'), backgroundColor: Colors.green));
          } else if (state is SyncFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal sinkronisasi: ${state.error}'), backgroundColor: Colors.red));
          }
        },
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      _buildSwipeableHeader(),
                      const SizedBox(height: 24),
                      const SizedBox(height: 24),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        builder: (context, state) {
                          String position = '';
                          if (state is ProfileLoaded) {
                            position = state.profile['job_position']?['title'] ?? '';
                          }
                          return _buildQuickAccess(position);
                        },
                      ),
                      if (_pendingTransactions.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildPendingTransactionsList(),
                      ],
                      const SizedBox(height: 40), // extra bottom padding for comfort
                    ],
                  ),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065F46).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFF059669).withOpacity(0.1), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.trending_up_rounded, size: 100, color: Colors.blueAccent.withOpacity(0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF059669), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PERFORMA OMZET',
                      style: GoogleFonts.outfit(color: const Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatter.format(targetOmzet),
                    style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                ),
                Text(
                  'Target ditugaskan atasan',
                  style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildStatItem('Realisasi', formatter.format(achievedOmzet), const Color(0xFF059669))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatItem('Sisa', formatter.format(sisa < 0 ? 0 : sisa), const Color(0xFFB91C1C))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatItem('Pencapaian', '${achievementPercentage.toStringAsFixed(1)}%', const Color(0xFF047857))),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: targetOmzet > 0 ? (achievedOmzet / targetOmzet).clamp(0.0, 1.0) : 0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFECFDF5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          child: Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ),
      ],
    );
  }

  Widget _buildQuickAccess(String jobPosition) {
    final bool isSalesTO = jobPosition.contains('Task Order') || jobPosition.contains('Sales TO');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AKSES OPERASIONAL',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
          children: [
            _buildActionItem(Icons.storefront_rounded, 'Kunjungan', const Color(0xFF059669)),
            _buildActionItem(Icons.view_list_rounded, 'Toko & Spanduk', const Color(0xFF047857)),
            _buildActionItem(Icons.menu_book_rounded, 'Katalog', const Color(0xFF0D9488)),
            _buildActionItem(Icons.history_edu_rounded, 'Riwayat Nota', const Color(0xFFCA8A04)),
            if (!isSalesTO)
              _buildActionItem(Icons.move_to_inbox_rounded, 'Ambil Barang', const Color(0xFF15803D)),
          ],
        ),
      ],
    );
  }

  void _showStoreManagementOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Manajemen Toko', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _buildDialogOption(
              context, 
              Icons.view_list_rounded, 
              'Daftar & Edit Toko', 
              'Kelola semua database outlet Anda',
              () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreListPage()));
              }
            ),
            const SizedBox(height: 12),
            _buildDialogOption(
              context, 
              Icons.art_track_rounded, 
              'Order Spanduk', 
              'Pemesanan spanduk promosi outlet',
              () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderBannerPage()));
              }
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption(BuildContext context, IconData icon, String title, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(desc, style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        if (label == 'Kunjungan') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VisitSchedulePage()));
        } else if (label == 'Toko & Spanduk') {
          _showStoreManagementOptions(context);
        } else if (label == 'Katalog') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductCatalogPage()));
        } else if (label == 'Riwayat Nota') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalesHistoryPage()));
        } else if (label == 'Ambil Barang') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalesStockRequestPage()));
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 10,
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


  Widget _buildPendingTransactionsList() {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TRANSAKSI PENDING (BELUM SYNC)',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.orange.shade800, letterSpacing: 1.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text('${_pendingTransactions.length}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange.shade900)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pendingTransactions.length > 3 ? 3 : _pendingTransactions.length,
          itemBuilder: (context, index) {
            final txn = _pendingTransactions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.cloud_off_rounded, color: Colors.orange.shade400, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(txn['store']?['name'] ?? 'Toko', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(formatter.format(txn['total_amount'] ?? 0), style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DigitalReceiptPage(transaction: txn, localId: txn['is_local'] == true ? txn['id'] : null)));
                    },
                    child: Text('LIHAT NOTA', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                  ),
                ],
              ),
            );
          },
        ),
        if (_pendingTransactions.length > 3)
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalesHistoryPage())),
              child: Text('LIHAT SEMUA PENDING', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueGrey)),
            ),
          ),
      ],
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
                colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                String name = 'Sales Team';
                String company = 'WOWIN PT';
                if (state is ProfileLoaded) {
                  name = state.profile['name'] ?? 'Sales Team';
                  company = state.profile['company']?['name'] ?? 'WOWIN PT';
                }
                return Column(
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
                      style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    Text(
                      company,
                      style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ],
                );
              },
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
