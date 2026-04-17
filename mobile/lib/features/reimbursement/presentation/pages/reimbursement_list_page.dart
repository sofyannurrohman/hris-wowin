import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/reimbursement/presentation/bloc/reimbursement_bloc.dart';
import 'package:hris_app/features/reimbursement/presentation/bloc/reimbursement_event.dart';
import 'package:hris_app/features/reimbursement/presentation/bloc/reimbursement_state.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:intl/intl.dart';
import 'add_reimbursement_page.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';

class ReimbursementListPage extends StatefulWidget {
  const ReimbursementListPage({super.key});

  @override
  State<ReimbursementListPage> createState() => _ReimbursementListPageState();
}

class _ReimbursementListPageState extends State<ReimbursementListPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ReimbursementBloc>()..add(const FetchReimbursementHistoryRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reimbursement'),
        ),
        body: BlocListener<ReimbursementBloc, ReimbursementState>(
          listener: (context, state) {
            if (state is ReimbursementActionSuccess) {
              SnackBarUtils.showSuccess(context, state.message);
              context.read<ReimbursementBloc>().add(const FetchReimbursementHistoryRequested());
            } else if (state is ReimbursementFailure) {
              SnackBarUtils.showError(context, state.message);
            }
          },
          child: const ReimbursementListView(),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddReimbursementPage()),
              );
              if (result == true && context.mounted) {
                context.read<ReimbursementBloc>().add(const FetchReimbursementHistoryRequested());
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajukan'),
          ),
        ),
      ),
    );
  }
}

class ReimbursementListView extends StatelessWidget {
  const ReimbursementListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReimbursementBloc, ReimbursementState>(
      buildWhen: (previous, current) => current is ReimbursementHistoryLoaded || current is ReimbursementLoading || current is ReimbursementFailure,
      builder: (context, state) {
        if (state is ReimbursementLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ReimbursementFailure) {
          return Center(child: Text(state.message));
        } else if (state is ReimbursementHistoryLoaded) {
          if (state.history.isEmpty) {
            return const Center(child: Text('Belum ada riwayat reimbursement.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReimbursementBloc>().add(const FetchReimbursementHistoryRequested());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.history.length,
              itemBuilder: (context, index) {
                final r = state.history[index];
                final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                
                Color statusColor = Colors.grey;
                bool canEditDelete = false;
                if (r.status == 'APPROVED') statusColor = Colors.green;
                if (r.status == 'REJECTED') statusColor = Colors.red;
                if (r.status == 'PENDING') {
                  statusColor = Colors.orange;
                  canEditDelete = true;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currencyFormat.format(r.amount), style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600)),
                        Text(DateFormat('dd MMM yyyy').format(r.createdAt), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            r.status,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (canEditDelete)
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddReimbursementPage(reimbursementToEdit: r)),
                                );
                                if (result == true && context.mounted) {
                                  context.read<ReimbursementBloc>().add(const FetchReimbursementHistoryRequested());
                                }
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Hapus Pengajuan'),
                                    content: const Text('Apakah Anda yakin ingin menghapus pengajuan reimbursement ini?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  context.read<ReimbursementBloc>().add(DeleteReimbursementRequested(r.id));
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Ubah')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
