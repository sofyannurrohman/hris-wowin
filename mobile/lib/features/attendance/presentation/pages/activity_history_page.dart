import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(const FetchHistoryRequested());
  }
  // Dummy data to match mockup perfectly
  final List<Map<String, dynamic>> _dummyHistory = [
    {
      'date': '12',
      'day': 'Thu',
      'month': 'Oct',
      'isLate': false,
      'isOvertime': false,
      'overtimeHours': null,
      'checkIn': '08:00 AM',
      'checkOut': '17:00 PM',
      'totalTime': '8h 0m',
    },
    {
      'date': '11',
      'day': 'Wed',
      'month': 'Oct',
      'isLate': true,
      'isOvertime': false,
      'overtimeHours': null,
      'checkIn': '08:15 AM',
      'checkOut': '17:00 PM',
      'totalTime': '7h 45m',
    },
    {
      'date': '10',
      'day': 'Tue',
      'month': 'Oct',
      'isLate': false,
      'isOvertime': true,
      'overtimeHours': '+2h',
      'checkIn': '08:00 AM',
      'checkOut': '19:00 PM',
      'totalTime': '10h 0m',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        title: const Text('RIWAYAT AKTIVITAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.textPrimary)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      ),
      body: SafeArea(
        child: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            if (state is AttendanceLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
            }

            if (state is AttendanceFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                ),
              );
            }

            if (state is AttendanceHistoryFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                ),
              );
            }

            if (state is HomeDataFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                ),
              );
            }

            if (state is AttendanceHistoryLoaded || state is HomeDataLoaded) {
              final List<Attendance> history = (state is AttendanceHistoryLoaded) 
                  ? state.history 
                  : (state as HomeDataLoaded).history;
              
              return Column(
                children: [
                  _buildMonthSelector(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<AttendanceBloc>().add(const FetchHistoryRequested());
                      },
                      child: history.isEmpty 
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                              const Center(child: Text('Tidak ada riwayat kehadiran', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600))),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(bottom: 120),
                            itemCount: history.length,
                            itemBuilder: (context, index) => _buildHistoryCard(history[index]),
                          ),
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryRed),
                  SizedBox(height: 16),
                  Text('Memuat riwayat...', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 12),
              Text(DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 1)),
            ],
          ),
          Icon(Icons.unfold_more_rounded, color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic record) {
    final checkIn = record.checkIn as DateTime;
    final checkOut = record.checkOut as DateTime?;
    
    final dayStr = DateFormat('EEE').format(checkIn).toUpperCase();
    final dateStr = DateFormat('dd').format(checkIn);
    final monthStr = DateFormat('MMM').format(checkIn).toUpperCase();
    
    final checkInTimeStr = DateFormat('HH:mm').format(checkIn);
    final checkOutTimeStr = checkOut != null ? DateFormat('HH:mm').format(checkOut) : '--:--';
    
    final durationHours = record.workDuration / 60; 
    final durationStr = '${durationHours.toStringAsFixed(1)} jam';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          // Date Column
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grayLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(dayStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 0.5)),
                Text(dateStr, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                Text(monthStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBadge('Regular', const Color(0xFF10B981)),
                    if (record.status.toLowerCase() == 'late') ...[
                      const SizedBox(width: 8),
                      _buildBadge('Terlambat', const Color(0xFFF97316)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text('$checkInTimeStr - $checkOutTimeStr', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Text('WIB', style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w800)),
                  ],
                )
              ],
            ),
          ),
          
          // Total Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(durationStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const Text('TOTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor, Color labelColor) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: valueColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: labelColor)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
