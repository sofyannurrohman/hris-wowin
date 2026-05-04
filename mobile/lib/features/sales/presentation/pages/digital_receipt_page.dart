import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DigitalReceiptPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const DigitalReceiptPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final storeName = transaction['store']?['name'] ?? 'Toko';
    final receiptNo = transaction['receipt_no'] ?? 'NO-DATA';
    final amount = (transaction['total_amount'] ?? 0.0).toDouble();
    final date = DateTime.parse(transaction['transaction_date']);
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('NOTA DIGITAL', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).popUntil((route) => route.settings.name == '/sales_dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Barcode Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: receiptNo,
                          width: double.infinity,
                          height: 100,
                          drawText: false,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          receiptNo,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF334155), letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _buildRow('Toko', storeName, isBold: true),
                        const Divider(height: 32),
                        _buildRow('Tanggal', dateStr),
                        const SizedBox(height: 12),
                        _buildRow('Status', transaction['status'] ?? 'PENDING'),
                        const SizedBox(height: 12),
                        _buildRow('Total', currencyFormat.format(amount), isPrice: true),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TUNJUKKAN KE ADMIN',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gunakan barcode di atas untuk validasi transaksi oleh Admin Nota atau Kasir.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.settings.name == '/sales_dashboard'),
                icon: const Icon(Icons.home_rounded, color: Colors.white),
                label: Text('KEMBALI KE DASHBOARD', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isPrice ? 18 : 14,
            fontWeight: isBold || isPrice ? FontWeight.w900 : FontWeight.w700,
            color: isPrice ? Colors.blueAccent : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
