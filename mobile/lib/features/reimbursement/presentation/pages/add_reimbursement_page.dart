import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/reimbursement/presentation/bloc/reimbursement_bloc.dart';
import 'package:hris_app/features/reimbursement/presentation/bloc/reimbursement_event.dart';
import 'package:hris_app/features/reimbursement/presentation/bloc/reimbursement_state.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:image_picker/image_picker.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';

class AddReimbursementPage extends StatefulWidget {
  const AddReimbursementPage({super.key});

  @override
  State<AddReimbursementPage> createState() => _AddReimbursementPageState();
}

class _AddReimbursementPageState extends State<AddReimbursementPage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _attachment;
  final ImagePicker _picker = ImagePicker();

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachment = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ReimbursementBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajukan Reimbursement'),
        ),
        body: BlocConsumer<ReimbursementBloc, ReimbursementState>(
          listener: (context, state) {
            if (state is ReimbursementActionSuccess) {
              SnackBarUtils.showSuccess(context, state.message);
              Navigator.pop(context, true);
            } else if (state is ReimbursementFailure) {
              SnackBarUtils.showError(context, state.message);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul (Contoh: Bensin Sales)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Total Nominal (Rp)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bukti Pembayaran / Nota',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: _attachment == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Pilih Foto Nota', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(_attachment!.path), fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    radius: 12,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                      onPressed: () => setState(() => _attachment = null),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: state is ReimbursementLoading
                        ? null
                        : () {
                            if (_titleController.text.isEmpty || _amountController.text.isEmpty || _attachment == null) {
                              SnackBarUtils.showError(context, 'Mohon lengkapi judul, nominal, dan nota.');
                              return;
                            }
                            final amount = double.tryParse(_amountController.text) ?? 0;
                            context.read<ReimbursementBloc>().add(SubmitReimbursementRequested(
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  amount: amount,
                                  attachmentPath: _attachment?.path,
                                ));
                          },
                    child: state is ReimbursementLoading
                        ? const CircularProgressIndicator()
                        : const Text('Kirim Pengajuan'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
