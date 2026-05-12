import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:intl/intl.dart';
import './delivery_tracking_page.dart';
import './delivery_history_page.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryDashboardPage extends StatefulWidget {
  const DeliveryDashboardPage({super.key});

  @override
  State<DeliveryDashboardPage> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage> {
  final ApiClient apiClient = di.sl<ApiClient>();
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  
  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await apiClient.client.get('delivery/tasks');
      if (mounted) {
        setState(() {
          _tasks = response.data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching delivery data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    int totalItems = 0;
    int deliveredItems = 0;
    double totalCash = 0;

    for (var task in _tasks) {
      final items = task['items'] as List;
      totalItems += items.length;
      deliveredItems += items.where((i) => i['status'] == 'DELIVERED').length;
      totalCash += (task['total_cash_collected'] ?? 0.0).toDouble();
    }

    final int totalBatches = _tasks.length;
    final double overallProgress = totalItems > 0 ? deliveredItems / totalItems : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'DASHBOARD PENGIRIMAN',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14, letterSpacing: 1),
            ),
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                String company = 'WOWIN PT';
                if (state is ProfileLoaded) {
                  company = state.profile['company']?['name'] ?? 'WOWIN PT';
                }
                return Text(
                  company.toUpperCase(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.blueAccent.shade100, fontSize: 8, letterSpacing: 1),
                );
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A), // Professional Midnight Blue
        centerTitle: true,
        elevation: 0,
        leadingWidth: 100,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(
                'KE HRIS',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchDashboardData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        backgroundColor: Colors.white,
        color: Colors.blueAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressHeader(overallProgress, deliveredItems, totalItems),
              const SizedBox(height: 24),
              _buildQuickStats(totalBatches, totalCash),
              const SizedBox(height: 32),
              _buildQuickActions(context),
              const SizedBox(height: 32),
              _buildRecentTasksHeader(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (_tasks.isEmpty)
                _buildEmptyState()
              else
                ..._tasks.map((task) => _buildTaskCard(context, task)).toList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(double progress, int delivered, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRES PENGIRIMAN',
                      style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$delivered / $total Outlet',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
                    ),
                    Text(
                      'Diselesaikan hari ini',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70, height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int batches, double cash) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'TOTAL SJ', 
            batches.toString(), 
            Icons.assignment_rounded, 
            Colors.orange,
            'Surat Jalan',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'KAS COD', 
            formatter.format(cash), 
            Icons.payments_rounded, 
            Colors.green,
            'Uang Tunai',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subLabel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: color.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ),
          Text(
            subLabel,
            style: GoogleFonts.outfit(color: Colors.blueGrey.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AKSES OPERASIONAL',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(context, Icons.qr_code_scanner_rounded, 'Scan SJ', const Color(0xFF6366F1), () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryTrackingPage(initialScan: true)));
            }),
            _buildActionItem(context, Icons.map_rounded, 'Rute Optimal', const Color(0xFFF43F5E), () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryTrackingPage(initialScan: true, autoShowMap: true)));
            }),
            _buildActionItem(context, Icons.local_shipping_rounded, 'Tugas Saya', const Color(0xFF0EA5E9), () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryTrackingPage()));
            }),
            _buildActionItem(context, Icons.history_rounded, 'Riwayat', const Color(0xFF64748B), () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryHistoryPage()));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasksHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'DAFTAR SURAT JALAN',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5),
        ),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryTrackingPage())),
          child: Text(
            'Lihat Semua',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, dynamic task) {
    final String doNo = task['delivery_order_no'] ?? 'SJ-PENDING';
    final String status = task['status'] ?? 'WAITING';
    final int itemsCount = (task['items'] as List).length;
    final int deliveredCount = (task['items'] as List).where((i) => i['status'] == 'DELIVERED').length;
    
    Color statusColor = Colors.grey;
    if (status == 'ON_DELIVERY') statusColor = Colors.blueAccent;
    if (status == 'COMPLETED') statusColor = Colors.green;
    if (status == 'WAITING_ASSIGNMENT') statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryTrackingPage()));
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.local_shipping_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SJ #$doNo',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.store_rounded, size: 12, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          '$deliveredCount / $itemsCount Outlet Selesai',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.blueGrey.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            'Tidak ada tugas hari ini',
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Semua pengiriman telah selesai atau belum ditugaskan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
