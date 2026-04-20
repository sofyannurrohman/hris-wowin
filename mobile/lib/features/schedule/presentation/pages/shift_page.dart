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
      body: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, state) {
          if (state is ShiftLoaded) {
            _allSchedules = state.schedules;
          }
          final selectedSchedule = _selectedDay != null ? _getScheduleForDay(_selectedDay!) : null;
          final todaySchedule = _getScheduleForDay(DateTime.now());

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(todaySchedule),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildCalendarContainer(),
                    const SizedBox(height: 12),
                    _buildDetailSection(selectedSchedule),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ShiftSchedule? todaySchedule) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primaryRed,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('JADWAL SHIFT', 
        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                todaySchedule != null ? todaySchedule.shiftName : 'OFF',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'SHIFT HARI INI',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarContainer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
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
          titleTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
          leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryRed),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryRed),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary, fontWeight: FontWeight.w700, fontSize: 12),
          weekendStyle: GoogleFonts.plusJakartaSans(color: AppColors.primaryRed, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          weekendTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.primaryRed),
          todayDecoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.1), shape: BoxShape.circle),
          todayTextStyle: GoogleFonts.plusJakartaSans(color: AppColors.primaryRed, fontWeight: FontWeight.w800),
          selectedDecoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
          selectedTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800),
          outsideDaysVisible: false,
          markerDecoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle),
        ),
        eventLoader: (day) {
          final s = _getScheduleForDay(day);
          return (s != null && !s.isOffDay) ? [s] : [];
        },
      ),
    );
  }

  Widget _buildDetailSection(ShiftSchedule? s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'DETAIL JADWAL',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          s != null ? _buildShiftDetailCard(s) : _buildEmptyDetail(),
        ],
      ),
    );
  }

  Widget _buildShiftDetailCard(ShiftSchedule s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: s.isOffDay ? AppColors.grayLight : AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  s.isOffDay ? Icons.coffee_rounded : Icons.work_history_rounded, 
                  color: s.isOffDay ? AppColors.textTertiary : AppColors.primaryRed, 
                  size: 28
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(s.date), 
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w700)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.shiftName, 
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!s.isOffDay)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AKTIF', 
                    style: GoogleFonts.plusJakartaSans(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w900)
                  ),
                ),
            ],
          ),
          if (!s.isOffDay) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1, color: AppColors.grayBorder),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo('JAM MASUK', s.startTime, Icons.login_rounded, AppColors.info),
                Container(width: 1, height: 40, color: AppColors.grayBorder),
                _buildTimeInfo('JAM PULANG', s.endTime, Icons.logout_rounded, AppColors.primaryRed),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color iconColor) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 8),
        Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildEmptyDetail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grayBorder, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.textTertiary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Pilih tanggal untuk melihat detail shift.', 
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }
}

