import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/injection.dart' as di;

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
  File? _podImage;
  
  // Variables for Invoice
  late Map<String, dynamic> orderData;
  List<dynamic> _items = [];
  Map<String, int> _returnedQuantities = {};
  
  // Variables for Payment
  double _paymentAmount = 0.0;
  String _paymentMethod = 'CASH'; // CASH, MIDTRANS_QRIS
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    orderData = widget.deliveryItem['sales_transaction'] ?? widget.deliveryItem['sales_order'];
    // In real app, we should fetch detailed items. Assuming they are passed or fetched here.
    // For now, let's assume orderData has 'items'.
    _items = orderData['items'] ?? [];
    if (_items.isEmpty) {
      // Mock items for UI demonstration if backend mapping is still pending
      _items = [
        {
          'id': 'mock-1',
          'product_id': 'prod-1',
          'product': {'name': 'Mock Product A'},
          'ordered_quantity': 10,
          'price': 50000.0,
          'unit': 'PCS'
        }
      ];
    }
  }

  double get _originalTotal {
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
    for (var item in _items) {
      String pId = item['product_id'] ?? item['id'];
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
        _podImage = File(photo.path);
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

    setState(() => _isLoading = true);

    try {
      String soId = orderData['id'];

      // 1. Prepare Returns List
      List<Map<String, dynamic>> returns = [];
      _returnedQuantities.forEach((prodId, qty) {
        if (qty > 0) {
          returns.add({
            'product_id': prodId,
            'returned_quantity': qty,
          });
        }
      });

      // 2. Submit Confirm Delivery (Returns & POD)
      // Note: In real implementation, image should be uploaded first to get URL
      await apiClient.client.post(
        'sales-orders/confirm-delivery',
        data: {
          'so_id': soId,
          'received_by': 'Toko (via App)',
          'pod_image_url': 'https://dummyimage.com/pod.jpg', // Replace with real upload logic
          'notes': _notesController.text,
          'returned_items': returns,
        },
      );

      // 3. Submit Payment if any amount is entered
      double payAmount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (payAmount > 0) {
        await apiClient.client.post(
          'sales-orders/collect-payment',
          data: {
            'so_id': soId,
            'amount': payAmount,
            'payment_method': _paymentMethod,
            'collected_by': 'Admin Pengiriman',
          },
        );
      }

      // Mark the delivery item as DELIVERED
      await apiClient.client.post(
        'delivery/items/${widget.deliveryItem['id']}/confirm',
        data: {'status': 'DELIVERED', 'notes': 'Checkout Selesai'},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selesai! Data tersimpan.'), backgroundColor: Colors.green),
      );
      
      widget.onSuccess();
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
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
        title: Text(
          'Penyelesaian Pengiriman',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. Retur Instan Section
              _buildSectionTitle('Verifikasi Barang & Retur'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: _items.map((item) {
                    String pId = item['product_id'] ?? item['id'];
                    int ordered = item['ordered_quantity'] ?? 0;
                    int ret = _returnedQuantities[pId] ?? 0;
                    
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
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (ret > 0) setState(() => _returnedQuantities[pId] = ret - 1);
                                  },
                                  child: Icon(Icons.remove_circle, color: Colors.red.shade400, size: 24),
                                ),
                                const SizedBox(width: 8),
                                Text('$ret Retur', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    if (ret < ordered) setState(() => _returnedQuantities[pId] = ret + 1);
                                  },
                                  child: Icon(Icons.add_circle, color: Colors.red.shade400, size: 24),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Tagihan Section
              _buildSectionTitle('Total Tagihan'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_originalTotal != _calculatedTotal)
                      Text(
                        'Awal: ${currencyFormat.format(_originalTotal)}',
                        style: GoogleFonts.outfit(color: Colors.grey.shade400, decoration: TextDecoration.lineThrough, fontSize: 12),
                      ),
                    Text(
                      'TOTAL SETELAH RETUR',
                      style: GoogleFonts.outfit(color: Colors.blue.shade200, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                    ),
                    Text(
                      currencyFormat.format(_calculatedTotal),
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Pembayaran Parsial
              _buildSectionTitle('Penerimaan Pembayaran'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Tunai', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                            value: 'CASH',
                            groupValue: _paymentMethod,
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('QRIS', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                            value: 'MIDTRANS_QRIS',
                            groupValue: _paymentMethod,
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nominal Dibayar (Rp)',
                        labelStyle: GoogleFonts.outfit(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.payments),
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _amountController.text = _calculatedTotal.toInt().toString();
                            });
                          },
                          child: Text('Isi Lunas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ),
                        if ((double.tryParse(_amountController.text) ?? 0) < _calculatedTotal)
                          Text(
                            'Sisa Piutang: ${currencyFormat.format(_calculatedTotal - (double.tryParse(_amountController.text) ?? 0))}',
                            style: GoogleFonts.outfit(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Bukti Pengiriman (POD)
              _buildSectionTitle('Bukti Pengiriman (Kamera)'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _podImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_podImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('Ambil Foto Toko/Barang', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _submitCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('SELESAIKAN PENGIRIMAN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              ),
              const SizedBox(height: 20),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E293B)),
    );
  }
}
