import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import './digital_receipt_page.dart';

class VisitSuccessPage extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final String? localId;

  const VisitSuccessPage({super.key, required this.transaction, this.localId});

  @override
  State<VisitSuccessPage> createState() => _VisitSuccessPageState();
}

class _VisitSuccessPageState extends State<VisitSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final amount = (widget.transaction['total_amount'] ?? 0.0).toDouble();
    final storeName = widget.transaction['store']?['name'] ?? 'Toko';
    final receiptNo = widget.transaction['receipt_no'] ?? 'NO-DATA';
    final isSO = widget.transaction['payment_method'] == 'SALES_ORDER';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -50,
            right: -50,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), shape: BoxShape.circle)),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.05), shape: BoxShape.circle)),
          ),
          
          // Random decorative circles for confetti feel
          Positioned(top: 100, left: 40, child: _dot(Colors.green, 12)),
          Positioned(top: 150, right: 60, child: _dot(Colors.blueAccent, 8)),
          Positioned(bottom: 250, right: 40, child: _dot(Colors.orange, 10)),
          Positioned(bottom: 200, left: 80, child: _dot(Colors.pinkAccent, 6)),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Top notification style badge
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isSO ? 'SALES ORDER TERSIMPAN!' : 'PEMBAYARAN BERHASIL!', 
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Main Icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      children: [
                        Text(
                          isSO ? 'Order Berhasil Dibuat' : 'Kunjungan Selesai',
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isSO 
                            ? 'Pesanan untuk $storeName telah berhasil disimpan dan menunggu verifikasi admin.'
                            : 'Kunjungan dan pembayaran untuk $storeName telah berhasil diselesaikan.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Summary Card
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('ID Transaksi', receiptNo),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                          _summaryRow('Total Nominal', currency.format(amount), isBold: true),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Buttons
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DigitalReceiptPage(
                                    transaction: widget.transaction,
                                    localId: widget.localId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text('LIHAT NOTA DIGITAL', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.settings.name == '/sales_dashboard'),
                          child: Text('KEMBALI KE DASHBOARD', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.blueAccent, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, double size) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
        Text(
          value, 
          style: GoogleFonts.outfit(
            fontSize: isBold ? 16 : 14, 
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, 
            color: const Color(0xFF1E293B)
          )
        ),
      ],
    );
  }
}
