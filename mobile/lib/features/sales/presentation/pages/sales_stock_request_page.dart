import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/injection.dart' as di;

class SalesStockRequestPage extends StatefulWidget {
  const SalesStockRequestPage({super.key});

  @override
  State<SalesStockRequestPage> createState() => _SalesStockRequestPageState();
}

class _SalesStockRequestPageState extends State<SalesStockRequestPage> {
  final ApiClient apiClient = di.sl<ApiClient>();
  bool _isLoading = false;
  List<dynamic> _products = [];
  
  String? _selectedProductId;
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();
  
  bool _showQR = false;
  String _requestId = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // Fetch available products from warehouse stock of the branch
      final response = await apiClient.client.get('warehouse/stock');
      setState(() {
        _products = (response.data as List<dynamic>?) ?? [];
      });
    } catch (e) {
      _showError('Gagal mengambil daftar produk: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _submitRequest() async {
    if (_selectedProductId == null) {
      _showError('Pilih produk terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await apiClient.client.post('sales-transfers/request', data: {
        'product_id': _selectedProductId,
        'quantity': _quantity,
        'type': 'TRANSFER',
        'notes': _notesController.text,
      });

      // Assuming backend returns success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Permintaan stok berhasil dikirim!'), backgroundColor: Colors.green));
      
      // Since we want to show QR, we might need the ID from backend.
      // Let's assume the response contains the new request data.
      // If not, we'd need to fetch the latest request.
      
      setState(() {
        _showQR = true;
        // For testing/prototype, we can use a temporary identifier or the real ID if available
        // Usually, the response data would have it.
        // For now, let's just go back or show a generic "Show QR in History" message
      });
      
      // Actually, let's just pop back to dashboard after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });

    } catch (e) {
      _showError('Gagal mengirim permintaan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('AMBIL BARANG GUDANG', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Text('Pilih Produk', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  _buildProductDropdown(),
                  const SizedBox(height: 24),
                  Text('Jumlah Pengambilan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  _buildQuantitySelector(),
                  const SizedBox(height: 24),
                  Text('Catatan (Opsional)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Untuk stok tambahan rute sore...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('KIRIM PERMINTAAN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Gunakan menu ini untuk mengambil stok dari gudang. Warehouse akan melakukan approval setelah permintaan dikirim.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedProductId,
          hint: const Text('Pilih barang yang ingin diambil'),
          items: _products.map((item) {
            final product = item['product'];
            return DropdownMenuItem<String>(
              value: product['id'],
              child: Text('${product['name']} (Sisa: ${item['quantity']})'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedProductId = val),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
            onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
          ),
          const SizedBox(width: 32),
          Text(_quantity.toString(), style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(width: 32),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }
}
