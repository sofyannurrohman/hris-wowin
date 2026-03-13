import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/overtime/domain/entities/overtime.dart';
import 'package:hris_app/features/overtime/presentation/bloc/overtime_event.dart';
import 'package:intl/intl.dart';
import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_event.dart';
import '../bloc/overtime_state.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';

class OvertimeRequestPage extends StatefulWidget {
  final Overtime? overtimeToEdit;
  const OvertimeRequestPage({super.key, this.overtimeToEdit});

  @override
  State<OvertimeRequestPage> createState() => _OvertimeRequestPageState();
}

class _OvertimeRequestPageState extends State<OvertimeRequestPage> {
  String _selectedChip = 'Project Alpha';
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);

  bool get _isEditing => widget.overtimeToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final ot = widget.overtimeToEdit!;
      _selectedDate = ot.date;
      _startTime = TimeOfDay.fromDateTime(ot.startTime);
      _endTime = TimeOfDay.fromDateTime(ot.endTime);
      
      // Attempt to extract chip from reason [Project Alpha] reason text
      if (ot.reason.startsWith('[') && ot.reason.contains('] ')) {
        final split = ot.reason.split('] ');
        _selectedChip = split[0].substring(1);
        _reasonController.text = split.sublist(1).join('] ');
      } else {
        _reasonController.text = ot.reason;
      }
    }
  }

  int get _durationMinutes {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    var end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);
    
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    
    return end.difference(start).inMinutes;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime24h(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _submitRequest() {
    if (_reasonController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Mohon isi alasan lembur');
      return;
    }

    final fullReason = '[$_selectedChip] ${_reasonController.text.trim()}';

    final startDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _startTime.hour, _startTime.minute,
    );
    
    var endDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _endTime.hour, _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    if (_isEditing) {
      context.read<OvertimeBloc>().add(UpdateOvertimeRequested(
        id: widget.overtimeToEdit!.id,
        date: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        durationMinutes: _durationMinutes,
        reason: fullReason,
      ));
    } else {
      context.read<OvertimeBloc>().add(SubmitOvertimeRequested(
        date: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        durationMinutes: _durationMinutes,
        reason: fullReason,
      ));
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B60F1);
    const bgGray = Color(0xFFF9FAFB);
    const textColor = Color(0xFF111827);
    const subtitleColor = Color(0xFF6B7280);
    const borderColor = Color(0xFFE5E7EB);

    return BlocListener<OvertimeBloc, OvertimeState>(
      listener: (context, state) {
        if (state is OvertimeLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        } else if (state is OvertimeSuccess) {
          Navigator.of(context).pop(); // dismiss loading
          SnackBarUtils.showSuccess(context, state.message);
          Navigator.of(context).pop(); // go back
        } else if (state is OvertimeFailure) {
          Navigator.of(context).pop(); // dismiss loading
          SnackBarUtils.showError(context, state.errorMessage);
        }
      },
      child: Scaffold(
        backgroundColor: bgGray,
        appBar: AppBar(
          title: Text(_isEditing ? 'Ubah Pengajuan' : 'Pengajuan Lembur',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanggal
                _buildLabel('Pilih Tanggal'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: _buildDropdownField(
                    DateFormat('dd MMMM yyyy').format(_selectedDate),
                    Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(height: 24),

                // Waktu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Waktu Lembur'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Text(
                        'Total ${(_durationMinutes / 60).toStringAsFixed(1)} Jam',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFEA580C)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mulai', style: GoogleFonts.inter(fontSize: 12, color: subtitleColor)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _selectTime(context, true),
                            child: _buildDropdownField(_formatTime24h(_startTime), Icons.access_time),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selesai', style: GoogleFonts.inter(fontSize: 12, color: subtitleColor)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _selectTime(context, false),
                            child: _buildDropdownField(_formatTime24h(_endTime), Icons.access_time),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Proyek / Alasan
                _buildLabel('Proyek / Alasan'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  style: GoogleFonts.inter(fontSize: 15, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Tuliskan detail pekerjaan lembur...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 15),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('Project Alpha'),
                    _buildChip('Maintenance'),
                    _buildChip('Urgent Fix'),
                    _buildChip('Lainnya'),
                  ],
                ),
                const SizedBox(height: 32),

                // Estimasi Upah Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF387BFF), Color(0xFF104FD4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimasi Upah Lembur',
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Perkiraan upah tambahan',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                      Text(
                        'Rp ${NumberFormat.decimalPattern('id').format((_durationMinutes / 60) * 50000)}',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        bottomSheet: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _isEditing ? 'Simpan Perubahan' : 'Ajukan Lembur',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
    );
  }

  Widget _buildDropdownField(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
              const SizedBox(width: 12),
              Text(text, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827))),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedChip == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChip = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF2FF) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF1B60F1) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF1B60F1) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
