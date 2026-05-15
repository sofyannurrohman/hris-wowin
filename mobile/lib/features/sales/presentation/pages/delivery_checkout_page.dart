import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/injection.dart' as di;
import './delivery_payment_info_page.dart';

class DeliveryCheckoutPage extends StatefulWidget {
  final Map<String, dynamic> deliveryItem;
  final VoidCallback onSuccess;

  const DeliveryCheckoutPage({
    super.key,
    required this.deliveryItem,
    required this.onSuccess,
  });

  @override
  State<DeliveryCheckoutPage> createState() => _DeliveryCheckoutPageState();
}

class _DeliveryCheckoutPageState extends State<DeliveryCheckoutPage> {
  final ApiClient apiClient = di.sl<ApiClient>();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  XFile? _podImage;
  Map<String, dynamic>? _midtransData;
  
  // Variables for Invoice
  late Map<String, dynamic> orderData;
  List<dynamic> _items = [];
  Map<String, int> _returnedQuantities = {};
  
  // Variables for Payment
  double _paymentAmount = 0.0;
  String _paymentMethod = 'CASH'; // CASH, QRIS, VA, TEMPO
  String? _selectedBank; // bca, bni, bri, mandiri
  final TextEditingController _receivedByController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  static const Map<String, Map<String, dynamic>> _paymentOptions = {
    'CASH': {'label': 'Tunai (Cash)', 'icon': Icons.payments_rounded, 'color': Colors.green},
    'QRIS': {'label': 'QRIS / E-Wallet', 'icon': Icons.qr_code_2_rounded, 'color': Colors.blueAccent},
    'VA': {'label': 'Virtual Account', 'icon': Icons.account_balance_rounded, 'color': Colors.indigo},
    'TEMPO': {'label': 'Tempo / Kredit', 'icon': Icons.history_rounded, 'color': Colors.orange},
  };

  static const List<Map<String, String>> _bankOptions = [
    {'id': 'bca', 'name': 'BCA Virtual Account'},
    {'id': 'bni', 'name': 'BNI Virtual Account'},
    {'id': 'bri', 'name': 'BRI Virtual Account'},
    {'id': 'mandiri', 'name': 'Mandiri Bill Payment'},
  ];

