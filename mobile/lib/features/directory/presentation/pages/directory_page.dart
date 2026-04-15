import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/features/directory/data/models/directory_model.dart';
import 'package:hris_app/features/directory/presentation/bloc/directory_bloc.dart';
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
    // Normalize phone number for international format
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
      appBar: AppBar(
        title: Text('DIREKTORI KARYAWAN', 
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: BlocBuilder<DirectoryBloc, DirectoryState>(
              builder: (context, state) {
                if (state is DirectoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is DirectoryLoaded) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: state.directory.length,
                    itemBuilder: (context, index) => _buildEmployeeCard(state.directory[index]),
                  );
                }
                if (state is DirectoryFailure) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          context.read<DirectoryBloc>().add(FetchDirectoryRequested(query: val));
        },
        decoration: InputDecoration(
          hintText: 'Cari nama atau departemen...',
          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          filled: true,
          fillColor: AppColors.grayLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeDirectory employee) {
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
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.grayLight,
            backgroundImage: employee.profileUrl != null ? NetworkImage(employee.profileUrl!) : null,
            child: employee.profileUrl == null ? const Icon(Icons.person, color: AppColors.textTertiary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('${employee.position} • ${employee.department}', style: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Row(
            children: [
              _buildIconButton(Icons.phone_rounded, const Color(0xFF10B981), () => _callNumber(employee.phoneNumber)),
              const SizedBox(width: 8),
              _buildIconButton(Icons.chat_bubble_rounded, Colors.green, () => _whatsappNumber(employee.phoneNumber)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
