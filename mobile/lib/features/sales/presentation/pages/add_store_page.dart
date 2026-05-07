import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';
import 'package:hris_app/features/sales/data/services/store_api_service.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/network/api_client.dart';

class AddStorePage extends StatefulWidget {
  final StoreModel? existingStore;
  const AddStorePage({super.key, this.existingStore});

  @override
  State<AddStorePage> createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLoading = false;
  String _selectedFrequency = 'F1';
  List<int> _selectedDays = [];
  final List<String> _frequencies = ['F1', 'F2', 'F4'];
  final List<String> _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final _apiService = StoreApiService(apiClient: di.sl<ApiClient>());

  @override
  void initState() {
    super.initState();
    if (widget.existingStore != null) {
      _nameCtrl.text = widget.existingStore!.name;
      _ownerCtrl.text = widget.existingStore!.ownerName;
      _addressCtrl.text = widget.existingStore!.address;
      _selectedFrequency = widget.existingStore!.visitFrequency.isNotEmpty ? widget.existingStore!.visitFrequency : 'F1';
      _selectedDays = List<int>.from(widget.existingStore!.visitDays);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'owner_name': _ownerCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        // mock lat/long for now
        'latitude': -7.250445,
        'longitude': 112.768845,
        'is_new': widget.existingStore == null ? true : widget.existingStore!.isNew,
        'visit_frequency': _selectedFrequency,
        'visit_days': _selectedDays,
      };

      if (widget.existingStore != null) {
        await _apiService.updateStore(widget.existingStore!.id, payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toko berhasil diperbarui'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        final store = await _apiService.createStore(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toko baru berhasil ditambahkan'), backgroundColor: Colors.green));
          Navigator.pop(context, store); // Return store if navigating from SelectStorePage
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan toko: $e'), backgroundColor: Colors.red));
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
            Text(widget.existingStore != null ? 'EDIT TOKO' : 'TAMBAH TOKO BARU', style: GoogleFonts.outfit(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text('Data Toko Kunjungan', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
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
              _buildInfoBanner(),
              const SizedBox(height: 24),
              _buildSection('Informasi Toko', [
                _buildField('Nama Toko *', 'Contoh: Toko Makmur Jaya', _nameCtrl, Icons.storefront_rounded),
                const SizedBox(height: 16),
                _buildField('Nama Pemilik *', 'Contoh: Pak Budi', _ownerCtrl, Icons.person_rounded),
                const SizedBox(height: 16),
                _buildField('No. HP Pemilik', 'Contoh: 0812XXXXXXXX', _phoneCtrl, Icons.phone_rounded, required: false, keyboardType: TextInputType.phone),
              ]),
              const SizedBox(height: 24),
              _buildSection('Lokasi Toko', [
                _buildField('Alamat Lengkap *', 'Jl. Nama Jalan No., Kota', _addressCtrl, Icons.location_on_rounded, maxLines: 3),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.2))),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: Colors.green, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Koordinat GPS', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF1E293B))),
                            Text('GPS akan diambil otomatis saat Anda check-in di toko.', style: GoogleFonts.outfit(fontSize: 11, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection('Penjadwalan Kunjungan', [
                Text('Frekuensi Kunjungan', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1E293B))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _selectedFrequency = v!),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.repeat_rounded, color: Colors.blueAccent, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Hari Kunjungan', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1E293B))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final dayNum = index + 1;
                    final isSelected = _selectedDays.contains(dayNum);
                    return ChoiceChip(
                      label: Text(_dayNames[index]),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      labelStyle: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(dayNum);
                          } else {
                            _selectedDays.remove(dayNum);
                          }
                        });
                      },
                    );
                  }),
                ),
              ]),
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
                      : Text('SIMPAN & LANJUTKAN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('Toko baru akan langsung masuk ke daftar rayon Anda setelah disimpan.', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, IconData icon,
      {bool required = true, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.blueGrey, fontSize: 13),
        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Field ini wajib diisi' : null : null,
    );
  }
}