  @override
  void initState() {
    super.initState();
    orderData = widget.deliveryItem['sales_transaction'] ?? widget.deliveryItem['sales_order'];
    _items = orderData['items'] ?? [];
    
    // Calculate and set initial amount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAmountFromTotal();
    });
  }

  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _receivedByController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _updateAmountFromTotal() {
    setState(() {
      _amountController.text = _calculatedTotal.toInt().toString();
    });
  }

  double get _originalTotal {
    if (orderData.containsKey('total_amount')) return (orderData['total_amount'] ?? 0).toDouble();
    double total = 0;
    for (var item in _items) {
      int qty = item['ordered_quantity'] ?? 0;
      int ppu = item['pieces_per_unit'] ?? 1;
      double price = (item['price'] ?? 0).toDouble();
      total += (qty * ppu) * price;
    }
    return total;
  }

  double get _calculatedTotal {
    double total = 0;
    if (_items.isEmpty && orderData.containsKey('total_amount')) {
      return (orderData['total_amount'] ?? 0).toDouble();
    }
    for (var item in _items) {
      String pId = item['product_id'] ?? item['id'] ?? '';
      int qty = item['ordered_quantity'] ?? 0;
      int ret = _returnedQuantities[pId] ?? 0;
      int finalQty = qty - ret;
      if (finalQty < 0) finalQty = 0;
      int ppu = item['pieces_per_unit'] ?? 1;
      double price = (item['price'] ?? 0).toDouble();
      total += (finalQty * ppu) * price;
    }
    return total;
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (photo != null) {
      setState(() {
        _podImage = photo;
      });
    }
  }

  Future<void> _submitCheckout() async {
    if (_podImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti pengiriman (POD) wajib diambil'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_paymentMethod == 'VA' && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih bank untuk Virtual Account.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payAmount = double.tryParse(_amountController.text) ?? 0.0;
      final soId = orderData['id'] ?? widget.deliveryItem['sales_order_id'] ?? widget.deliveryItem['so_id'];

      List<Map<String, dynamic>> returns = [];
      _returnedQuantities.forEach((prodId, qty) {
        if (qty > 0) {
          returns.add({
            'product_id': prodId,
            'returned_quantity': qty,
          });
        }
      });

      await apiClient.client.post(
        'sales-orders/confirm-delivery',
        data: {
          'so_id': soId,
          'received_by': _receivedByController.text.isNotEmpty ? _receivedByController.text : 'Toko (via App)',
          'pod_image_url': 'https://dummyimage.com/pod.jpg', // Placeholder for now
          'notes': _notesController.text,
          'returned_items': returns,
        },
      );

      // 3. Collect Payment if any amount is entered AND not already collected via Wizard transition
      if (payAmount > 0 && _midtransData == null) {
        final response = await apiClient.client.post(
          'sales-orders/collect-payment',
          data: {
            'so_id': soId,
            'amount': payAmount,
            'payment_method': _paymentMethod,
            'payment_bank': _selectedBank,
            'collected_by': 'Driver Delivery',
          },
        );

        if (_paymentMethod == 'QRIS' || _paymentMethod == 'VA') {
          final resData = response.data is Map && response.data.containsKey('data') ? response.data['data'] : response.data;
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DeliveryPaymentInfoPage(
                  paymentData: {
                    'payment_method': _paymentMethod,
                    'midtrans_qris_url': resData['midtrans_qris_url'],
                    'midtrans_va_number': resData['midtrans_va_number'],
                    'midtrans_bank': resData['midtrans_bank'] ?? _selectedBank,
                    'midtrans_bill_key': resData['midtrans_bill_key'],
                    'midtrans_biller_code': resData['midtrans_biller_code'],
                  },
                  storeName: orderData['store']?['name'] ?? 'Toko',
                  amount: payAmount,
                ),
              ),
            );
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selesai! Pengiriman & Pembayaran tersimpan.'), backgroundColor: Colors.green),
        );
        widget.onSuccess();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penyelesaian Pengiriman',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), fontSize: 16),
            ),
            Text(
              'LANGKAH ${_currentStep + 1} DARI 4',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 10, letterSpacing: 1),
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                color: Colors.blueAccent,
                minHeight: 4,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (idx) => setState(() => _currentStep = idx),
                  children: [
                    _buildStepReview(currencyFormat),
                    _buildStepDocumentation(),
                    _buildStepPayment(currencyFormat),
                    _buildStepConfirmation(currencyFormat),
                  ],
                ),
              ),
              _buildBottomNav(),
            ],
          ),
    );
  }

  Widget _buildStepReview(NumberFormat currencyFormat) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildStepHeader('Verifikasi Barang', 'Periksa barang yang dikirim dan catat retur jika ada.'),
        const SizedBox(height: 24),
        if (_items.isEmpty)
          _buildEmptyItemsWarning()
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: _items.map((item) {
                String pId = item['product_id'] ?? item['id'] ?? '';
                int ordered = item['ordered_quantity'] ?? 0;
                int ret = _returnedQuantities[pId] ?? 0;
                return _buildItemRow(item, ordered, ret, pId);
              }).toList(),
            ),
          ),
        const SizedBox(height: 24),
        _buildTagihanSummary(currencyFormat),
      ],
    );
  }

  Widget _buildStepDocumentation() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildStepHeader('Dokumentasi', 'Ambil foto sebagai bukti bahwa barang telah diterima oleh toko.'),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: _takePhoto,
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _podImage != null ? Colors.blueAccent : Colors.grey.shade300, width: 2, style: BorderStyle.solid),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: _podImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: kIsWeb 
                        ? Image.network(_podImage!.path, fit: BoxFit.cover) 
                        : Image.file(File(_podImage!.path), fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, size: 48, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 16),
                      Text('Ambil Foto Bukti (POD)', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('Pastikan foto terlihat jelas', style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 13)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 32),
        Text('Informasi Penerima', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _receivedByController,
          decoration: InputDecoration(
            hintText: 'Masukkan nama penerima barang...',
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepPayment(NumberFormat currencyFormat) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildStepHeader('Pembayaran', 'Pilih metode pembayaran dan masukkan nominal yang diterima.'),
        const SizedBox(height: 24),
        _buildPaymentMethodSelector(),
        const SizedBox(height: 24),
        _buildPaymentAmountInput(currencyFormat),
      ],
    );
  }

  Widget _buildStepConfirmation(NumberFormat currencyFormat) {
    final payAmount = double.tryParse(_amountController.text) ?? 0.0;
    final hasMidtrans = _midtransData != null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildStepHeader('Konfirmasi Akhir', 'Pastikan semua data sudah benar sebelum menyimpan.'),
        const SizedBox(height: 24),

        if (hasMidtrans) ...[
          _buildMidtransInfoPreview(currencyFormat),
          const SizedBox(height: 24),
        ],

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Column(
            children: [
              _summaryRow('Toko', orderData['store']?['name'] ?? 'Toko'),
              const Divider(height: 32),
              _summaryRow('Tagihan Akhir', currencyFormat.format(_calculatedTotal), isBold: true),
              _summaryRow('Metode Bayar', _paymentOptions[_paymentMethod]!['label']),
              _summaryRow('Nominal Bayar', currencyFormat.format(payAmount), valueColor: Colors.blueAccent),
              if (payAmount < _calculatedTotal)
                _summaryRow('Sisa Piutang', currencyFormat.format(_calculatedTotal - payAmount), valueColor: Colors.orange.shade800),
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.photo_library_rounded, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Text('Foto Bukti Tersedia', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        if (hasMidtrans) ...[
          ElevatedButton.icon(
            onPressed: _shareMidtransToWhatsApp,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text('BAGIKAN KE PELANGGAN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),
        ],

        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan jika ada...',
            hintStyle: GoogleFonts.outfit(fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  Widget _buildMidtransInfoPreview(NumberFormat currencyFormat) {
    final qrisUrl = _midtransData?['midtrans_qris_url'];
    final vaNumber = _midtransData?['midtrans_va_number'] ?? _midtransData?['midtrans_bill_key'];
    final bank = (_midtransData?['midtrans_bank'] ?? 'Bank').toString().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          if (_paymentMethod == 'QRIS' && qrisUrl != null) ...[
            QrImageView(data: qrisUrl, size: 200, backgroundColor: Colors.white, padding: const EdgeInsets.all(12)),
            const SizedBox(height: 16),
            Text('SCAN QRIS UNTUK BAYAR', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 14)),
          ] else if (_paymentMethod == 'VA' && vaNumber != null) ...[
            Text('NOMOR VIRTUAL ACCOUNT ($bank)', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(vaNumber, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
            if (_midtransData?['midtrans_biller_code'] != null)
              Text('Biller: ${_midtransData!['midtrans_biller_code']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ],
        ],
      ),
    );
  }

  Future<void> _shareMidtransToWhatsApp() async {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final storeName = orderData['store']?['name'] ?? 'Toko';
    final payAmount = double.tryParse(_amountController.text) ?? 0.0;
    final vaNumber = _midtransData?['midtrans_va_number'] ?? _midtransData?['midtrans_bill_key'];
    final bank = (_midtransData?['midtrans_bank'] ?? 'Bank').toString().toUpperCase();

    String message = "Halo *$storeName*,\n\nBerikut informasi pembayaran untuk pengiriman hari ini:\n";
    message += "💰 *Total Tagihan:* ${currencyFormat.format(payAmount)}\n";
    message += "💳 *Metode Pembayaran:* $_paymentMethod\n";
    
    if (_paymentMethod == 'VA' && vaNumber != null) {
      message += "\n🏦 *Informasi Pembayaran ($bank):*\n";
      message += "Nomor: `$vaNumber`";
      if (_midtransData?['midtrans_biller_code'] != null) message += "\nKode Biller: `${_midtransData!['midtrans_biller_code']}`";
    }

    message += "\n\nTerima kasih!";
    
    final whatsappUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: const Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomNav() {
    bool isFirst = _currentStep == 0;
    bool isLast = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('KEMBALI', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.blueGrey)),
              ),
            ),
          if (!isFirst) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLast ? _submitCheckout : _validateAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? Colors.green : Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                isLast ? 'SELESAIKAN & SIMPAN' : 'LANJUT',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndNext() async {
    if (_currentStep == 1 && _podImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap ambil foto bukti pengiriman sebelum lanjut.'), backgroundColor: Colors.red));
      return;
    }
    if (_currentStep == 2) {
      if (_paymentMethod == 'VA' && _selectedBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih bank untuk Virtual Account.'), backgroundColor: Colors.orange));
        return;
      }

      // Fetch Midtrans data if digital payment
      if (_paymentMethod == 'QRIS' || _paymentMethod == 'VA') {
        setState(() => _isLoading = true);
        try {
          final payAmount = double.tryParse(_amountController.text) ?? 0.0;
          final soId = orderData['id'] ?? widget.deliveryItem['sales_order_id'];
          
          final response = await apiClient.client.post(
            'sales-orders/collect-payment',
            data: {
              'so_id': soId,
              'amount': payAmount,
              'payment_method': _paymentMethod,
              'payment_bank': _selectedBank,
              'collected_by': 'Driver Delivery',
            },
          );

          final resData = response.data is Map && response.data.containsKey('data') ? response.data['data'] : response.data;
          setState(() {
            _midtransData = {
              'payment_method': _paymentMethod,
              'midtrans_qris_url': resData['midtrans_qris_url'],
              'midtrans_va_number': resData['midtrans_va_number'],
              'midtrans_bank': resData['midtrans_bank'] ?? _selectedBank,
              'midtrans_bill_key': resData['midtrans_bill_key'],
              'midtrans_biller_code': resData['midtrans_biller_code'],
            };
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil data pembayaran: $e'), backgroundColor: Colors.red));
          return;
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
    _nextPage();
  }

  Widget _buildEmptyItemsWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(child: Text('Rincian barang tidak tersedia. Silakan lanjutkan dengan total tagihan.', style: GoogleFonts.outfit(color: Colors.orange.shade900, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item, int ordered, int ret, String pId) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['product']?['name'] ?? 'Produk', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Kirim: $ordered ${item['unit']}', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (ret > 0) {
                      setState(() => _returnedQuantities[pId] = ret - 1);
                      _updateAmountFromTotal();
                    }
                  },
                  child: Icon(Icons.remove_circle, color: Colors.red.shade400, size: 24),
                ),
                const SizedBox(width: 8),
                Text('$ret Retur', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (ret < ordered) {
                      setState(() => _returnedQuantities[pId] = ret + 1);
                      _updateAmountFromTotal();
                    }
                  },
                  child: Icon(Icons.add_circle, color: Colors.red.shade400, size: 24),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTagihanSummary(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_originalTotal != _calculatedTotal)
            Text('Awal: ${currencyFormat.format(_originalTotal)}', style: GoogleFonts.outfit(color: Colors.grey.shade400, decoration: TextDecoration.lineThrough, fontSize: 12)),
          Text('TOTAL SETELAH RETUR', style: GoogleFonts.outfit(color: Colors.blue.shade200, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
          Text(currencyFormat.format(_calculatedTotal), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('METODE PEMBAYARAN', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        ..._paymentOptions.entries.map((e) {
          final isSelected = _paymentMethod == e.key;
          return GestureDetector(
            onTap: () => setState(() {
              _paymentMethod = e.key;
              if (e.key != 'VA') _selectedBank = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? e.value['color'].withOpacity(0.05) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
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
        if (_paymentMethod == 'VA') ...[
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
                decoration: BoxDecoration(color: isBankSelected ? Colors.indigo.withOpacity(0.05) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: isBankSelected ? Colors.indigo : Colors.grey.shade200)),
                child: Row(children: [
                  Text(bank['name']!, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: isBankSelected ? Colors.indigo : const Color(0xFF1E293B))),
                  const Spacer(),
                  if (isBankSelected) const Icon(Icons.check_circle_rounded, color: Colors.indigo, size: 18),
                ]),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildPaymentAmountInput(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOMINAL PEMBAYARAN', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: const Color(0xFF1E293B)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixText: 'Rp ',
            prefixStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.blueGrey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
            contentPadding: const EdgeInsets.all(24),
          ),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _updateAmountFromTotal,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text('Isi Sesuai Tagihan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ),
            if ((double.tryParse(_amountController.text) ?? 0) < _calculatedTotal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('Sisa: ${currencyFormat.format(_calculatedTotal - (double.tryParse(_amountController.text) ?? 0))}', style: GoogleFonts.outfit(color: Colors.orange.shade800, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
          ],
        )
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.blueGrey, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(value, style: GoogleFonts.outfit(fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: valueColor ?? const Color(0xFF1E293B), fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B)));
  }
}
