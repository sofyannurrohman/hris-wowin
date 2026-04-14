import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/features/leave/presentation/bloc/leave_bloc.dart';
import 'package:hris_app/features/leave/presentation/bloc/leave_event.dart';
import 'package:hris_app/features/leave/presentation/bloc/leave_state.dart';
import 'package:hris_app/features/leave/domain/entities/leave_balance.dart';
import 'package:intl/intl.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    context.read<LeaveBloc>().add(const FetchLeaveBalancesRequested());
    context.read<LeaveBloc>().add(const FetchMyLeavesRequested());
  }


  @override
  Widget build(BuildContext context) {
    return const LeaveView();
  }
}

class LeaveView extends StatefulWidget {
  const LeaveView({super.key});

  @override
  State<LeaveView> createState() => _LeaveViewState();
}

class _LeaveViewState extends State<LeaveView> {
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedLeaveTypeId;
  List<LeaveBalance> _balances = [];

  void _presentDatePicker(bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  void _submitLeave() {
    if (_startDate == null || _endDate == null || _reasonController.text.isEmpty || _selectedLeaveTypeId == null) {
      SnackBarUtils.showError(context, 'Please fill all fields (Type, Date, Reason)');
      return;
    }
    
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);

    context.read<LeaveBloc>().add(SubmitLeaveRequested(
          leaveTypeId: _selectedLeaveTypeId!,
          startDate: startStr,
          endDate: endStr,
          reason: _reasonController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Cuti'),
        leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      ),
      body: BlocListener<LeaveBloc, LeaveState>(
        listener: (context, state) {
          if (state is LeaveActionSuccess) {
            SnackBarUtils.showSuccess(context, state.message);
            _reasonController.clear();
            setState(() {
              _startDate = null;
              _endDate = null;
              _selectedLeaveTypeId = null;
            });
            context.read<LeaveBloc>().add(const FetchMyLeavesRequested());
            context.read<LeaveBloc>().add(const FetchLeaveBalancesRequested());
          } else if (state is LeaveActionFailure) {
            SnackBarUtils.showError(context, state.message);
          }
 else if (state is LeaveBalancesLoaded) {
            setState(() {
              _balances = state.balances;
            });
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Pengajuan Cuti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedLeaveTypeId,
                        hint: Text(_balances.isEmpty ? 'Memuat tipe cuti...' : 'Pilih Tipe Cuti'),
                        decoration: const InputDecoration(
                          labelText: 'Tipe Cuti',
                          border: OutlineInputBorder(),
                        ),
                        items: _balances.map((balance) {
                          return DropdownMenuItem(
                            value: balance.leaveTypeId,
                            child: Text('${balance.leaveTypeName} (Sisa: ${balance.remaining})'),
                          );
                        }).toList(),

                        onChanged: (value) {
                          setState(() {
                            _selectedLeaveTypeId = value;
                          });
                        },
                      ),
                      if (_selectedLeaveTypeId != null) ...[
                        const SizedBox(height: 12),
                        _buildLeavePayInfo(),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _presentDatePicker(true),
                              icon: const Icon(Icons.date_range),
                              label: Text(_startDate == null ? 'Tanggal Mulai' : DateFormat('yyyy-MM-dd').format(_startDate!)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _presentDatePicker(false),
                              icon: const Icon(Icons.date_range),
                              label: Text(_endDate == null ? 'Tanggal Selesai' : DateFormat('yyyy-MM-dd').format(_endDate!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Alasan',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitLeave,
                        child: const Text('Ajukan Cuti'),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'My Leave History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: BlocBuilder<LeaveBloc, LeaveState>(
                buildWhen: (previous, current) => current is LeavesLoaded || current is LeavesFailure || current is LeaveLoading,
                builder: (context, state) {
                  if (state is LeaveLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is LeavesFailure) {
                    return Center(child: Text(state.message));
                  } else if (state is LeavesLoaded) {
                    if (state.leaves.isEmpty) {
                      return const Center(child: Text("No leave requests found."));
                    }
                    return ListView.builder(
                      itemCount: state.leaves.length,
                      itemBuilder: (context, index) {
                        final leave = state.leaves[index];
                        final startStr = DateFormat('yyyy-MM-dd').format(leave.startDate);
                        final endStr = DateFormat('yyyy-MM-dd').format(leave.endDate);

                        Color statusColor = Colors.grey;
                        if (leave.status == 'approved') statusColor = Colors.green;
                        if (leave.status == 'rejected') statusColor = Colors.red;
                        if (leave.status == 'pending') statusColor = Colors.orange;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text('${leave.leaveTypeName ?? "Cuti"} | $startStr to $endStr'),
                            subtitle: Text('Reason: ${leave.reason}'),
                            trailing: Chip(
                              label: Text(
                                leave.status.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor: statusColor,
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeavePayInfo() {
    final balance = _balances.firstWhere((b) => b.leaveTypeId == _selectedLeaveTypeId);
    final isPaid = balance.isPaid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPaid ? Colors.blue.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPaid ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.info_outline : Icons.warning_amber_rounded,
            size: 16,
            color: isPaid ? Colors.blue : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPaid
                  ? 'Cuti ini berbayar (Gaji tetap dibayarkan).'
                  : 'Cuti ini tidak berbayar (Akan ada pemotongan gaji).',
              style: TextStyle(
                fontSize: 12,
                color: isPaid ? Colors.blue[700] : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
