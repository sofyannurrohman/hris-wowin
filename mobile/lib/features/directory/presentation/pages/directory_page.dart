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
      backgroundColor: AppColors.backgroundAlt,
      body: BlocBuilder<DirectoryBloc, DirectoryState>(
        builder: (context, state) {
          int count = 0;
          List<EmployeeDirectory> employees = [];
          if (state is DirectoryLoaded) {
            employees = state.directory;
            count = employees.length;
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(count),
                _buildSearchHeader(),
              ];
            },
            body: _buildBody(state, employees),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(int count) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primaryRed,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('DIREKTORI', 
        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)
      ),
      centerTitle: true,
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
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'TOTAL KARYAWAN',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              context.read<DirectoryBloc>().add(FetchDirectoryRequested(query: val));
            },
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Cari Nama atau Departemen...',
              hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w500),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryRed, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DirectoryState state, List<EmployeeDirectory> employees) {
    if (state is DirectoryLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
    }
    
    if (state is DirectoryLoaded && employees.isEmpty) {
      return _buildEmptyState();
    }

    if (state is DirectoryFailure) {
      return Center(child: Text(state.message, style: GoogleFonts.plusJakartaSans(color: AppColors.error)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: employees.length,
      itemBuilder: (context, index) => _buildProfessionalCard(employees[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: AppColors.textTertiary.withOpacity(0.3)),
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
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    _buildPositionBadge(employee.position),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(employee.department, 
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _buildAvatar(EmployeeDirectory employee) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.1), width: 2),
      ),
      child: CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.grayLight,
        backgroundImage: (employee.profileUrl != null && employee.profileUrl!.isNotEmpty) 
            ? NetworkImage(employee.profileUrl!.startsWith('http') 
                ? employee.profileUrl! 
                : '${Uri.parse(AppConstants.baseUrl).origin}${employee.profileUrl!.startsWith('/') ? employee.profileUrl : '/${employee.profileUrl}'}') 
            : null,
        child: (employee.profileUrl == null || employee.profileUrl!.isEmpty) 
            ? const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 32) 
            : null,
      ),
    );
  }

  Widget _buildPositionBadge(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        position.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.primaryRed,
          fontSize: 9,
          fontWeight: FontWeight.w900,
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
        const SizedBox(height: 12),
        _buildCircularAction(
           Icons.chat_bubble_rounded,
           const Color(0xFF10B981), // Success Green
           () => _whatsappNumber(employee.phoneNumber)
        ),
      ],
    );
  }

  Widget _buildCircularAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

