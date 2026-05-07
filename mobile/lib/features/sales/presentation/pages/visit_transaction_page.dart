import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/features/sales/presentation/pages/visit_checkout_page.dart';
import 'package:hris_app/features/sales/presentation/pages/select_company_page.dart';
import 'package:hris_app/features/sales/presentation/pages/order_entry_page.dart';
import 'package:hris_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_app/injection.dart' as di;

class VisitTransactionPage extends StatefulWidget {
  final StoreModel store;
  final String selfiePath;

  const VisitTransactionPage({super.key, required this.store, required this.selfiePath});

  @override
  State<VisitTransactionPage> createState() => _VisitTransactionPageState();
}

class _VisitTransactionPageState extends State<VisitTransactionPage> {
  bool _isLoading = false;

  void _navigateToSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SelectCompanyPage(store: widget.store, selfiePath: widget.selfiePath)),
    );
  }

  Future<void> _handleAutoSelection() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = di.sl<AuthRepository>();
      final result = await authRepo.getProfile();
      
      if (mounted) {
        result.fold(
          (failure) => _navigateToSelection(),
          (profile) {
            final companyId = profile['company_id'] ?? profile['companyId'];
            final companyName = profile['company_name'] ?? profile['companyName'] ?? profile['company']?['name'];
            
            if (companyId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderEntryPage(
                    store: widget.store,
                    selfiePath: widget.selfiePath,
                    companyId: companyId.toString(),
                    companyName: companyName ?? 'Wowin Indonesia',
                  ),
                ),
              );
            } else {
              _navigateToSelection();
            }
          },
        );
      }
    } catch (e) {
      if (mounted) _navigateToSelection();
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
            Text('LANGKAH 3 DARI 5', style: GoogleFonts.outfit(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text('Status Transaksi', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(value: 0.75, minHeight: 4, backgroundColor: Colors.grey.shade200, color: Colors.blueAccent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Store badge
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.storefront_rounded, color: Colors.blueAccent, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.store.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B))),
                                  Text(widget.store.address, style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text('✓ Selfie check-in berhasil', style: GoogleFonts.outfit(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Apakah ada transaksi\ndi kunjungan ini?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Data perusahaan akan diambil otomatis\nberdasarkan akun Anda.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      // YES button (big, prominent)
                      SizedBox(
                        width: double.infinity,
                        height: 72,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleAutoSelection,
                          icon: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.note_add_rounded, color: Colors.white, size: 28),
                          label: Text(_isLoading ? 'MENGAMBIL DATA...' : 'INPUT NOTA DIGITAL', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: Colors.green.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // NO button
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VisitCheckoutPage(store: widget.store, selfiePath: widget.selfiePath, receiptPath: null)),
                          ),
                          icon: Icon(Icons.close_rounded, color: Colors.grey.shade600, size: 24),
                          label: Text('TIDAK ADA TRANSAKSI', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.grey.shade700)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
