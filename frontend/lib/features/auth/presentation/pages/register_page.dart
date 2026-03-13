import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/attendance/presentation/pages/face_verification_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  final _formKey = GlobalKey<FormState>();
  
  List<double>? _faceEmbedding;
  String? _selfiePath;
  String? _selectedJobPositionId;

  final List<Map<String, String>> _jobPositions = [
    {'id': 'ff961e50-8c25-4748-aa27-46afa117e109', 'title': 'CTO'},
    {'id': 'c96ab7f0-141b-4a11-92f4-5eea3dcddf12', 'title': 'Software Engineer'},
    {'id': 'a6838152-11e3-4e03-a98f-10c918636446', 'title': 'HR Manager'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      if (_selfiePath == null) {
        SnackBarUtils.showError(context, 'Harap ambil selfie verifikasi terlebih dahulu');
        return;
      }
      if (_selectedJobPositionId == null) {
        SnackBarUtils.showError(context, 'Harap pilih posisi pekerjaan');
        return;
      }
      context.read<AuthBloc>().add(
            RegisterRequested(
              _nameController.text.trim(),
              _emailController.text.trim(),
              _employeeIdController.text.trim(),
              _passwordController.text,
              _selectedJobPositionId!,
              embedding: _faceEmbedding,
              selfiePath: _selfiePath,
            ),
          );
    } else if (!_agreedToTerms) {
      SnackBarUtils.showError(context, 'Harap setuju dengan syarat dan ketentuan');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B60F1);
    const textColor = Color(0xFF111827);
    const subtitleColor = Color(0xFF6B7280);
    const borderColor = Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daftar',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            SnackBarUtils.showSuccess(context, 'Pendaftaran berhasil! Silahkan login.');
            Navigator.of(context).pop(); // Go back to login
          } else if (state is AuthError) {
            SnackBarUtils.showError(context, state.message);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: AnimationLimiter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // Logo Image
                        Center(
                          child: Image.asset(
                            'assets/logo_wowin.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Titles
                        Text(
                          'Buat Akun',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Daftar untuk mengakses PT Wowin Poernomo\nPutra SIK portal dan fitur absensi.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: subtitleColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Job Position Dropdown
                        _buildLabel('Posisi Pekerjaan'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedJobPositionId,
                          items: _jobPositions.map((pos) {
                            return DropdownMenuItem<String>(
                              value: pos['id'],
                              child: Text(pos['title']!),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedJobPositionId = value),
                          decoration: InputDecoration(
                            hintText: 'Pilih posisi pekerjaan',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 15),
                            prefixIcon: const Icon(Icons.work_outline, color: const Color(0xFF9CA3AF), size: 22),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1B60F1), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Full Name Field
                        _buildLabel('Nama Lengkap'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Masukkan nama lengkap',
                          icon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Employee ID Field
                        _buildLabel('NIKaryawan'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _employeeIdController,
                          hintText: 'e.g. WP-8821',
                          icon: Icons.badge_outlined,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Company Email Field
                        _buildLabel('Email'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'name@wowin.co.id',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => !v!.contains('@') ? 'Invalid Email' : null,
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Buat password',
                          icon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF9CA3AF),
                            ),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                          onChanged: (v) => setState(() {}),
                        ),
                        const SizedBox(height: 24),

                        // Face Registration Section
                        _buildLabel('Verifikasi Wajah (Wajib)'),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final result = await Navigator.of(context).push<FaceVerificationResult>(
                              MaterialPageRoute(builder: (_) => const FaceVerificationPage(isRegistration: true)),
                            );
                            if (result != null) {
                              setState(() {
                                _faceEmbedding = result.embedding;
                                _selfiePath = result.imagePath;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _selfiePath != null ? primaryBlue : borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    image: _selfiePath != null
                                        ? DecorationImage(
                                            image: kIsWeb
                                                ? NetworkImage(_selfiePath!) as ImageProvider
                                                : FileImage(File(_selfiePath!)),
                                            fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: _selfiePath == null
                                      ? const Icon(Icons.camera_alt, color: subtitleColor)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selfiePath == null ? 'Ambil Selfie Verifikasi' : 'Selfie Berhasil Diambil',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _selfiePath == null ? textColor : primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selfiePath == null
                                            ? 'Wajah anda akan digunakan untuk fitur absensi'
                                            : 'Klik untuk ambil ulang',
                                        style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selfiePath != null)
                                  const Icon(Icons.check_circle, color: Colors.green),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Password Strength Indicator Dummy
                        if (_passwordController.text.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: Container(height: 4, color: Colors.amber)),
                                    const SizedBox(width: 4),
                                    Expanded(child: Container(height: 4, color: Colors.amber)),
                                    const SizedBox(width: 4),
                                    Expanded(child: Container(height: 4, color: const Color(0xFFF3F4F6))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Medium Strength',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.amber[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                        const SizedBox(height: 24),

                        // Terms Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                side: const BorderSide(color: borderColor),
                                activeColor: primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(color: subtitleColor, fontSize: 13, height: 1.5),
                                  children: const [
                                    TextSpan(text: 'Saya setuju dengan '),
                                    TextSpan(text: 'Syarat dan Ketentuan', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500)),
                                    TextSpan(text: ' dan '),
                                    TextSpan(text: 'Kebijakan Privasi', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: state is AuthLoading ? null : _onRegisterPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: state is AuthLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'Daftar',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: GoogleFonts.inter(color: subtitleColor, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text(
                                'Masuk',
                                style: GoogleFonts.inter(
                                  color: primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B60F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
