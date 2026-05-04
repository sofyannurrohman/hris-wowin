import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/features/sales/data/services/sales_api_service.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/network/api_client.dart';
import 'package:intl/intl.dart';
import './digital_receipt_page.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  final _apiService = SalesApiService(apiClient: di.sl<ApiClient>());
  bool _isLoading = true;
  List<dynamic> _historyTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _apiService.getHistoryTransactions();
      // Sort by date descending
      history.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });
      setState(() {
        _historyTransactions = history;
      });
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
            Text('LOG OPERASIONAL', style: GoogleFonts.outfit(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text('Riwayat Transaksi', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: _historyTransactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _historyTransactions.length,
                      itemBuilder: (ctx, i) => _buildHistoryCard(_historyTransactions[i]),
                    ),
            ),
    );
  }

  Widget _buildHistoryCard(dynamic txn) {
    final storeName = txn['store']?['name'] ?? 'Toko Tidak Diketahui';
    final amount = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(txn['total_amount'] ?? 0);
    final dateObj = DateTime.parse(txn['created_at']);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dateObj);
    final status = txn['status']; // e.g. PENDING, VERIFIED

    final isVerified = status == 'VERIFIED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            color: isVerified ? Colors.green : Colors.orange,
            size: 28,
          ),
        ),
        title: Text(storeName, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(amount, style: GoogleFonts.outfit(fontSize: 14, color: isVerified ? Colors.green : Colors.orange, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(dateStr, style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey.withOpacity(0.8))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isVerified ? 'VERIFIED' : 'NEED REVIEW',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: isVerified ? Colors.green : Colors.orange),
              ),
            ),
          ],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DigitalReceiptPage(transaction: txn),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text('Belum Ada Riwayat', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF334155))),
          const SizedBox(height: 8),
          Text('Riwayat kunjungan, order, dan finalisasi\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey)),
        ],
      ),
    );
  }
}
