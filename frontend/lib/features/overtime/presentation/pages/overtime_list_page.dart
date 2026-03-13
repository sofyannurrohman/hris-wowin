import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/overtime/presentation/bloc/overtime_bloc.dart';
import 'package:hris_app/features/overtime/presentation/bloc/overtime_event.dart';
import 'package:hris_app/features/overtime/presentation/bloc/overtime_state.dart';
import 'package:hris_app/features/overtime/presentation/pages/overtime_request_page.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_event.dart';
import '../bloc/overtime_state.dart';
import '../../domain/entities/overtime.dart';

class OvertimeListPage extends StatefulWidget {
  const OvertimeListPage({super.key});

  @override
  State<OvertimeListPage> createState() => _OvertimeListPageState();
}

class _OvertimeListPageState extends State<OvertimeListPage> {
  @override
  void initState() {
    super.initState();
    context.read<OvertimeBloc>().add(FetchMyOvertimesRequested());
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B60F1);
    const bgGray = Color(0xFFF9FAFB);
    const textColor = Color(0xFF111827);
    const subtitleColor = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        title: Text(
          'Pengajuan Lembur',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<OvertimeBloc, OvertimeState>(
        listener: (context, state) {
          if (state is OvertimeSuccess) {
            SnackBarUtils.showSuccess(context, state.message);
            context.read<OvertimeBloc>().add(FetchMyOvertimesRequested());
          } else if (state is OvertimeFailure) {
            SnackBarUtils.showError(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          if (state is OvertimeLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          if (state is MyOvertimesLoaded) {
            final overtimes = state.overtimes;

            if (overtimes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off, color: Colors.grey[300], size: 80),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada pengajuan lembur',
                      style: GoogleFonts.inter(fontSize: 16, color: subtitleColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<OvertimeBloc>().add(FetchMyOvertimesRequested());
              },
              color: primaryBlue,
              child: AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: overtimes.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildOvertimeCard(context, overtimes[index], primaryBlue, textColor, subtitleColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OvertimeRequestPage(),
            ),
          ).then((_) {
            if (mounted) {
              context.read<OvertimeBloc>().add(FetchMyOvertimesRequested());
            }
          });
        },
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOvertimeCard(
    BuildContext context,
    Overtime overtime,
    Color primaryBlue,
    Color textColor,
    Color subtitleColor,
  ) {
    final statusColor = _getStatusColor(overtime.status);
    final isPending = overtime.status.toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(overtime.date),
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('HH:mm').format(overtime.startTime)} - ${DateFormat('HH:mm').format(overtime.endTime)} (${(overtime.durationMinutes / 60).toStringAsFixed(1)} Jam)',
                      style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    overtime.status.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              overtime.reason,
              style: GoogleFonts.inter(fontSize: 14, color: textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isPending) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editOvertime(context, overtime),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: primaryBlue),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteOvertime(context, overtime),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
            if (overtime.rejectReason != null && overtime.rejectReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Text(
                  'Alasan Penolakan: ${overtime.rejectReason}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.red[700], fontStyle: FontStyle.italic),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _editOvertime(BuildContext context, Overtime overtime) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OvertimeRequestPage(overtimeToEdit: overtime),
      ),
    ).then((_) {
      if (mounted) {
        context.read<OvertimeBloc>().add(FetchMyOvertimesRequested());
      }
    });
  }

  void _deleteOvertime(BuildContext context, Overtime overtime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Pengajuan?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus pengajuan lembur ini?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<OvertimeBloc>().add(DeleteOvertimeRequested(overtime.id));
            },
            child: Text('Hapus', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
