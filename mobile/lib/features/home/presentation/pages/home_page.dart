import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/features/attendance/presentation/pages/face_verification_page.dart';
import 'package:hris_app/core/utils/dialog_utils.dart';
import 'package:hris_app/features/attendance/presentation/pages/attendance_page.dart';
import 'package:hris_app/features/attendance/presentation/pages/activity_history_page.dart';
import 'package:hris_app/features/leave/presentation/pages/leave_page.dart';
import 'package:hris_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:hris_app/features/kpi/presentation/bloc/kpi_bloc.dart';
import 'package:hris_app/features/kpi/presentation/pages/kpi_page.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:hris_app/core/utils/constants.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:hris_app/features/payroll/presentation/bloc/payroll_bloc.dart';
import 'package:hris_app/features/payroll/presentation/pages/payslip_list_page.dart';
import 'package:hris_app/features/overtime/presentation/bloc/overtime_bloc.dart';
import 'package:hris_app/features/overtime/presentation/pages/overtime_list_page.dart';
import 'package:hris_app/features/profile/presentation/pages/face_registration_page.dart';
import 'package:hris_app/features/schedule/presentation/bloc/shift_bloc.dart';
import 'package:hris_app/features/schedule/presentation/pages/shift_page.dart';
import 'package:hris_app/features/profile/presentation/pages/profile_overview_page.dart';
import 'package:hris_app/features/directory/presentation/pages/directory_page.dart';
import 'package:hris_app/features/directory/presentation/bloc/directory_bloc.dart';
import 'package:hris_app/features/approval/presentation/bloc/approval_bloc.dart';
import 'package:hris_app/features/approval/presentation/pages/approval_page.dart';
import 'package:hris_app/features/announcement/presentation/bloc/announcement_bloc.dart';
import 'package:hris_app/features/announcement/presentation/pages/announcement_detail_page.dart';
import 'package:hris_app/features/reimbursement/presentation/pages/reimbursement_list_page.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

