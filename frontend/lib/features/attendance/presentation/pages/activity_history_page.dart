import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
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
    const primaryBlue = Color(0xFF1B60F1);
    const bgGray = Color(0xFFF9FAFB);
    const textColor = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        title: Text('Activity History', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      ),
      body: SafeArea(
        child: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            if (state is AttendanceLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AttendanceFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(state.errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ),
              );
            }

            if (state is AttendanceHistoryFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ),
              );
            }

            if (state is HomeDataFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
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
                              const Center(child: Text('Tidak ada riwayat kehadiran')),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 150),
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
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat riwayat...'),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(String week, String dateRange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(week, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF), letterSpacing: 1.0)),
        Text(dateRange, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF))),
      ],
    );
  }

  Widget _buildHistoryCard(dynamic record) {
    final checkIn = record.checkIn as DateTime;
    final checkOut = record.checkOut as DateTime?;
    
    final dayStr = DateFormat('EEE').format(checkIn);
    final dateStr = DateFormat('dd').format(checkIn);
    final monthStr = DateFormat('MMM').format(checkIn);
    
    final checkInTimeStr = DateFormat('hh:mm a').format(checkIn);
    final checkOutTimeStr = checkOut != null ? DateFormat('hh:mm a').format(checkOut) : '--:--';
    
    final durationHours = record.workDuration / 60; // Assuming workDuration is in minutes
    final durationStr = '${durationHours.toStringAsFixed(1)}h';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Date Column
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(dayStr, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                Text(monthStr, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
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
                    _buildBadge('Regular', Colors.green),
                    if (record.status == 'late') ...[
                      const SizedBox(width: 8),
                      _buildBadge('Late In', Colors.orange),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text('$checkInTimeStr - $checkOutTimeStr', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563), fontWeight: FontWeight.w500)),
                  ],
                )
              ],
            ),
          ),
          
          // Total Time
          Text(durationStr, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color.shade700)),
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
