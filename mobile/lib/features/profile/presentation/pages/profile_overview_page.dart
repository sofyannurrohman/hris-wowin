import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_state.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:hris_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:hris_app/features/profile/presentation/pages/face_registration_page.dart';
import 'package:hris_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:hris_app/core/utils/constants.dart';
import 'package:shimmer/shimmer.dart';

class ProfileOverviewPage extends StatefulWidget {
  const ProfileOverviewPage({super.key});

  @override
  State<ProfileOverviewPage> createState() => _ProfileOverviewPageState();
}

class _ProfileOverviewPageState extends State<ProfileOverviewPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading && state is! ProfileLoaded) {
            return _buildLoadingState();
          }

          final profile = (state is ProfileLoaded) ? state.profile : {};
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(profile),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    children: [
                      _buildMenuSection(
                        title: 'DATA KARYAWAN',
                        items: [
                          _buildMenuItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Informasi Pribadi',
                            subtitle: 'Detail data diri dan pekerjaan',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                          ),
                          _buildMenuItem(
                            icon: Icons.face_retouching_natural_rounded,
                            title: 'Registrasi Wajah',
                            subtitle: 'Perbarui data biometrik wajah',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceRegistrationPage())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildMenuSection(
                        title: 'KEAMANAN & AKSES',
                        items: [
                          _buildBiometricTile(),
                          _buildMenuItem(
                            icon: Icons.lock_reset_rounded,
                            title: 'Ganti Kata Sandi',
                            subtitle: 'Klik untuk ubah password anda',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildMenuSection(
                        title: 'LAINNYA',
                        items: [
                          _buildMenuItem(
                            icon: Icons.info_outline_rounded,
                            title: 'Informasi Aplikasi',
                            subtitle: 'Versi 1.0.0 (Stable)',
                            onTap: () {},
                          ),
                          _buildMenuItem(
                            icon: Icons.help_outline_rounded,
                            title: 'Pusat Bantuan',
                            subtitle: 'Butuh bantuan penggunaan?',
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Map<dynamic, dynamic> profile) {
    final name = '${profile['first_name'] ?? 'User'} ${profile['last_name'] ?? ''}'.trim();
    final position = profile['job_position']?['title'] ?? 'Employee';
    final nik = profile['employee_id_number'] ?? '-';

    return SliverAppBar(
      expandedHeight: 280,
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
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: (profile['face_reference_url'] != null && profile['face_reference_url'].toString().isNotEmpty)
                          ? Image.network(
                              profile['face_reference_url'].toString().startsWith('http') 
                                  ? profile['face_reference_url'] 
                                  : '${Uri.parse(AppConstants.baseUrl).origin}${profile['face_reference_url'].toString().startsWith('/') ? profile['face_reference_url'] : '/${profile['face_reference_url']}'}',
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
                              },
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primaryRed)),
                              ),
                            )
                          : Center(
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primaryRed)),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                      child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primaryRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(name, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(position, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              Text('NIK: $nik', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
      title: const Text('PROFIL PESERTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.grayBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: (color ?? AppColors.primaryRed).withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color ?? AppColors.primaryRed, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _buildBiometricTile() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final bool isSupported = state.isBiometricSupported;
        final bool isEnabled = state.isBiometricEnabled;

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.fingerprint_rounded, color: Colors.orange, size: 22),
          ),
          title: const Text('Login Biometrik', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
          subtitle: Text(isSupported ? 'Gunakan sidik jari' : 'Perangkat tidak didukung', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          trailing: Switch.adaptive(
            value: isEnabled,
            activeColor: AppColors.primaryRed,
            onChanged: isSupported ? (val) {
              context.read<AuthBloc>().add(ToggleBiometricRequested(val));
            } : null,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => _showLogoutConfirmation(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: 12),
            Text('KELUAR DARI AKUN', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, minimumSize: const Size(100, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('KELUAR', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: AppColors.grayLight,
      highlightColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Center(child: Container(width: 100, height: 100, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
          const SizedBox(height: 16),
          Center(child: Container(width: 200, height: 20, color: Colors.white)),
          const SizedBox(height: 48),
          Container(width: double.infinity, height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
        ],
      ),
    );
  }
}