import 'package:hris_app/features/announcement/presentation/pages/notification_list_page.dart';
import 'package:hris_app/features/notification/presentation/bloc/notification_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      drawer: _buildDrawer(),
      body: _buildPage(_currentIndex),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardTab();
      case 1:
        return const AttendancePage();
      case 2:
        return const LeavePage();
      case 3:
        return const ProfileOverviewPage();
      default:
        return const DashboardTab();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Presensi'),
          BottomNavigationBarItem(icon: Icon(Icons.event_available_rounded), label: 'Cuti'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          Map<String, dynamic>? profile;
          if (state is Authenticated) {
            profile = state.userProfile;
          }
          final name = '${profile?['first_name'] ?? 'User'}'.toUpperCase();
          final job = profile?['job_position']?['title'] ?? 'DASHBOARD PANEL';
          
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: (profile?['face_reference_url'] != null && profile!['face_reference_url'].toString().isNotEmpty)
                          ? Image.network(
                              profile['face_reference_url'].toString().startsWith('http') 
                                  ? profile['face_reference_url'] 
                                  : '${Uri.parse(AppConstants.baseUrl).origin}${profile['face_reference_url'].toString().startsWith('/') ? profile['face_reference_url'] : '/${profile['face_reference_url']}'}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40, color: AppColors.primaryRed),
                            )
                          : const Icon(Icons.person, size: 40, color: AppColors.primaryRed),
                    ),
                    const SizedBox(height: 16),
                    const Text('MENU UTAMA', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    Text(job.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text('ADMINISTRASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5)),
                    ),
                    _buildDrawerItem(Icons.payments_rounded, 'Slip Gaji Digital', () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => di.sl<PayrollBloc>(), child: const PayslipListPage())));
                    }),
                    _buildDrawerItem(Icons.timer_rounded, 'Lembur', () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => di.sl<OvertimeBloc>(), child: const OvertimeListPage())));
                    }),
                    _buildDrawerItem(Icons.receipt_long_rounded, 'Reimbursement', () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReimbursementListPage()));
                    }),
                    _buildDrawerItem(Icons.face_retouching_natural_rounded, 'Registrasi Wajah', () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaceRegistrationPage()));
                    }),
                    _buildDrawerItem(Icons.trending_up_rounded, 'KPI & Performa', () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => di.sl<KPIBloc>(), child: const KPIPage())));
                    }),
                    _buildDrawerItem(Icons.calendar_month_rounded, 'Jadwal Shift', () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => di.sl<ShiftBloc>(), child: const ShiftPage())));
                    }),
                    _buildDrawerItem(Icons.contact_phone_rounded, 'Direktori Karyawan', () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => di.sl<DirectoryBloc>(), child: const DirectoryPage())));
                    }),
                    if (profile?['user']?['role'] != 'employee')
                      _buildDrawerItem(Icons.verified_user_rounded, 'Approval Panel', () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => di.sl<ApprovalBloc>(), child: const ApprovalPage())));
                      }, color: AppColors.primaryRed),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: InkWell(
                  onTap: () => _showLogoutConfirmation(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.error),
                        const SizedBox(width: 16),
                        Text('Keluar Akun', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 24),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar Akun?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textTertiary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('KELUAR', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }
        
        Map<String, dynamic>? profile;
        List<Attendance> recentActivity = [];
        Map<String, dynamic>? statistics;

        // Get profile from AuthBloc for stability
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          profile = authState.userProfile;
        }

        if (state is HomeDataLoaded) {
          // stats/history still come from AttendanceBloc
          recentActivity = state.recentActivity;
          statistics = state.statistics;
          // If AttendanceBloc also has profile, it can override
          if (state.profile != null) profile = state.profile;
        } else if (state is AttendanceHistoryLoaded) {
          recentActivity = state.history;
          if (state.profile != null) profile = state.profile;
          if (state.statistics != null) statistics = state.statistics;
        }

        String displayName = '';
        if (profile != null) {
          final firstName = profile['first_name'] ?? profile['FirstName'] ?? '';
          final lastName = profile['last_name'] ?? profile['LastName'] ?? '';
          displayName = '$firstName $lastName'.trim();
          
          // Fallback if split first/last not found
          if (displayName.isEmpty) {
            displayName = profile['name'] ?? profile['Name'] ?? profile['full_name'] ?? '';
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AttendanceBloc>().add(FetchHomeDataRequested());
          },
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, profile, displayName),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatistics(statistics),
                      const SizedBox(height: 32),
                      _buildQuickActions(context, state.attendanceStatus),
                      const SizedBox(height: 40),
                      _buildAnnouncements(context),
                      const SizedBox(height: 40),
                      _buildRecentActivity(recentActivity),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic>? profile, String displayName) {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryRed,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selamat Datang,',
                style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1),
              ),
              Text(
                (displayName.isNotEmpty ? displayName : 'User').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            final hasNotifications = state is NotificationLoaded && state.notifications.isNotEmpty;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), 
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NotificationListPage()),
                    );
                  }
                ),
                if (hasNotifications)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8, 
                      height: 8, 
                      decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: AppColors.primaryRed, width: 1))),
                    ),
                  ),
              ],
            );
          }
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatistics(Map<String, dynamic>? stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RINGKASAN KEHADIRAN ANDA', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildRedStatItem('HADIR', stats?['PresentCount']?.toString() ?? '0', Icons.check_circle_rounded)),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(child: _buildRedStatItem('CUTI', stats?['LeaveCount']?.toString() ?? '0', Icons.event_available_rounded)),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(child: _buildRedStatItem('ALFA', stats?['AlphaCount']?.toString() ?? '0', Icons.error_rounded)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRedStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AttendanceStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AKSES CEPAT', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              Icons.qr_code_scanner_rounded, 
              'Absen Masuk', 
              AppColors.success, 
              () {
                if (status == AttendanceStatus.clockedIn || status == AttendanceStatus.completed) {
                  DialogUtils.showError(
                    context: context, 
                    title: 'Sudah Absen', 
                    message: 'Sudah absen masuk hari ini',
                  );
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaceVerificationPage(isClockIn: true)));
                }
              },
              isDisabled: status == AttendanceStatus.clockedIn || status == AttendanceStatus.completed,
            ),
            _buildActionItem(
              Icons.logout_rounded, 
              'Absen Keluar', 
              AppColors.primaryRed, 
              () {
                if (status == AttendanceStatus.none) {
                  DialogUtils.showError(
                    context: context, 
                    title: 'Belum Absen', 
                    message: 'Anda belum melakukan absen masuk hari ini',
                  );
                } else if (status == AttendanceStatus.completed) {
                  DialogUtils.showError(
                    context: context, 
                    title: 'Sudah Absen', 
                    message: 'Anda sudah melakukan absen keluar hari ini',
                  );
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaceVerificationPage(isClockIn: false)));
                }
              },
              isDisabled: status == AttendanceStatus.none || status == AttendanceStatus.completed,
            ),
            _buildActionItem(Icons.history_rounded, 'Riwayat', AppColors.warning, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityHistoryPage()))),
            _buildActionItem(Icons.event_available_rounded, 'Cuti', const Color(0xFF6366F1), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeavePage()))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap, {bool isDisabled = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isDisabled ? Colors.grey.shade200 : color.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: (isDisabled ? Colors.grey.shade400 : color), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label, 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, 
              fontWeight: FontWeight.w600, 
              color: (isDisabled ? AppColors.textTertiary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncements(BuildContext context) {
    return BlocBuilder<AnnouncementBloc, AnnouncementState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PENGUMUMAN', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NotificationListPage()),
                    );
                  }, 
                  child: Text('Lihat Semua', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryRed))
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state is AnnouncementLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
            else if (state is AnnouncementLoaded && state.announcements.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.announcements.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final ann = state.announcements[index];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AnnouncementDetailPage(announcement: ann),
                        ),
                      ),
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8), 
                                  decoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.1), shape: BoxShape.circle), 
                                  child: const Icon(Icons.campaign_rounded, color: AppColors.primaryRed, size: 18)
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(ann.title.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(ann.content, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, height: 1.6), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd MMM yyyy').format(ann.createdAt), style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
                                Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryRed.withOpacity(0.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              _buildEmptyPlaceholder(Icons.campaign_outlined, 'Belum ada pengumuman hari ini'),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity(List<Attendance> activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AKTIVITAS TERBARU', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        if (activity.isEmpty)
          _buildEmptyPlaceholder(Icons.history_rounded, 'Belum ada riwayat absensi')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activity.length > 5 ? 5 : activity.length,
            itemBuilder: (context, index) {
              final att = activity[index];
              final isAlfa = att.status == 'ALFA';
              final isClockIn = att.checkOut == null && !isAlfa;
              
              Color statusColor;
              if (isAlfa) {
                statusColor = AppColors.warning;
              } else if (isClockIn) {
                statusColor = AppColors.success;
              } else {
                statusColor = AppColors.primaryRed;
              }

              IconData statusIcon;
              if (isAlfa) {
                statusIcon = Icons.cancel_outlined;
              } else if (isClockIn) {
                statusIcon = Icons.login_rounded;
              } else {
                statusIcon = Icons.logout_rounded;
              }

              String title;
              if (isAlfa) {
                title = 'Tidak Absen (ALFA)';
              } else if (isClockIn) {
                title = 'Absen Masuk';
              } else {
                title = 'Absen Keluar';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: statusColor, width: 5)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                          child: Icon(statusIcon, color: statusColor, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(DateFormat('dd MMMM yyyy').format(att.checkIn), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Text(isAlfa ? '--:--' : DateFormat('HH:mm').format(att.checkOut ?? att.checkIn), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grayBorder, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textTertiary.withOpacity(0.2), size: 40),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
