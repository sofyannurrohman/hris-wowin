import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/features/sales/data/services/sales_api_service.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/core/database/database.dart';
import 'package:hris_app/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import './digital_receipt_page.dart';

class VisitCheckoutPage extends StatefulWidget {
  final StoreModel store;
  final String selfiePath;
  final Uint8List? selfieBytes;
  final String? receiptPath;
  final String? companyId;
  final String? companyName;
  final List<Map<String, dynamic>>? items;
  final double? totalAmount;
  final String? notes;

  const VisitCheckoutPage({
    super.key, 
    required this.store, 
    required this.selfiePath, 
    this.selfieBytes,
    this.receiptPath,
    this.companyId,
    this.companyName,
    this.items,
    this.totalAmount,
    this.notes,
  });

  @override
  State<VisitCheckoutPage> createState() => _VisitCheckoutPageState();
}

class _VisitCheckoutPageState extends State<VisitCheckoutPage> {
  bool _isSubmitting = false;
  final AppDatabase db = di.sl<AppDatabase>();
  String _selectedPaymentMethod = 'CASH'; // 'CASH', 'QRIS', 'TEMPO', 'VA'
  String? _selectedBank; // 'bca', 'bni', 'bri'
  DateTime? _paymentDueDate;

  final Map<String, Map<String, dynamic>> _paymentOptions = {
    'CASH': {'label': 'Tunai (Cash)', 'icon': Icons.payments_rounded, 'color': Colors.green},
    'QRIS': {'label': 'QRIS / E-Wallet', 'icon': Icons.qr_code_2_rounded, 'color': Colors.blueAccent},
    'VA': {'label': 'Virtual Account', 'icon': Icons.account_balance_rounded, 'color': Colors.indigo},
    'TEMPO': {'label': 'Tempo / Kredit', 'icon': Icons.history_rounded, 'color': Colors.orange},
  };

  final List<Map<String, String>> _bankOptions = [
    {'id': 'bca', 'name': 'BCA Virtual Account'},
    {'id': 'bni', 'name': 'BNI Virtual Account'},
    {'id': 'bri', 'name': 'BRI Virtual Account'},
    {'id': 'mandiri', 'name': 'Mandiri Bill Payment'},
  ];

