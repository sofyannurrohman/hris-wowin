import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/features/attendance/presentation/pages/face_verification_page.dart';
import 'package:hris_app/features/attendance/presentation/pages/clock_in_failed_page.dart';
import 'package:hris_app/features/attendance/presentation/pages/activity_history_page.dart';
import 'package:hris_app/features/leave/presentation/pages/leave_page.dart';
import 'package:hris_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:hris_app/features/overtime/presentation/pages/overtime_request_page.dart';
import 'package:hris_app/features/overtime/presentation/pages/overtime_list_page.dart';
import 'package:hris_app/features/overtime/presentation/bloc/overtime_bloc.dart';
import 'package:hris_app/features/profile/presentation/pages/face_registration_page.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_app/core/utils/constants.dart';
import 'package:hris_app/features/payroll/presentation/bloc/payroll_bloc.dart';
import 'package:hris_app/features/payroll/presentation/pages/payslip_list_page.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
// Note: LeavePage, ProfilePage, etc. imports would go here based on navigation needs.

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(FetchHomeDataRequested());
  }

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
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
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }



  void _onClockInPressed(Map<String, dynamic>? profile) async {
    try {
      await _takeSelfie(isClockIn: true, profile: profile);
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    }
  }

  void _onClockOutPressed(Map<String, dynamic>? profile) async {
    try {
      await _takeSelfie(isClockIn: false, profile: profile);
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    }
  }

  Future<void> _takeSelfie({required bool isClockIn, Map<String, dynamic>? profile}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FaceVerificationPage(
          isClockIn: isClockIn,
          userProfile: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B60F1);
    const bgGray = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgGray,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(primaryBlue),
          const ActivityHistoryPage(),
          const LeavePage(),
          const EditProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Pengajuan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(Color primaryBlue) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSuccess) {
          context.read<AttendanceBloc>().add(FetchHomeDataRequested());
          SnackBarUtils.showSuccess(context, state.message);
        } else if (state is AttendanceFailure) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClockInFailedPage(errorMessage: state.errorMessage)));
        }
      },
      child: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading && state is! HomeDataLoaded) {
            return _buildShimmerDashboard();
          }

          Map<String, dynamic>? profile;
          AttendanceStats? stats;
          List<Attendance> history = [];

          if (state is HomeDataLoaded) {
            profile = state.profile;
            stats = state.stats;
            history = state.history;
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<AttendanceBloc>().add(FetchHomeDataRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AnimationLimiter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildGreeting(
                            profile?['FirstName'] ?? 'User',
                            faceUrl: profile?['FaceReferenceURL'],
                          ),
                          const SizedBox(height: 24),
                          _buildMainActionCard(context, primaryBlue, history, profile),
                          const SizedBox(height: 24),
                          _buildStatsGrid(stats),
                          const SizedBox(height: 24),
                          _buildRecentActivityHeader(context, primaryBlue),
                          const SizedBox(height: 12),
                          _buildRecentActivityList(history),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business, color: Color(0xFF1B60F1)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PT Wowin Poernomo Putra',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                ),
                Text(
                  'Employee Portal',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ]),
              child: const Icon(Icons.notifications_none, color: Color(0xFF111827)),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ]),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                onPressed: () => _showLogoutConfirmation(context),
              ),
            ),
          ],
        )
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin keluar dari akun ini?', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: Text('Logout', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGreeting(String name, {String? faceUrl}) {
    final dateStr = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());
    
    // Construct the full URL if faceUrl is relative
    final String? fullFaceUrl = (faceUrl != null && faceUrl.isNotEmpty) 
        ? (faceUrl.startsWith('http') ? faceUrl : '${Uri.parse(AppConstants.baseUrl).origin}${faceUrl.startsWith('/') ? faceUrl : '/$faceUrl'}')
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $name!',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFFFDCA8),
          backgroundImage: fullFaceUrl != null ? NetworkImage(fullFaceUrl) : null,
          child: fullFaceUrl == null 
            ? const Icon(Icons.person, color: Colors.orange, size: 32)
            : null, // If image fails, you might want to handle it, but for now this is fine.
        )
      ],
    );
  }

  Widget _buildMainActionCard(BuildContext context, Color primaryBlue, List<Attendance> history, Map<String, dynamic>? profile) {
    final timeStr = DateFormat('hh : mm').format(_currentTime);
    final amPmStr = DateFormat('a').format(_currentTime);

    bool hasClockedIn = false;
    if (history.isNotEmpty) {
      final todayRecord = history.first;
      if (todayRecord.checkIn.day == DateTime.now().day && todayRecord.checkOut == null) {
        hasClockedIn = true;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Shift: 07:30 - 16:30',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF111827), letterSpacing: -1),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  amPmStr,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => hasClockedIn ? _onClockOutPressed(profile) : _onClockInPressed(profile),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF387BFF), Color(0xFF104FD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(hasClockedIn ? Icons.logout : Icons.camera_alt, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    hasClockedIn ? 'Clock Out' : 'Clock In',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (!hasClockedIn)
                    Text(
                      'Selfie Diperlukan',
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => di.sl<PayrollBloc>(),
                      child: const PayslipListPage(),
                    ),
                  ),
                );
              },
              icon: Icon(Icons.receipt_long, color: primaryBlue),
              label: Text('Slip Gaji', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: primaryBlue)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF0F5FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => di.sl<OvertimeBloc>(),
                      child: const OvertimeListPage(),
                    ),
                  ),
                );
              },
              icon: Icon(Icons.history_toggle_off, color: primaryBlue),
              label: Text('Ajukan Lembur', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: primaryBlue)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF0F5FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaceRegistrationPage()));
              },
              icon: Icon(Icons.face, color: Colors.orange),
              label: Text('Registrasi Wajah', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.orange)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280), size: 16),
              const SizedBox(width: 6),
              Text(
                'Pandeyan, Karanganyar',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AttendanceStats? stats) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(Icons.access_time, Colors.blue, '${stats?.totalHours.toStringAsFixed(1) ?? "0"}h', 'Total Jam'),
        _buildStatCard(Icons.watch_later_outlined, Colors.purple, '${stats?.overtimeHours.toStringAsFixed(1) ?? "0"}h', 'Lembur'),
        _buildStatCard(Icons.calendar_month, Colors.green, '${stats?.attendanceDays ?? "0"}d', 'Hadir'),
        _buildStatCard(Icons.beach_access_outlined, Colors.orange, '${stats?.leaveDays ?? "0"}d', 'Cuti'),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, Color color, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context, Color primaryBlue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityHistoryPage()));
          },
          child: Text(
            'View All',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primaryBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(List<Attendance> history) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Tidak ada aktivitas terbaru', style: GoogleFonts.inter(color: Colors.grey)),
        ),
      );
    }
    return Column(
      children: history.take(3).map((record) {
        final isClockIn = record.status != 'checkout'; // Simplified check
        return _buildActivityTile(
          icon: isClockIn ? Icons.login : Icons.logout,
          isClockIn: isClockIn,
          title: isClockIn ? 'Clock In' : 'Clock Out',
          dateStr: DateFormat('MMM dd').format(record.checkIn),
          timeStr: DateFormat('hh:mm a').format(isClockIn ? record.checkIn : (record.checkOut ?? record.checkIn)),
          status: record.status.toLowerCase() == 'on_time' ? 'On Time' : (record.status.toLowerCase() == 'late' ? 'Late' : 'On Time'),
          statusColor: record.status.toLowerCase() == 'late' ? Colors.orange : Colors.green,
        );
      }).toList(),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required bool isClockIn,
    required String title,
    required String dateStr,
    required String timeStr,
    required String status,
    required Color statusColor,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isClockIn ? const Color(0xFFF0F5FF) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isClockIn ? const Color(0xFF1B60F1) : const Color(0xFF4B5563), size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(dateStr, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeStr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildShimmerDashboard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 150, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 32),
            Container(width: 200, height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 280, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: List.generate(4, (index) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
            ),
          ],
        ),
      ),
    );
  }
}
