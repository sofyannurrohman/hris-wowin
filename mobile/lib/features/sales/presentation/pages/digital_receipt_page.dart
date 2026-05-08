import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/database/database.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class DigitalReceiptPage extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final String? localId;

  const DigitalReceiptPage({super.key, required this.transaction, this.localId});

  @override
  State<DigitalReceiptPage> createState() => _DigitalReceiptPageState();
}

class _DigitalReceiptPageState extends State<DigitalReceiptPage> {
  late Map<String, dynamic> _currentTrx;
  Timer? _refreshTimer;
  final AppDatabase _db = di.sl<AppDatabase>();

  @override
  void initState() {
    super.initState();
    _currentTrx = widget.transaction;
    if (widget.localId != null) {
      _fetchLatestData();
      // Poll every 5 seconds to catch sync updates (QRIS/VA)
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLatestData());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestData() async {
    if (widget.localId == null) return;

    final updated = await (_db.select(_db.localTransactions)
          ..where((t) => t.localId.equals(widget.localId!)))
        .getSingleOrNull();

    if (updated != null && mounted) {
      setState(() {
        _currentTrx = {
          ..._currentTrx,
          'receipt_no': updated.receiptNo ?? _currentTrx['receipt_no'],
          'status': updated.syncStatus == 'synced' 
              ? 'BERHASIL (TERSIMPAN)' 
              : (_currentTrx['payment_method'] == 'CASH' ? 'LUNAS (CASH)' : 'PENDING (MENUNGGU SINYAL)'),
          'midtrans_id': updated.midtransId,
          'midtrans_qris_url': updated.midtransQrisUrl,
          'midtrans_va_number': updated.midtransVaNumber,
          'midtrans_bank': updated.midtransBank,
          'midtrans_bill_key': updated.midtransBillKey,
          'midtrans_biller_code': updated.midtransBillerCode,
        };
      });
    }
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    final storeName = _currentTrx['store']?['name'] ?? 'Toko';
    final receiptNo = _currentTrx['receipt_no'] ?? 'NO-DATA';
    final amount = (_currentTrx['total_amount'] ?? 0.0).toDouble();
    final paymentMethod = _currentTrx['payment_method'] ?? 'CASH';
    final vaNumber = _currentTrx['midtrans_va_number'] ?? _currentTrx['midtrans_bill_key'] ?? '';
    final bank = _currentTrx['midtrans_bank'] ?? '';
    
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    
    String message = "Halo *$storeName*,\n\nTerima kasih telah berbelanja di *Wowin Indonesia*.\n\nBerikut ringkasan pesanan Anda:\n";
    message += "📌 *No. Nota:* $receiptNo\n";
    message += "💰 *Total Tagihan:* ${currencyFormat.format(amount)}\n";
    message += "💳 *Metode Pembayaran:* $paymentMethod\n";
    
    if (vaNumber.isNotEmpty) {
      message += "\n🏦 *Informasi Pembayaran (${bank.toUpperCase()}):*\n";
      message += "Nomor: `$vaNumber`";
      if (_currentTrx['midtrans_biller_code'] != null) {
        message += "\nKode Biller: `${_currentTrx['midtrans_biller_code']}`";
      }
      message += "\n\n_Silakan lakukan pembayaran sesuai nominal di atas._\n";
    }

    if (amount == 0 && _currentTrx['notes'] != null) {
      message += "\n📝 *Catatan Kunjungan:* ${_currentTrx['notes']}\n";
    }
    
    message += "\nTerima kasih atas kerja samanya!";
    
    final whatsappUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka WhatsApp.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeName = _currentTrx['store']?['name'] ?? 'Toko';
    final receiptNo = _currentTrx['receipt_no'] ?? 'NO-DATA';
    final amount = (_currentTrx['total_amount'] ?? 0.0).toDouble();
    final date = DateTime.tryParse(_currentTrx['transaction_date'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('NOTA DIGITAL', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _fetchLatestData, icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent))
        ],
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
                  
                  // Barcode or QRIS Section
                  if (_currentTrx['payment_method'] == 'QRIS' && _currentTrx['midtrans_qris_url'] != null)
                    _buildQRISSection(_currentTrx['midtrans_qris_url'])
                  else
                    _buildBarcodeSection(receiptNo),
                  
                  const SizedBox(height: 32),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _buildRow('Toko', storeName, isBold: true),
                        const Divider(height: 32),
                        _buildRow('Tanggal', dateStr),
                        const SizedBox(height: 12),
                        _buildRow('Status', _currentTrx['status'] ?? 'PENDING'),
                        const SizedBox(height: 12),
                        _buildRow('Metode Bayar', _currentTrx['payment_method'] ?? 'CASH'),
                        const SizedBox(height: 12),
                        _buildRow('Total', currencyFormat.format(amount), isPrice: true),
                      ],
                    ),
                  ),

                  // VA Information if exists
                  if (_currentTrx['midtrans_va_number'] != null || _currentTrx['midtrans_bill_key'] != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
                      child: Column(children: [
                        Text('NOMOR VIRTUAL ACCOUNT (${(_currentTrx['midtrans_bank'] ?? 'Bank').toString().toUpperCase()})', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(_currentTrx['midtrans_va_number'] ?? _currentTrx['midtrans_bill_key'], style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: 1)),
                        if (_currentTrx['midtrans_biller_code'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Kode Biller: ${_currentTrx['midtrans_biller_code']}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
                        ]
                      ]),
                    ),
                  ],
                  
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
                          _currentTrx['payment_method'] == 'QRIS' ? 'SCAN QRIS DI ATAS' : 'TUNJUKKAN KE ADMIN',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentTrx['payment_method'] == 'QRIS' 
                            ? 'Pelanggan dapat memindai kode QR di atas menggunakan aplikasi perbankan atau e-wallet.'
                            : 'Gunakan barcode di atas untuk validasi transaksi oleh Admin Nota atau Kasir.',
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

            // Share to WhatsApp Button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: () => _shareToWhatsApp(context),
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                label: Text('KIRIM KE WHATSAPP PELANGGAN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
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
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.settings.name == '/sales_dashboard'),
                icon: const Icon(Icons.home_rounded, color: Color(0xFF1E293B)),
                label: Text('KEMBALI KE DASHBOARD', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeSection(String data) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        BarcodeWidget(barcode: Barcode.code128(), data: data, width: double.infinity, height: 100, drawText: false),
        const SizedBox(height: 12),
        Text(data, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF334155), letterSpacing: 2)),
      ]),
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
