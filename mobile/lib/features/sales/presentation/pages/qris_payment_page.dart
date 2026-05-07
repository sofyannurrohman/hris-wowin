import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class QrisPaymentPage extends StatelessWidget {
  final String qrisData;
  final double amount;
  final String receiptNo;

  const QrisPaymentPage({
    super.key,
    required this.qrisData,
    required this.amount,
    required this.receiptNo,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('PEMBAYARAN QRIS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              receiptNo,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Text(
              currency.format(amount),
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 40),
            
            // QR Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Logo_QRIS.svg/1200px-Logo_QRIS.svg.png',
                    height: 40,
                  ),
                  const SizedBox(height: 24),
                  QrImageView(
                    data: qrisData,
                    version: QrVersions.auto,
                    size: 260.0,
                    gapless: false,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SCAN UNTUK BAYAR',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: 2),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _infoRow(Icons.account_balance_wallet_rounded, 'Dukung semua e-wallet (GoPay, OVO, Dana, dll)'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.speed_rounded, 'Pembayaran terverifikasi otomatis secara real-time'),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('TUTUP', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.blueGrey)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
