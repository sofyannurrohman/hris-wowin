import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/sales/data/services/banner_order_api_service.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/features/sales/data/services/store_api_service.dart';

class OrderBannerPage extends StatefulWidget {
  const OrderBannerPage({super.key});

  @override
  State<OrderBannerPage> createState() => _OrderBannerPageState();
}

class _OrderBannerPageState extends State<OrderBannerPage> {
  final _formKey = GlobalKey<FormState>();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;
  final _apiService = BannerOrderApiService(apiClient: di.sl<ApiClient>());
  final _storeApiService = StoreApiService(apiClient: di.sl<ApiClient>());
  
  List<StoreModel> _stores = [];
  StoreModel? _selectedStore;
  bool _isLoadingStores = false;

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    setState(() => _isLoadingStores = true);
    try {
      final stores = await _storeApiService.getStores();
      setState(() {
        _stores = stores;
      });
    } catch (e) {
      debugPrint('Error fetching stores for banner: $e');
    } finally {
      setState(() => _isLoadingStores = false);
    }
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih toko terlebih dahulu'), backgroundColor: Colors.orange));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final length = double.parse(_lengthCtrl.text.trim().replaceAll(',', '.'));
      final width = double.parse(_widthCtrl.text.trim().replaceAll(',', '.'));
      
      final payload = {
        'store_name': _selectedStore!.name,
        'size': length * width, // Calculate total area in m2
        'notes': 'Ukuran: $length x $width m. ${_notesCtrl.text.trim()}',
      };

      await _apiService.createBannerOrder(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Spanduk berhasil dikirim'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REQUEST BARU', style: GoogleFonts.outfit(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text('Order Spanduk', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Pastikan ukuran akurat. Tim marketing akan memverifikasi request ini sebelum dicetak.', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('INFORMASI SPANDUK', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih Toko *', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.blueGrey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<StoreModel>(
                          isExpanded: true,
                          value: _selectedStore,
                          hint: Text(_isLoadingStores ? 'Memuat toko...' : 'Pilih Toko...', style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14)),
                          items: _stores.map((store) {
                            return DropdownMenuItem(
                              value: store,
                              child: Text(store.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedStore = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField('Panjang (m) *', '0.0', _lengthCtrl, Icons.height_rounded, isDecimal: true),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildField('Lebar (m) *', '0.0', _widthCtrl, Icons.width_normal_rounded, isDecimal: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField('Catatan Tambahan', 'Tulis pesan atau konten...', _notesCtrl, Icons.notes_rounded, required: false, maxLines: 3),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                    shadowColor: Colors.blueAccent.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('SUBMIT ORDER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, IconData icon, {bool required = true, bool isDecimal = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
          child: Icon(icon, color: Colors.blueAccent, size: 20),
        ),
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.blueGrey, fontSize: 13),
        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Field ini wajib diisi';
        if (isDecimal && v != null && v.isNotEmpty) {
          if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Harus berupa angka (contoh: 2.5)';
        }
        return null;
      },
    );
  }
}
