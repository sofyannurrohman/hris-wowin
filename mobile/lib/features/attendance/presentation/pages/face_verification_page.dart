import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:camera/camera.dart' show XFile;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/core/widgets/reusable_camera_widget.dart';
import 'package:hris_app/core/utils/ml_service.dart';
import 'package:hris_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:image/image.dart' as imglib;
import 'package:intl/intl.dart';
import 'package:hris_app/core/utils/constants.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:geolocator/geolocator.dart';

class FaceVerificationResult {
  final String imagePath;
  final List<double> embedding;
  FaceVerificationResult({required this.imagePath, required this.embedding});
}

class FaceVerificationPage extends StatefulWidget {
  final bool isClockIn;
  final bool isRegistration;
  final Map<String, dynamic>? userProfile;
  const FaceVerificationPage({
    super.key, 
    this.isClockIn = true,
    this.isRegistration = false,
    this.userProfile,
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  String? _capturedImagePath;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final MLService _mlService = MLService();
  bool _isVerifying = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _mlService.initialize();
    _fetchCurrentLocation();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching location: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReusableCameraWidget(
          instructionText: "Posisikan wajah Anda di dalam lingkaran",
          onCapture: (String imagePath) {
            setState(() {
              _capturedImagePath = imagePath;
            });
            // Auto close camera after taking picture
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _submitClockIn() async {
    if (_capturedImagePath == null) return;
    
    setState(() {
      _isVerifying = true;
    });

    try {
      // 1. Decode image for ML processing (if needed)
      final xFile = XFile(_capturedImagePath!);
      final bytes = await xFile.readAsBytes();
      final image = imglib.decodeImage(bytes);
      if (image == null) throw Exception("Gagal memproses gambar");

      List<double> currentEmbedding;
      try {
        if (_mlService.isInitialized) {
          currentEmbedding = _mlService.predict(image);
        } else if (widget.isRegistration) {
          // Skip ML on web/unsupported if it's registration
          currentEmbedding = List.filled(192, 0.0);
        } else {
          throw Exception("Layanan verifikasi wajah tidak tersedia.");
        }
      } catch (e) {
        if (widget.isRegistration) {
          currentEmbedding = List.filled(192, 0.0);
          if (kDebugMode) print("ML prediction failed during registration, using dummy: $e");
        } else {
          rethrow;
        }
      }

      // 2. If registration, just return the result early
      if (widget.isRegistration) {
        if (mounted) {
          Navigator.of(context).pop(
            FaceVerificationResult(
              imagePath: _capturedImagePath!,
              embedding: currentEmbedding,
            ),
          );
        }
        return;
      }

      // 3. Get stored base embedding (only for clock-in/out)
      final authRepo = di.sl<AuthRepository>();
      final result = await authRepo.getStoredFaceEmbedding();
      
      List<double>? baseEmbedding;
      result.fold(
        (failure) => throw Exception(failure.message),
        (embedding) => baseEmbedding = embedding,
      );

      if (baseEmbedding == null) {
        throw Exception("Wajah Anda belum terdaftar. Silakan registrasi wajah terlebih dahulu di profil.");
      }

      // 4. Compare
      final distance = _mlService.calculateEuclideanDistance(currentEmbedding, baseEmbedding!);
      
      if (kDebugMode) {
        print("Face Recognition Distance: $distance (Threshold: ${AppConstants.faceVerificationThreshold})");
      }
      
      if (distance > AppConstants.faceVerificationThreshold) {
        throw Exception("Wajah tidak cocok. Harap pastikan wajah Anda terlihat jelas.");
      }

      // 5. Submit to Backend if face matches locally
      if (mounted) {
        context.read<AttendanceBloc>().add(
          widget.isClockIn
              ? SubmitClockInEvent(
                  photoPath: _capturedImagePath!,
                  embedding: currentEmbedding,
                )
              : SubmitClockOutEvent(
                  photoPath: _capturedImagePath!,
                  embedding: currentEmbedding,
                ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm').format(_currentTime);
    final amPmStr = DateFormat('a').format(_currentTime);

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSuccess) {
          SnackBarUtils.showSuccess(context, state.message);
          Navigator.pop(context, true);
        } else if (state is AttendanceFailure) {
          SnackBarUtils.showError(context, state.errorMessage);
        }
      },
      builder: (context, state) {
        bool isLoading = state is AttendanceLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: Text(
                widget.isRegistration
                    ? 'Ambil Selfie Verifikasi'
                    : (widget.isClockIn ? 'Clock In Pegawai' : 'Clock Out Pegawai'),
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      if (!widget.isRegistration) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'SHIFT MORNING',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800]),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8.0, left: 4.0),
                            child: Text(
                              amPmStr,
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!widget.isRegistration) ...[
                  const SizedBox(height: 16),
                  // Location Details
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on,
                              color: Color(0xFF34A853), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  'Lokasi Saat Ini',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentPosition != null 
                                      ? '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                      : 'Mencari lokasi...',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.userProfile?['BranchName'] != null)
                                  Text(
                                    'Branch: ${widget.userProfile!['BranchName']}',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.blue[600]),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                const SizedBox(height: 32),

                // Camera Section
                if (_capturedImagePath == null) ...[
                  // State: Belum Foto
                  Container(
                    height: 240,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.face_retouching_natural, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Silakan ambil foto selfie untuk\nkeperluan absensi',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: Text('Buka Kamera', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),
                ] else ...[
                  // State: Sudah Foto
                  Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.greenAccent, width: 3),
                      image: DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(_capturedImagePath!) as ImageProvider
                            : FileImage(File(_capturedImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _openCamera,
                    icon: const Icon(Icons.refresh),
                    label: Text('Foto Ulang', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Submit Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (isLoading || _isVerifying) ? null : _submitClockIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B60F1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: (isLoading || _isVerifying) 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              widget.isRegistration
                                  ? 'Gunakan Foto Ini'
                                  : (widget.isClockIn
                                      ? 'Clock In Sekarang'
                                      : 'Clock Out Sekarang'),
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
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
