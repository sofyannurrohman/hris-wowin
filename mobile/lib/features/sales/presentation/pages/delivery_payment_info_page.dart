import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryPaymentInfoPage extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  final String storeName;
  final double amount;

  const DeliveryPaymentInfoPage({
    super.key,
    required this.paymentData,
    required this.storeName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final paymentMethod = paymentData['payment_method'] ?? 'PENDING';
    final qrisUrl = paymentData['midtrans_qris_url'];
    final vaNumber = paymentData['midtrans_va_number'] ?? paymentData['midtrans_bill_key'];
    final bank = (paymentData['midtrans_bank'] ?? 'Bank').toString().toUpperCase();
    final billerCode = paymentData['midtrans_biller_code'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('INFO PEMBAYARAN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  
                  if (paymentMethod == 'QRIS' && qrisUrl != null) ...[
                    _buildQRISSection(qrisUrl),
                  ] else if (paymentMethod == 'VA' && vaNumber != null) ...[
                    _buildVASection(bank, vaNumber, billerCode),
                  ] else ...[
                    const Icon(Icons.pending_actions_rounded, size: 80, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text('Menunggu Data...', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _buildRow('Toko', storeName, isBold: true),
                        const Divider(height: 32),
                        _buildRow('Metode Bayar', paymentMethod),
                        const SizedBox(height: 12),
                        _buildRow('Total Tagihan', currencyFormat.format(amount), isPrice: true),
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
                          paymentMethod == 'QRIS' ? 'SCAN QRIS DI ATAS' : 'TRANSFER KE NOMOR DI ATAS',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          paymentMethod == 'QRIS' 
                            ? 'Pelanggan dapat memindai kode QR di atas menggunakan aplikasi perbankan atau e-wallet.'
                            : 'Silakan lakukan transfer ke nomor Virtual Account di atas sebelum meninggalkan toko.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: () => _shareToWhatsApp(context, paymentMethod, vaNumber, bank, billerCode),
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                label: Text('KIRIM KE WHATSAPP', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 64,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('TUTUP', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRISSection(String url) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        QrImageView(data: url, version: QrVersions.auto, size: 240.0),
        const SizedBox(height: 12),
        Text('SCAN QRIS UNTUK BAYAR', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
      ]),
    );
  }

  Widget _buildVASection(String bank, String va, String? biller) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
      child: Column(children: [
        Text('NOMOR VIRTUAL ACCOUNT ($bank)', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1)),
        const SizedBox(height: 12),
        Text(va, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: 1)),
        if (biller != null) ...[
          const SizedBox(height: 4),
          Text('Kode Biller: $biller', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
        ],
      ]),
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

  Future<void> _shareToWhatsApp(BuildContext context, String method, String? va, String bank, String? biller) async {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    String message = "Halo *$storeName*,\n\nBerikut informasi pembayaran untuk pengiriman hari ini:\n";
    message += "💰 *Total Tagihan:* ${currencyFormat.format(amount)}\n";
    message += "💳 *Metode Pembayaran:* $method\n";
    
    if (method == 'VA' && va != null) {
      message += "\n🏦 *Informasi Pembayaran ($bank):*\n";
      message += "Nomor: `$va`";
      if (biller != null) message += "\nKode Biller: `$biller`";
    }

    message += "\n\nTerima kasih!";
    
    final whatsappUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }
}
