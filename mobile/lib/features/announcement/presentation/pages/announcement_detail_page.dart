import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/features/announcement/data/models/announcement_model.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailPage({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'DETAIL PENGUMUMAN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Date Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.03),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryBadge(announcement.category),
                  const SizedBox(height: 20),
                  Text(
                    announcement.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMMM yyyy').format(announcement.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (announcement.author != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Text(
                          announcement.author!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ISI PENGUMUMAN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryRed,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    announcement.content,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Footer Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundAlt,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.grayBorder.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded, color: AppColors.primaryRed, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Harap baca pengumuman ini secara menyeluruh. Hubungi HR jika ada pertanyaan.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(AnnouncementCategory category) {
    Color color;
    String label;
    IconData icon;

    switch (category) {
      case AnnouncementCategory.policy:
        color = AppColors.primaryRed;
        label = 'KEBIJAKAN';
        icon = Icons.gavel_rounded;
        break;
      case AnnouncementCategory.birthday:
        color = const Color(0xFFEC4899);
        label = 'ULANG TAHUN';
        icon = Icons.cake_rounded;
        break;
      case AnnouncementCategory.alert:
        color = AppColors.warning;
        label = 'PENTING';
        icon = Icons.priority_high_rounded;
        break;
      default:
        color = const Color(0xFF6366F1);
        label = 'INFORMASI';
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
