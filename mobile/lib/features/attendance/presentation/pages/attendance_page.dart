import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/features/attendance/presentation/pages/face_verification_page.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/core/utils/dialog_utils.dart';
import 'package:shimmer/shimmer.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    context.read<AttendanceBloc>().add(FetchHomeDataRequested());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return _buildLoadingState();
          }

          final status = state.attendanceStatus;
          final bool isClockedIn = status == AttendanceStatus.clockedIn;
          final bool isCompleted = status == AttendanceStatus.completed;

          Attendance? lastAttendance;
          if (state is HomeDataLoaded && state.history.isNotEmpty) {
            lastAttendance = state.history.first;
          }

          final String workDuration = _calculateWorkDuration(lastAttendance?.checkIn);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AttendanceBloc>().add(FetchHomeDataRequested());
            },
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTimerCard(isClockedIn, workDuration, lastAttendance, isCompleted),
                      const SizedBox(height: 32),
                      _buildMainActionButton(isClockedIn, isCompleted),
                      const SizedBox(height: 32),
                      _buildStatusIndicators(),
                      const SizedBox(height: 32),
                      _buildDailySummary(state),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primaryRed,
      elevation: 0,
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
                DateFormat('HH:mm:ss').format(_currentTime),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_currentTime).toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
      title: const Text('PRESENSI KERJA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
    );
  }

  Widget _buildTimerCard(bool isClockedIn, String duration, Attendance? lastAttendance, bool isCompleted) {
    final bool showCheckIn = isClockedIn || isCompleted;
    final bool showCheckOut = isCompleted;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grayBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHECK IN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    showCheckIn ? DateFormat('HH:mm').format(lastAttendance!.checkIn) : '--:--',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: AppColors.grayBorder,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('CHECK OUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    showCheckOut ? DateFormat('HH:mm').format(lastAttendance!.checkOut!) : '--:--',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Column(
            children: [
              Text(
                isClockedIn ? 'DURASI KERJA HARI INI' : 'STATUS TERAKHIR',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                isClockedIn ? duration : (isCompleted ? 'Sesi Terakhir Selesai' : 'Belum Absen'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isClockedIn ? const Color(0xFF10B981) : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(bool isClockedIn, bool isCompleted) {
    // If completed (already clocked out once today), we allow another Clock In for a new session
    final color = isClockedIn ? AppColors.primaryRed : const Color(0xFF10B981);

    return Center(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FaceVerificationPage(isClockIn: !isClockedIn),
            ),
          );
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color.withOpacity(0.1), width: 10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                isClockedIn ? 'CLOCK OUT' : (isCompleted ? 'NEW CLOCK IN' : 'CLOCK IN'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSmallIndicator(Icons.location_on_rounded, 'Location Ready', const Color(0xFF10B981)),
        const SizedBox(width: 16),
        _buildSmallIndicator(Icons.face_rounded, 'Biometric Active', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildSmallIndicator(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary(AttendanceState state) {
    List<Attendance> history = [];
    if (state is HomeDataLoaded) {
      history = state.history.where((a) => a.checkIn.day == DateTime.now().day).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AKTIVITAS HARI INI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.grayBorder),
            ),
            child: const Center(
              child: Text(
                'Belum ada aktivitas hari ini',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final att = history[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.grayBorder),
                ),
                child: Row(
                  children: [
                    _buildLogBadge(att.checkOut == null),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            att.checkOut == null ? 'Absen Masuk' : 'Absen Keluar',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm').format(att.checkOut ?? att.checkIn),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLogBadge(bool isCheckIn) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isCheckIn ? const Color(0xFF10B981) : AppColors.primaryRed).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
        color: isCheckIn ? const Color(0xFF10B981) : AppColors.primaryRed,
        size: 20,
      ),
    );
  }

  String _calculateWorkDuration(DateTime? checkIn) {
    if (checkIn == null) return "00:00:00";
    final duration = DateTime.now().difference(checkIn);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: AppColors.grayLight,
      highlightColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Center(child: Container(width: 200, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 32),
          Container(width: double.infinity, height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 32),
          Center(child: Container(width: 180, height: 180, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
        ],
      ),
    );
  }
}
