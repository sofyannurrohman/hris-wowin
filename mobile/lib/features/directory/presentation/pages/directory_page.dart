import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/features/directory/data/models/directory_model.dart';
import 'package:hris_app/features/directory/presentation/bloc/directory_bloc.dart';
import 'package:hris_app/core/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({super.key});

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DirectoryBloc>().add(const FetchDirectoryRequested());
  }

  void _callNumber(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _whatsappNumber(String phoneNumber) async {
    String normalized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (normalized.startsWith('0')) {
      normalized = '62${normalized.substring(1)}';
    }
    final Uri url = Uri.parse('https://wa.me/$normalized');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra light professional gray
      appBar: AppBar(
        title: Text('DIREKTORI KARYAWAN', 
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textPrimary)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildPremiumSearchField(),
          Expanded(
            child: BlocBuilder<DirectoryBloc, DirectoryState>(
              builder: (context, state) {
                if (state is DirectoryLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
                }
                if (state is DirectoryLoaded) {
                  if (state.directory.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.directory.length,
                    itemBuilder: (context, index) => _buildProfessionalCard(state.directory[index]),
                  );
                }
                if (state is DirectoryFailure) {
                  return Center(child: Text(state.message, style: GoogleFonts.plusJakartaSans(color: Colors.red)));
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSearchField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            context.read<DirectoryBloc>().add(FetchDirectoryRequested(query: val));
          },
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Cari Nama atau Departemen...',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Karyawan tidak ditemukan', 
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard(EmployeeDirectory employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {}, // Future: Detail Page
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildAvatar(employee),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(employee.name, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        _buildPositionBadge(employee.position),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.business_rounded, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(employee.department, 
                              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActionButtons(employee),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(EmployeeDirectory employee) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2), width: 2),
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFFF1F5F9),
        backgroundImage: (employee.profileUrl != null && employee.profileUrl!.isNotEmpty) 
            ? NetworkImage(employee.profileUrl!.startsWith('http') 
                ? employee.profileUrl! 
                : '${Uri.parse(AppConstants.baseUrl).origin}${employee.profileUrl!.startsWith('/') ? employee.profileUrl : '/${employee.profileUrl}'}') 
            : null,
        child: (employee.profileUrl == null || employee.profileUrl!.isEmpty) 
            ? const Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 30) 
            : null,
      ),
    );
  }

  Widget _buildPositionBadge(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        position.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.primaryRed,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(EmployeeDirectory employee) {
    return Column(
      children: [
        _buildCircularAction(
          Icons.phone_in_talk_rounded, 
          const Color(0xFF3B82F6), // Professional Blue
          () => _callNumber(employee.phoneNumber)
        ),
        const SizedBox(height: 10),
        _buildCircularAction(
           Icons.chat_bubble_rounded,
           const Color(0xFF22C55E), // WhatsApp Brand Green
           () => _whatsappNumber(employee.phoneNumber)
        ),
      ],
    );
  }

  Widget _buildCircularAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
