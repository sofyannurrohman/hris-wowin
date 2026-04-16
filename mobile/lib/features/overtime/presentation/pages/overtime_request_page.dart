import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/overtime/domain/entities/overtime.dart';
import 'package:hris_app/features/overtime/presentation/bloc/overtime_event.dart';
import 'package:intl/intl.dart';
import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_state.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:hris_app/core/theme/app_colors.dart';

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
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryRed, onPrimary: Colors.white, onSurface: AppColors.textPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
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
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryRed, onPrimary: Colors.white, onSurface: AppColors.textPrimary),
          ),
          child: child!,
        );
      },
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
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _submitRequest() {
    if (_reasonController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Mohon isi detail pekerjaan lembur.');
      return;
    }

    final fullReason = '[$_selectedChip] ${_reasonController.text.trim()}';
    final startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    var endDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);

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
    return BlocListener<OvertimeBloc, OvertimeState>(
      listener: (context, state) {
        if (state is OvertimeSuccess) {
          SnackBarUtils.showSuccess(context, state.message);
          Navigator.of(context).pop();
        } else if (state is OvertimeFailure) {
          SnackBarUtils.showError(context, state.errorMessage);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundAlt,
        appBar: AppBar(
          title: Text(_isEditing ? 'Ubah Pengajuan' : 'Pengajuan Lembur',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 0.5)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('WAKTU & TANGGAL'),
              const SizedBox(height: 12),
              _buildTimeDateCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('PROYEK & DETAIL PEKERJAAN'),
              const SizedBox(height: 12),
              _buildReasonCard(),
              const SizedBox(height: 32),
              _buildEstimationCard(),
              const SizedBox(height: 48),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5));
  }

  Widget _buildTimeDateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grayBorder),
      ),
      child: Column(
        children: [
          _buildClickableField('TANGGAL', DateFormat('dd MMMM yyyy').format(_selectedDate), Icons.calendar_today_rounded, () => _selectDate(context)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          Row(
            children: [
              Expanded(child: _buildClickableField('MULAI', _formatTime24h(_startTime), Icons.access_time_filled_rounded, () => _selectTime(context, true))),
              Container(width: 1, height: 40, color: AppColors.grayBorder, margin: const EdgeInsets.symmetric(horizontal: 16)),
              Expanded(child: _buildClickableField('SELESAI', _formatTime24h(_endTime), Icons.access_time_rounded, () => _selectTime(context, false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickableField(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
          Icon(icon, size: 20, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildReasonCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.grayBorder)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: ['Project Alpha', 'Maintenance', 'Urgent Fix', 'Lainnya'].map((chip) => _buildChip(chip)).toList(),
            ),
          ),
          const Divider(height: 1),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Tuliskan detail pekerjaan lembur...',
              hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5), fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedChip == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedChip = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primaryRed : AppColors.grayBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSelected ? AppColors.primaryRed : AppColors.textTertiary)),
      ),
    );
  }

  Widget _buildEstimationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryRed.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ESTIMASI UPAH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('${(_durationMinutes / 60).toStringAsFixed(1)} Jam Lembur', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          Text(
            'Rp ${NumberFormat.decimalPattern('id').format((_durationMinutes / 60) * 50000)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<OvertimeBloc, OvertimeState>(
      builder: (context, state) {
        final isLoading = state is OvertimeLoading;
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: AppColors.primaryRed.withOpacity(0.4),
            ),
            child: isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text(_isEditing ? 'SIMPAN PERUBAHAN' : 'AJUKAN LEMBUR', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5, fontSize: 13)),
          ),
        );
      },
    );
  }
}
