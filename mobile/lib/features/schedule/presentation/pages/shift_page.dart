import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/features/schedule/data/models/shift_model.dart';
import 'package:hris_app/features/schedule/presentation/bloc/shift_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ShiftPage extends StatefulWidget {
  const ShiftPage({super.key});

  @override
  State<ShiftPage> createState() => _ShiftPageState();
}

class _ShiftPageState extends State<ShiftPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ShiftSchedule> _allSchedules = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    context.read<ShiftBloc>().add(FetchSchedulesRequested(month: _focusedDay.month, year: _focusedDay.year));
  }

  ShiftSchedule? _getScheduleForDay(DateTime day) {
    try {
      return _allSchedules.firstWhere((s) => isSameDay(s.date, day));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        title: Text('JADWAL SHIFT', 
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, state) {
          if (state is ShiftLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShiftLoaded) {
            _allSchedules = state.schedules;
            final selectedSchedule = _getScheduleForDay(_selectedDay!);

            return Column(
              children: [
                _buildCalendar(),
                const SizedBox(height: 24),
                if (selectedSchedule != null)
                  _buildShiftDetail(selectedSchedule)
                else
                  _buildEmptyDetail(),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          context.read<ShiftBloc>().add(FetchSchedulesRequested(month: _focusedDay.month, year: _focusedDay.year));
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.1), shape: BoxShape.circle),
          todayTextStyle: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold),
          selectedDecoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
          markerDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
        ),
        eventLoader: (day) {
          final s = _getScheduleForDay(day);
          return (s != null && !s.isOffDay) ? [s] : [];
        },
      ),
    );
  }

  Widget _buildShiftDetail(ShiftSchedule s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: s.isOffDay ? Colors.grey[100] : AppColors.primaryRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: s.isOffDay ? Colors.grey[300]! : AppColors.primaryRed.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, d MMMM yyyy').format(s.date), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(s.shiftName, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: s.isOffDay ? AppColors.textPrimary : AppColors.primaryRed)),
                  ],
                ),
                Icon(s.isOffDay ? Icons.coffee_rounded : Icons.work_history_rounded, color: s.isOffDay ? Colors.grey : AppColors.primaryRed, size: 40),
              ],
            ),
            if (!s.isOffDay) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeInfo('Masuk', s.startTime),
                  Container(width: 1, height: 40, color: AppColors.grayBorder),
                  _buildTimeInfo('Pulang', s.endTime),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildEmptyDetail() {
    return Center(child: Text('Pilih tanggal untuk melihat detail shift.', style: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary)));
  }
}
