import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/features/attendance/presentation/pages/clock_in_success_page.dart';
import 'package:hris_app/features/attendance/presentation/pages/clock_in_failed_page.dart';
import 'package:hris_app/core/services/biometric_service.dart';

class FaceVerificationResult {
  final List<double> embedding;
  final String imagePath;

  FaceVerificationResult({required this.embedding, required this.imagePath});
}

class FaceVerificationPage extends StatefulWidget {
  final bool isClockIn;
  final bool isRegistration;

  const FaceVerificationPage({
    super.key, 
    this.isClockIn = true,
    this.isRegistration = false,
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  final ImagePicker _picker = ImagePicker();
  String? _capturedImagePath;
  bool _isVerifying = false;
  Position? _currentPosition;
  late Timer _timer;
  DateTime _now = DateTime.now();
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkBiometricStatus();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final status = await di.sl<BiometricService>().isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = status;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _verifyBiometric() async {
    final authenticated = await di.sl<BiometricService>().authenticate(
      reason: 'Silakan verifikasi sidik jari untuk absensi',
    );
    if (authenticated) {
      _submitClockIn();
    }
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (photo != null) {
        setState(() {
          _capturedImagePath = photo.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka kamera: $e')),
      );
    }
  }

  void _submitClockIn() {
    if (widget.isRegistration) {
      if (_capturedImagePath == null) return;
      // Navigator should return the result if it's for registration
      Navigator.of(context).pop(FaceVerificationResult(
        embedding: [], // Mock embedding or get from ML kit if needed
        imagePath: _capturedImagePath!,
      ));
    } else {
      context.read<AttendanceBloc>().add(
        ClockInRequested(
          isClockIn: widget.isClockIn,
          imagePath: _capturedImagePath,
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String timeStr = DateFormat('HH:mm').format(_now);
    String amPmStr = DateFormat('a').format(_now);

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ClockInSuccessPage(
                attendance: state.attendance,
              ),
            ),
          );
        } else if (state is AttendanceFailure) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ClockInFailedPage(
                errorMessage: state.message,
              ),
            ),
          );
        } else if (state is FaceRegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi wajah berhasil!')),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        bool isLoading = state is AttendanceLoading || state is FaceRegistrationLoading;

        return Scaffold(
          backgroundColor: AppColors.backgroundAlt,
          appBar: AppBar(
            title: Text(
              widget.isRegistration
                  ? 'VERIFIKASI WAJAH'
                  : (widget.isClockIn ? 'ABSEN MASUK' : 'ABSEN KELUAR'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.textPrimary),
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
              children: [
                // Top Info Section
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      if (!widget.isRegistration) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SHIFT PAGI (07:30)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primaryRed),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                            child: Text(
                              amPmStr.toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textTertiary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!widget.isRegistration) ...[
                  const SizedBox(height: 24),
                  // Location Details
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LOKASI PRESENSI', style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                              const SizedBox(height: 4),
                              Text(
                                _currentPosition != null 
                                    ? 'Koordinat: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                    : 'Mencari lokasi...',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Camera Section
                if (_capturedImagePath == null) ...[
                  Container(
                    height: 260,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.grayBorder, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(color: AppColors.grayLight, shape: BoxShape.circle),
                          child: const Icon(Icons.face_unlock_rounded, size: 48, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Ambil foto selfie Anda\nuntuk verifikasi wajah',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: ElevatedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      label: const Text('BUKA KAMERA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_isBiometricEnabled && !widget.isRegistration) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: OutlinedButton.icon(
                        onPressed: _verifyBiometric,
                        icon: const Icon(Icons.fingerprint_rounded, size: 24),
                        label: const Text('VERIFIKASI SIDIK JARI'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          foregroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.primaryRed, width: 4),
                      image: DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(_capturedImagePath!) as ImageProvider
                            : FileImage(File(_capturedImagePath!)),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryRed.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15))
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: _openCamera,
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryRed),
                    label: const Text('Ambil Ulang Foto', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 32),
                  
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: (isLoading || _isVerifying) ? null : _submitClockIn,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      child: (isLoading || _isVerifying) 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(
                              widget.isRegistration ? 'SIMPAN REGISTRASI' : (widget.isClockIn ? 'SUBMIT ABSEN MASUK' : 'SUBMIT ABSEN KELUAR'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
