import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/features/sales/data/models/visit_plan_model.dart';
import 'package:hris_app/features/sales/data/services/sales_api_service.dart';
import 'package:hris_app/features/sales/data/services/store_api_service.dart';
import 'package:hris_app/features/sales/presentation/pages/select_store_page.dart';
import 'package:hris_app/features/sales/presentation/pages/visit_checkin_page.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/network/api_client.dart';
import 'package:intl/intl.dart';

class VisitSchedulePage extends StatefulWidget {
  const VisitSchedulePage({super.key});

  @override
  State<VisitSchedulePage> createState() => _VisitSchedulePageState();
}

class _VisitSchedulePageState extends State<VisitSchedulePage> {
  final _salesApi = SalesApiService(apiClient: di.sl<ApiClient>());
  final _storeApi = StoreApiService(apiClient: di.sl<ApiClient>());
  bool _isLoading = true;
  List<VisitPlanModel> _plans = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _salesApi.getVisitPlans();
      setState(() {
        _plans = data.map((e) => VisitPlanModel.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _completedCount => _plans.where((p) => p.status == 'COMPLETED' || p.status == 'EXTRA').length;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(now);

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
            Text('JADWAL KUNJUNGAN', style: GoogleFonts.outfit(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            Text('Hari Ini', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: CustomScrollView(
                slivers: [
                  // Header Summary
                  SliverToBoxAdapter(
                    child: _buildHeader(dateStr),
                  ),

                  // List Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DAFTAR TOKO', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
                          Text('${_plans.length} Toko', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                  ),

                  // Visit List
                  _plans.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildVisitCard(_plans[i]),
                              childCount: _plans.length,
                            ),
                          ),
                        ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectStorePage())),
        backgroundColor: Colors.blueAccent,
        elevation: 8,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: Text('Kunjungan Ekstra', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildHeader(String dateStr) {
    final progress = _plans.isEmpty ? 0.0 : _completedCount / _plans.length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(dateStr, style: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress Kunjungan', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '$_completedCount', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                        TextSpan(text: ' / ${_plans.length}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
                        TextSpan(text: ' Toko', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                      ],
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64, height: 64,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      color: Colors.blueAccent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(VisitPlanModel plan) {
    final isCompleted = plan.status == 'COMPLETED' || plan.status == 'EXTRA';
    final isExtra = plan.isExtra || plan.status == 'EXTRA';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isCompleted ? null : () => _navigateToCheckin(plan),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatusIcon(plan.status),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(plan.storeName, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B)))),
                            if (isExtra)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text('EKSTRA', style: GoogleFonts.outfit(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w900)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(plan.address, style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (!isCompleted)
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.blueAccent, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'COMPLETED':
      case 'EXTRA':
        color = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'SKIPPED':
        color = Colors.red;
        icon = Icons.cancel_rounded;
        break;
      default:
        color = Colors.blueAccent;
        icon = Icons.schedule_rounded;
    }

    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }

  void _navigateToCheckin(VisitPlanModel plan) async {
    // Fetch full store data
    try {
      final store = await _storeApi.getStoreByID(plan.storeId);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => VisitCheckinPage(store: store)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text('Tidak Ada Jadwal', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF334155))),
          const SizedBox(height: 8),
          Text('Anda tidak memiliki rencana\nkunjungan hari ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectStorePage())),
            icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
            label: Text('Mulai Kunjungan Ekstra', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ],
      ),
    );
  }
}