  Future<void> _submitAndCheckout() async {
    if (_selectedPaymentMethod == 'TEMPO' && _paymentDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap tentukan tanggal jatuh tempo untuk metode TEMPO.')));
      return;
    }

    if (_selectedPaymentMethod == 'VA' && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih Bank untuk Virtual Account.')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final localId = const Uuid().v4();
      final now = DateTime.now();

      // 1. Save Transaction Header to Local DB
      await db.into(db.localTransactions).insert(LocalTransactionsCompanion.insert(
        localId: localId,
        companyId: widget.companyId ?? '00000000-0000-0000-0000-000000000000',
        companyName: widget.companyName ?? 'Wowin',
        storeId: widget.store.id,
        storeName: widget.store.name,
        totalAmount: widget.totalAmount ?? 0.0,
        selfiePath: Value(widget.selfiePath),
        receiptPath: Value(widget.receiptPath),
        paymentMethod: Value(_selectedPaymentMethod),
        paymentBank: Value(_selectedBank),
        notes: Value(widget.notes),
        createdAt: now,
        syncStatus: const Value('pending'),
      ));

      // 2. Save Transaction Items to Local DB
      if (widget.items != null) {
        for (final item in widget.items!) {
          await db.into(db.localTransactionItems).insert(LocalTransactionItemsCompanion.insert(
            transactionLocalId: localId,
            productId: item['product_id'],
            productName: item['product_name'],
            quantity: item['quantity'],
            price: (item['price'] as num).toDouble(),
          ));
        }
      }

      // 3. Prepare transaction object for DigitalReceiptPage
      final transaction = {
        'receipt_no': 'PENDING-${localId.substring(0, 8).toUpperCase()}',
        'store': {'name': widget.store.name},
        'total_amount': widget.totalAmount ?? 0.0,
        'transaction_date': now.toUtc().toIso8601String(),
        'status': _selectedPaymentMethod == 'CASH' ? 'LUNAS (CASH)' : 'PENDING (OFFLINE)',
        'payment_method': _selectedPaymentMethod,
        'bank': _selectedBank,
      };

      // 4. Trigger Sync in background
      di.sl<SyncBloc>().add(SyncDataRequested());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DigitalReceiptPage(
              transaction: transaction,
              localId: localId,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Kunjungan & Order ${_selectedPaymentMethod} tersimpan!', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
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
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF334155)), onPressed: _isSubmitting ? null : () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('LANGKAH 5 DARI 5', style: GoogleFonts.outfit(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w800, letterSpacing: 1)),
          Text('Ringkasan & Pembayaran', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
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
                      Text('Total Tagihan: ${currency.format(widget.totalAmount ?? 0)}', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _row(Icons.storefront_rounded, 'Toko', widget.store.name),
                  const SizedBox(height: 10),
                  _row(Icons.business_rounded, 'Entitas', widget.companyName ?? 'Wowin Indonesia'),
                  const SizedBox(height: 10),
                  _row(Icons.shopping_basket_rounded, 'Item Pesanan', widget.items != null ? '${widget.items!.length} Produk' : 'TIDAK ADA TRANSAKSI'),
                  if (widget.notes != null && widget.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _row(Icons.speaker_notes_rounded, 'Alasan / Catatan', widget.notes!, valueColor: Colors.orange.shade800),
                  ],
                ]),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 24),
              // Payment Method selection (Only if there are items)
              if (widget.items != null && widget.items!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('METODE PEMBAYARAN', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    ..._paymentOptions.entries.map((e) {
                      final isSelected = _selectedPaymentMethod == e.key;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedPaymentMethod = e.key;
                          if (e.key != 'VA') _selectedBank = null;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? e.value['color'].withOpacity(0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? e.value['color'] : Colors.transparent, width: 2),
                          ),
                          child: Row(children: [
                            Icon(e.value['icon'], color: isSelected ? e.value['color'] : Colors.blueGrey, size: 24),
                            const SizedBox(width: 16),
                            Expanded(child: Text(e.value['label'], style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF1E293B)))),
                            if (isSelected) Icon(Icons.check_circle_rounded, color: e.value['color'], size: 20),
                          ]),
                        ),
                      );
                    }).toList(),
                    
                    if (_selectedPaymentMethod == 'VA') ...[
                      const SizedBox(height: 16),
                      Text('PILIH BANK', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      ..._bankOptions.map((bank) {
                        final isBankSelected = _selectedBank == bank['id'];
                        return InkWell(
                          onTap: () => setState(() => _selectedBank = bank['id']),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isBankSelected ? Colors.indigo.withOpacity(0.05) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isBankSelected ? Colors.indigo : Colors.grey.shade200),
                            ),
                            child: Row(children: [
                              Text(bank['name']!, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: isBankSelected ? Colors.indigo : const Color(0xFF1E293B))),
                              const Spacer(),
                              if (isBankSelected) const Icon(Icons.check_circle_rounded, color: Colors.indigo, size: 18),
                            ]),
                          ),
                        );
                      }).toList(),
                    ],

                    if (_selectedPaymentMethod == 'TEMPO') ...[
                      const SizedBox(height: 16),
                      Text('JATUH TEMPO', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) setState(() => _paymentDueDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: Row(children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _paymentDueDate == null ? 'Pilih Tanggal Jatuh Tempo...' : DateFormat('dd MMMM yyyy').format(_paymentDueDate!),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: _paymentDueDate == null ? Colors.grey : const Color(0xFF1E293B)),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ]),
                ),

              const SizedBox(height: 24),
              // Photos
              if (widget.selfieBytes != null || widget.selfiePath.isNotEmpty)
                _thumb('Selfie Check-In', widget.selfiePath, widget.selfieBytes),
              const SizedBox(height: 40),
              // Checkout button
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAndCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.items != null ? _paymentOptions[_selectedPaymentMethod]!['color'] : Colors.green, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
                    elevation: 12, 
                    shadowColor: (widget.items != null ? _paymentOptions[_selectedPaymentMethod]!['color'] : Colors.green).withOpacity(0.4)
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            widget.items == null 
                                ? 'SELESAI KUNJUNGAN' 
                                : _selectedPaymentMethod == 'QRIS' 
                                    ? 'BAYAR VIA QRIS' 
                                    : _selectedPaymentMethod == 'VA' 
                                        ? 'GENERATE VA' 
                                        : 'SELESAI & CHECKOUT', 
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)
                          ),
                          if (widget.items != null)
                            Text('Metode: ${_paymentOptions[_selectedPaymentMethod]!['label']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                        ]),
                ),
              ),
              const SizedBox(height: 40),
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

  Widget _thumb(String label, String path, Uint8List? bytes) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20), 
        child: bytes != null 
            ? Image.memory(bytes, height: 160, width: double.infinity, fit: BoxFit.cover)
            : Image.file(File(path), height: 160, width: double.infinity, fit: BoxFit.cover)
      ),
      const SizedBox(height: 8),
      Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
    ]);
  }
}
