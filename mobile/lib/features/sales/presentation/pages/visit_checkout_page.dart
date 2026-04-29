import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/features/sales/data/services/sales_api_service.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/network/api_client.dart';
import 'package:intl/intl.dart';

class VisitCheckoutPage extends StatefulWidget {
  final StoreModel store;
  final String selfiePath;
  final String? receiptPath;
  const VisitCheckoutPage({super.key, required this.store, required this.selfiePath, required this.receiptPath});

  @override
  State<VisitCheckoutPage> createState() => _VisitCheckoutPageState();
}
class _VisitCheckoutPageState extends State<VisitCheckoutPage> {
  bool _isSubmitting = false;
  final _apiService = SalesApiService(apiClient: di.sl<ApiClient>());
  String? _selectedReason;

  final List<String> _noTransactionReasons = [
    'Toko Tutup',
    'Pemilik Tidak Ada',
    'Stok Masih Banyak',
    'Sudah Belanja di Sales Lain',
    'Toko Sedang Pindah / Renovasi',
    'Lainnya',
  ];

  Future<void> _submitAndCheckout() async {
    setState(() => _isSubmitting = true);
    
    try {
      // Note: In real app, we should upload image and get URL first.
      // Here we simulate it or pass empty.
      
      await _apiService.createTransaction({
        'company_id': '00000000-0000-0000-0000-000000000000', // Auto resolved in backend by token
        'store_id': widget.store.id,
        'employee_id': '00000000-0000-0000-0000-000000000000', // Auto resolved in backend
        'receipt_no': '',
        'receipt_image_url': widget.receiptPath ?? '',
        'total_amount': 0.0, // Updated later during finalization
        'notes': _selectedReason ?? '',
        'store_category': widget.store.isNew ? 'TOKO_BARU' : 'TOKO_LAMA',
        'transaction_date': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.settings.name == '/sales_dashboard');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Kunjungan ${widget.store.name} tersimpan!', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan kunjungan: $e', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF334155)), onPressed: _isSubmitting ? null : () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.selfiePath.isEmpty ? 'LANGKAH 3 DARI 3' : 'LANGKAH 4 DARI 4', style: GoogleFonts.outfit(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w800, letterSpacing: 1)),
          Text(widget.selfiePath.isEmpty ? 'Ringkasan Order & Checkout' : 'Ringkasan & Checkout', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        ]),
      ),
      body: Column(children: [
        LinearProgressIndicator(value: 1.0, minHeight: 4, backgroundColor: Colors.grey.shade200, color: Colors.green),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Siap Checkout!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                      Text(widget.selfiePath.isEmpty ? 'Data order sudah lengkap.' : 'Data kunjungan sudah lengkap.', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey)),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _row(Icons.storefront_rounded, 'Toko', widget.store.name),
                  const SizedBox(height: 10),
                  _row(Icons.location_on_rounded, 'Alamat', widget.store.address),
                  const SizedBox(height: 10),
                  _row(Icons.receipt_long_rounded, 'Transaksi', widget.receiptPath != null ? 'Ada (nota terlampir)' : 'Tidak ada', valueColor: widget.receiptPath != null ? Colors.green : Colors.orange),
                ]),
              ),

              if (widget.receiptPath == null) ...[
                const SizedBox(height: 24),
                Text('ALASAN TIDAK ADA TRANSAKSI', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _selectedReason == null ? Colors.red.withOpacity(0.3) : Colors.transparent),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedReason,
                      hint: Text('Pilih Alasan...', style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14)),
                      items: _noTransactionReasons.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B))),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedReason = val),
                    ),
                  ),
                ),
                if (_selectedReason == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 8),
                    child: Text('* Harap pilih alasan untuk melanjutkan', style: GoogleFonts.outfit(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
              const SizedBox(height: 24),
              // Photos
              if (widget.selfiePath.isNotEmpty)
                Row(children: [
                  Expanded(child: _thumb('Selfie Check-In', widget.selfiePath)),
                  if (widget.receiptPath != null) ...[const SizedBox(width: 16), Expanded(child: _thumb('Nota', widget.receiptPath!))],
                ])
              else if (widget.receiptPath != null)
                Row(children: [
                  Expanded(child: _thumb('Nota', widget.receiptPath!)),
                ]),
              const SizedBox(height: 40),
              // Checkout button
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || (widget.receiptPath == null && _selectedReason == null)) ? null : _submitAndCheckout,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 12, shadowColor: Colors.green.withOpacity(0.4)),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('SELESAI & CHECKOUT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                          Text('Data masuk ke Finalisasi Laporan', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                        ]),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.blueAccent, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w700)),
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: valueColor ?? const Color(0xFF1E293B))),
      ])),
    ]);
  }

  Widget _thumb(String label, String path) {
    return Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(path), height: 160, width: double.infinity, fit: BoxFit.cover)),
      const SizedBox(height: 8),
      Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
    ]);
  }
}
