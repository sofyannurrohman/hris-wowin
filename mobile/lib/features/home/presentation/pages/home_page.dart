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
import 'package:hris_app/features/reimbursement/presentation/pages/reimbursement_list_page.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

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
          return const Center(child: CircularProgressIndicator());
        }
        
        Map<String, dynamic>? profile;
        List<Attendance> recentActivity = [];
        Map<String, dynamic>? statistics;

        if (state is HomeDataLoaded) {
          profile = state.profile;
          recentActivity = state.recentActivity;
          statistics = state.statistics;
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AttendanceBloc>().add(FetchHomeDataRequested());
          },
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(profile),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatistics(statistics),
                      const SizedBox(height: 32),
                      _buildQuickActions(context),
                      const SizedBox(height: 32),
                      _buildAnnouncements(context),
                      const SizedBox(height: 32),
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

  Widget _buildSliverAppBar(Map<String, dynamic>? profile) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
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
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('WOWIN', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
              Text('HRIS SYSTEM', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 2)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatistics(Map<String, dynamic>? stats) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('HADIR', stats?['PresentCount']?.toString() ?? '0', const Color(0xFF10B981))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('CUTI', stats?['LeaveCount']?.toString() ?? '0', const Color(0xFF3B82F6))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('ALFA', stats?['AlphaCount']?.toString() ?? '0', AppColors.primaryRed)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AKSES CEPAT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(Icons.qr_code_scanner_rounded, 'Masuk', const Color(0xFF10B981), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaceVerificationPage(isClockIn: true)))),
            _buildActionItem(Icons.logout_rounded, 'Keluar', AppColors.primaryRed, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaceVerificationPage(isClockIn: false)))),
            _buildActionItem(Icons.history_rounded, 'Riwayat', const Color(0xFFF59E0B), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityHistoryPage()))),
            _buildActionItem(Icons.event_available_rounded, 'Cuti', const Color(0xFF8B5CF6), () { /* Go to Leave tab */ }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildAnnouncements(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AnnouncementBloc>()..add(FetchAnnouncementsRequested()),
      child: BlocBuilder<AnnouncementBloc, AnnouncementState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PENGUMUMAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
                  TextButton(onPressed: () {}, child: const Text('Lihat Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryRed))),
                ],
              ),
              const SizedBox(height: 8),
              if (state is AnnouncementLoading)
                const Center(child: CircularProgressIndicator())
              else if (state is AnnouncementLoaded && state.announcements.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.announcements.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final ann = state.announcements[index];
                      return Container(
                        width: 280,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.grayBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.campaign_rounded, color: AppColors.primaryRed, size: 16)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(ann.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(ann.content, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Text(DateFormat('dd MMM yyyy').format(ann.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.grayBorder)),
                  child: const Column(
                    children: [
                      Icon(Icons.campaign_outlined, color: AppColors.textTertiary, size: 32),
                      SizedBox(height: 12),
                      Text('Belum ada pengumuman hari ini', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentActivity(List<Attendance> activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AKTIVITAS TERBARU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (activity.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.grayBorder)),
            child: const Column(
              children: [
                Icon(Icons.history_rounded, color: AppColors.textTertiary, size: 32),
                SizedBox(height: 12),
                Text('Belum ada riwayat absensi', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activity.length > 5 ? 5 : activity.length,
            itemBuilder: (context, index) {
              final att = activity[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grayBorder)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: (att.checkOut == null ? const Color(0xFF10B981) : AppColors.primaryRed).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                      child: Icon(att.checkOut == null ? Icons.login_rounded : Icons.logout_rounded, color: att.checkOut == null ? const Color(0xFF10B981) : AppColors.primaryRed, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(att.checkOut == null ? 'Absen Masuk' : 'Absen Keluar', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(DateFormat('dd MMMM yyyy').format(att.checkIn), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Text(DateFormat('HH:mm').format(att.checkOut ?? att.checkIn), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
