import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/features/leave/presentation/bloc/leave_bloc.dart';
import 'package:hris_app/features/leave/presentation/bloc/leave_event.dart';
import 'package:hris_app/features/leave/presentation/bloc/leave_state.dart';
import 'package:hris_app/features/leave/domain/entities/leave_balance.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
  XFile? _attachment;
  final ImagePicker _picker = ImagePicker();

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

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachment = image;
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

    // VALIDATION: Sakit must have attachment
    final selectedBalance = _balances.firstWhere((element) => element.leaveTypeId == _selectedLeaveTypeId);
    if (selectedBalance.leaveTypeName.toLowerCase().contains('sakit') && _attachment == null) {
      SnackBarUtils.showError(context, 'Surat izin dokter wajib dilampirkan untuk izin sakit');
      return;
    }

    context.read<LeaveBloc>().add(SubmitLeaveRequested(
          leaveTypeId: _selectedLeaveTypeId!,
          startDate: startStr,
          endDate: endStr,
          reason: _reasonController.text,
          attachmentPath: _attachment?.path,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Cuti / Izin'),
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
              _attachment = null;
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
                      const Text('Pengajuan Cuti / Izin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedLeaveTypeId,
                        hint: Text(_balances.isEmpty ? 'Memuat tipe...' : 'Pilih Tipe Cuti / Izin'),
                        decoration: const InputDecoration(
                          labelText: 'Tipe Layanan',
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
                      Text(
                        'Lampiran (Wajib untuk Sakit)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.attachment_rounded, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _attachment == null ? 'Pilih Foto Surat Dokter' : (_attachment!.name.length > 30 ? '...${_attachment!.name.substring(_attachment!.name.length - 20)}' : _attachment!.name),
                                  style: TextStyle(color: _attachment == null ? Colors.grey : Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_attachment != null)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                  onPressed: () => setState(() => _attachment = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitLeave,
                        child: const Text('Ajukan Sekarang'),
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
                'Riwayat Pengajuan',
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
                  ? 'Pengajuan ini berbayar (Gaji tetap dibayarkan).'
                  : 'Pengajuan ini tidak berbayar (Terdapat pemotongan gaji pokok).',
              style: TextStyle(
                fontSize: 12,
                color: isPaid ? Colors.blue[700] : Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
