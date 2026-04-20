import 'package:flutter/material.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/features/home/presentation/pages/home_page.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ClockInSuccessPage extends StatelessWidget {
  final Attendance attendance;
  final String? branchName;

  const ClockInSuccessPage({
    super.key, 
    required this.attendance,
    this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    final isClockOut = attendance.checkOut != null;
    final displayTime = isClockOut ? attendance.checkOut! : attendance.checkIn;
    
    // Formatting for Indonesian locale
    final timeStr = DateFormat('HH.mm').format(displayTime);
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(displayTime);

    final bool hasSelfie = attendance.selfiePath.isNotEmpty;
    // Base URL should ideally come from a config, but for now we follow the existing pattern
    final String selfieUrl = hasSelfie ? 'http://localhost:8080${attendance.selfiePath}' : '';

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: SafeArea(
      body: SafeArea(
        child: AnimationLimiter(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 600),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                  children: [
                    const SizedBox(height: 60),
                    
                    // Success Icon with Pulse effect
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Title
                    Text(
                      isClockOut ? 'Absensi Keluar Berhasil!' : 'Absensi Masuk Berhasil!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isClockOut 
                        ? 'Terima kasih atas kerja keras Anda hari ini. Selamat beristirahat!' 
                        : 'Selamat bekerja! Semoga hari Anda produktif dan menyenangkan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Info Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                        border: Border.all(color: AppColors.grayBorder.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              timeStr,
                                              style: GoogleFonts.outfit(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                                letterSpacing: -1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    // Selfie Preview
                                    Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        color: AppColors.grayLight,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.success.withOpacity(0.2), width: 2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: hasSelfie
                                            ? Image.network(
                                                selfieUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => 
                                                  const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 40),
                                              )
                                            : const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 40),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Divider(height: 1),
                                const SizedBox(height: 20),
                                
                                // Location Row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.location_on_rounded, size: 20, color: AppColors.info),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'LOKASI PRESENSI',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textTertiary,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            (branchName != null && branchName!.isNotEmpty) 
                                                ? branchName! 
                                                : (attendance.branchName.isNotEmpty ? attendance.branchName : 'Cabang Terdaftar'),
                                            style: GoogleFonts.outfit(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Status Bar bottom
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.grayLight.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Shift: Pagi (07:30)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (attendance.status == 'on_time' ? AppColors.success : AppColors.warning).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    attendance.status == 'on_time' ? 'TEPAT WAKTU' : 'TERLAMBAT',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: attendance.status == 'on_time' ? AppColors.success : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                  // Back to Home Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Kembali ke Beranda',
                      style: GoogleFonts.outfit(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
