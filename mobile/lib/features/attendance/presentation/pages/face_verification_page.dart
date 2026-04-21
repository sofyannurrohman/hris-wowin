import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:hris_app/core/theme/app_colors.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/core/services/biometric_service.dart';
import 'package:hris_app/core/utils/dialog_utils.dart';
import 'package:hris_app/core/utils/face_detector_service.dart';
import 'package:hris_app/core/utils/ml_service.dart';
import 'package:hris_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:hris_app/features/attendance/presentation/pages/clock_in_success_page.dart';
import 'package:hris_app/features/attendance/presentation/pages/clock_in_failed_page.dart';
import 'package:hris_app/features/attendance/presentation/pages/clock_out_success_page.dart';
import 'package:hris_app/features/attendance/presentation/pages/clock_out_failed_page.dart';

class FaceVerificationResult {
  final List<double> embedding;
  final String imagePath;

  FaceVerificationResult({required this.embedding, required this.imagePath});
}

class _FaceProcessingParams {
  final String path;
  final Rect boundingBox;
  _FaceProcessingParams(this.path, this.boundingBox);
}

Future<imglib.Image?> _decodeAndCropFaceBackground(_FaceProcessingParams params) async {
  try {
    final bytes = await File(params.path).readAsBytes();
    imglib.Image? capturedImage = imglib.decodeImage(bytes);
    if (capturedImage == null) return null;

    // Bake orientation logic
    capturedImage = imglib.bakeOrientation(capturedImage);

    return imglib.copyCrop(
      capturedImage,
      x: params.boundingBox.left.toInt(),
      y: params.boundingBox.top.toInt(),
      width: params.boundingBox.width.toInt(),
      height: params.boundingBox.height.toInt(),
    );
  } catch (e) {
    debugPrint("Background processing error: $e");
    return null;
  }
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
  CameraController? _cameraController;
  final FaceDetectorService _faceDetectorService = FaceDetectorService();
  final MLService _mlService = MLService();
  
  String? _capturedImagePath;
  bool _isVerifying = false;
  Position? _currentPosition;
  String? _currentAddress;
  late Timer _nowTimer;
  DateTime _now = DateTime.now();
  bool _isBiometricEnabled = false;
  
  // Geofencing & Branch Info
  Map<String, dynamic>? _assignedBranch;
  double _distanceToBranch = -1;
  bool _isWithinGeofence = false;
  String? _targetBranchAddress;
  
  // Face Recognition Info
  bool _isFaceDetected = false;
  bool _isFaceMatched = false;
  String _statusText = "Menginisialisasi...";
  bool _isProcessing = false;
  List<double>? _currentEmbedding;
  List<double>? _baselineEmbedding;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _checkBiometricStatus();
    _nowTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  Future<void> _initializeServices() async {
    if (!kIsWeb) {
      _faceDetectorService.initialize();
      await _mlService.initialize();
    }
    
    // Start camera immediately so the user doesn't see a hang
    await _startCamera();
    
    // Request location and branch data in background
    _fetchBranchAndBaseline();
    _getCurrentLocation();
  }

  Future<void> _fetchBranchAndBaseline() async {
    try {
      // Skip authenticated calls during registration
      if (widget.isRegistration) {
        final branchesResult = await di.sl<AuthRepository>().getBranches();
        branchesResult.fold(
          (l) => debugPrint("Error branches: ${l.message}"),
          (branches) {
            if (mounted) {
              // During registration we don't have an assigned branch yet
            }
          }
        );
        return;
      }

      final profileResult = await di.sl<AuthRepository>().getProfile();
      final branchesResult = await di.sl<AuthRepository>().getBranches();
      final embeddingResult = await di.sl<AuthRepository>().getStoredFaceEmbedding();
      
      profileResult.fold(
        (l) => debugPrint("Error profile: ${l.message}"),
        (profile) {
          // Compatibility layer for branch_id
          final branchId = profile['branch_id'] ?? profile['BranchID'];
          
          if (branchId == null) {
            debugPrint("Warning: No branch_id found in profile. Is a branch assigned to this employee?");
          }

          // Fallback embedding extraction from profile
          final remoteEmbedding = profile['face_embedding'] ?? profile['FaceEmbedding'];
          if (remoteEmbedding != null && remoteEmbedding is List && remoteEmbedding.isNotEmpty) {
            try {
              final List<double> mappedEmbedding = remoteEmbedding.map((e) => (e as num).toDouble()).toList();
              if (mounted) {
                setState(() {
                  if (_baselineEmbedding == null || _baselineEmbedding!.isEmpty) {
                    _baselineEmbedding = mappedEmbedding;
                  }
                });
              }
            } catch (_) {}
          }

          branchesResult.fold(
            (l) => debugPrint("Error branches: ${l.message}"),
            (branches) {
              // Compatibility layer for branch ID lookup
              final branch = branches.firstWhere(
                (b) => (b['id'] ?? b['ID'] ?? b['id_branch']) == branchId, 
                orElse: () => {}
              );
              
              if (mounted) {
                setState(() {
                  _assignedBranch = branch.isNotEmpty ? branch : null;
                });
                
                if (_assignedBranch != null && !kIsWeb) {
                  // Compatibility layer for latitude/longitude
                  final lat = _assignedBranch!['latitude'] ?? _assignedBranch!['Latitude'];
                  final lng = _assignedBranch!['longitude'] ?? _assignedBranch!['Longitude'];
                  if (lat != null && lng != null) {
                    _getBranchAddress(lat, lng);
                  }
                }
              }
            }
          );
        }
      );

      embeddingResult.fold(
        (l) => debugPrint("Error embedding: ${l.message}"),
        (embedding) {
          if (mounted && embedding != null && embedding.isNotEmpty) {
            setState(() {
              _baselineEmbedding = embedding;
            });
          }
        }
      );
    } catch (e) {
      debugPrint("Background fetch error: $e");
    } finally {
      if (mounted && _statusText == "Menginisialisasi...") {
        setState(() {
           _statusText = "Mencari wajah...";
        });
      }
    }
  }

  Future<void> _getBranchAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() {
          _targetBranchAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      debugPrint("Branch geocoding error: $e");
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: !kIsWeb && Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      
      if (!kIsWeb) {
        _cameraController!.startImageStream((CameraImage image) {
          if (!_isProcessing && _capturedImagePath == null) {
            _processCameraImage(image, frontCamera);
          }
        });
      } else {
        // On Web, we can't do real-time stream easily, so we allow manual capture
        setState(() {
          _statusText = "Silakan ambil foto wajah anda.";
          _isFaceDetected = true; // Allow clicking "Ambil Foto"
        });
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void dispose() {
    _nowTimer.cancel();
    _cameraController?.dispose();
    if (!kIsWeb) {
      _faceDetectorService.dispose();
      _mlService.dispose();
    }
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    if (kIsWeb) return;
    try {
      final status = await di.sl<BiometricService>().isBiometricAvailable();
      if (mounted) {
        setState(() {
          _isBiometricEnabled = status;
        });
      }
    } catch (e) {
      debugPrint("Biometric check failed: $e");
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

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint("Current position timeout/error: $e. trying last known...");
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (mounted) SnackBarUtils.showError(context, "Gagal mendapatkan lokasi. Pastikan GPS aktif.");
        return;
      }
      
      // Reverse Geocoding
      try {
        if (!kIsWeb) {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            _currentAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
          }
        } else {
          _currentAddress = "Web Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})";
        }
      } catch (e) {
        debugPrint("Geocoding error: $e");
      }

      // Geofencing calculation
      double distance = -1;
      bool withinGeofence = false;
      
      final branchLat = _assignedBranch?['latitude'] ?? _assignedBranch?['Latitude'];
      final branchLng = _assignedBranch?['longitude'] ?? _assignedBranch?['Longitude'];
      final radius = _assignedBranch?['radius_meter'] ?? _assignedBranch?['RadiusMeter'] ?? 100;

      if (!widget.isRegistration && _assignedBranch != null && branchLat != null) {
        distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          branchLat,
          branchLng,
        );
        withinGeofence = distance <= radius;
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _distanceToBranch = distance;
          _isWithinGeofence = withinGeofence;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image, CameraDescription camera) async {
    _isProcessing = true;
    try {
      final inputImage = _faceDetectorService.createInputImageFromCameraImage(image, camera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetectorService.processImage(inputImage);
      
      if (faces.isEmpty) {
        if (mounted && _isFaceDetected) {
          setState(() {
            _isFaceDetected = false;
            _statusText = "Mencari wajah...";
          });
        }
      } else if (faces.length > 1) {
        if (mounted) {
          setState(() {
            _isFaceDetected = false;
            _statusText = "Terdeteksi lebih dari satu wajah.";
          });
        }
      } else {
        final face = faces.first;
        if (face.headEulerAngleY! > 10 || face.headEulerAngleY! < -10 || face.headEulerAngleZ! > 10 || face.headEulerAngleZ! < -10) {
          if (mounted) {
            setState(() {
              _isFaceDetected = false;
              _statusText = "Tatap lurus ke kamera.";
            });
          }
        } else {
          // Face is good
          if (mounted && !_isFaceDetected) {
            setState(() {
              _isFaceDetected = true;
              _statusText = "Wajah terdeteksi.";
            });
          }

          if (widget.isRegistration) {
             // For registration, we just need to detect
          } else if (_baselineEmbedding != null && !_isFaceMatched) {
            await _extractAndVerifyFace(image, face);
          }
        }
      }
    } catch (e) {
      // Suppress format errors in logs as we have a manual fallback
      if (e.toString().contains("InputImageConverterError")) {
        if (mounted && _statusText == "Mencari wajah...") {
          setState(() => _statusText = "Posisikan wajah & ambil foto.");
        }
      } else {
        debugPrint("Error processing image: $e");
      }
    }
    _isProcessing = false;
  }

  Future<void> _extractAndVerifyFace(CameraImage image, Face face) async {
    try {
      imglib.Image convertedImage = _convertCameraImage(image);
      if (!_mlService.isInitialized) {
        debugPrint("MLService not initialized, skipping verification.");
        return;
      }
      final currentEmbedding = _mlService.predict(convertedImage);
      
      if (_baselineEmbedding != null) {
        final distance = _mlService.calculateEuclideanDistance(currentEmbedding, _baselineEmbedding!);
        // Adjusted threshold to 1.5 for a looser match as requested
        final isMatched = distance < 1.5;
        
        if (mounted) {
          setState(() {
            _isFaceMatched = isMatched;
            _statusText = isMatched ? "Wajah diverifikasi." : "Wajah tidak sesuai.";
          });
        }
      }
    } catch (e) {
      debugPrint("Error verifying face: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      setState(() => _isVerifying = true);
      
      // Stop stream if it's running
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}

      final photo = await _cameraController!.takePicture();
      
      // Face detection from file (fast because it uses native JNI)
      final faces = await _faceDetectorService.processImageFromFile(photo.path);
      
      if (faces.isEmpty) {
        if (mounted) {
          SnackBarUtils.showError(context, "Wajah tidak ditemukan di foto. Coba lagi.");
          setState(() {
             _isVerifying = false;
             _startCamera();
          });
        }
        return;
      }

      final face = faces.first;
      
      // OFF-LOAD HEAVY DECODING AND CROPPING TO ISOLATE
      final imglib.Image? faceCrop = await compute(
        _decodeAndCropFaceBackground, 
        _FaceProcessingParams(photo.path, face.boundingBox)
      );
      
      if (faceCrop == null) {
        throw Exception("Gagal memproses file foto.");
      }

      if (!_mlService.isInitialized) {
        throw Exception("Sistem AI belum siap: ${_mlService.lastError ?? 'Tunggu sebentar'}");
      }
      
      final embedding = _mlService.predict(faceCrop);

      if (widget.isRegistration) {
        setState(() {
          _capturedImagePath = photo.path;
          _isVerifying = false;
        });
      } else {
        if (_baselineEmbedding == null) {
          // Handle missing baseline - IMPORTANT: prevents hang
          if (mounted) {
             SnackBarUtils.showError(context, "Data wajah Anda tidak ditemukan. Silakan registrasi ulang.");
             setState(() {
               _isVerifying = false;
               _startCamera();
             });
          }
          return;
        }

        // Verify against baseline
        final double distance = _mlService.calculateEuclideanDistance(_baselineEmbedding!, embedding);
        final bool isMatched = distance < 1.5;

        // Save the baked and cropped image for upload
        final tempDir = await getTemporaryDirectory();
        final facePath = p.join(tempDir.path, 'verify_face_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final faceFile = File(facePath);
        await faceFile.writeAsBytes(imglib.encodeJpg(faceCrop));

        if (mounted) {
          setState(() {
            _currentEmbedding = embedding;
            _handleCapturedImage(faceFile.path, isMatched);
          });
        }
      }
    } catch (e) {
      debugPrint("Take picture logic error: $e");
      if (mounted) {
        SnackBarUtils.showError(context, "Gagal memproses foto: $e");
        setState(() => _isVerifying = false);
        _startCamera();
      }
    }
  }

  void _handleCapturedImage(String path, bool isMatched) {
    _capturedImagePath = path;
    _isFaceMatched = isMatched;
    _isVerifying = false;
    _statusText = isMatched ? "Wajah diverifikasi." : "Wajah tidak sesuai.";
    
    if (!isMatched) {
      SnackBarUtils.showError(context, "Verifikasi gagal. Pastikan wajah Anda terlihat jelas.");
      _startCamera();
    }
  }

  imglib.Image _convertCameraImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.nv21) {
      return _convertNV21(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(image);
    } else {
      throw Exception('Unsupported image format');
    }
  }

  imglib.Image _convertNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final imglib.Image img = imglib.Image(width: width, height: height);
    final plane0 = image.planes[0].bytes;
    final plane1 = image.planes[1].bytes;
    final plane2 = image.planes[2].bytes;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = (y >> 1) * image.planes[1].bytesPerRow + (x & ~1);
        final int index = y * image.planes[0].bytesPerRow + x;
        final yp = plane0[index];
        final up = plane1[uvIndex];
        final vp = plane2[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        img.setPixelRgb(x, y, r, g, b);
      }
    }
    return imglib.copyRotate(img, angle: -90);
  }

  imglib.Image _convertBGRA8888(CameraImage image) {
    return imglib.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: imglib.ChannelOrder.bgra,
    );
  }

  Future<void> _verifyBiometric() async {
    final authenticated = await di.sl<BiometricService>().authenticate(
      reason: 'Silakan verifikasi sidik jari untuk absensi',
    );
    if (authenticated) {
      _submitClockIn();
    }
  }


  void _submitClockIn() {
    if (widget.isRegistration) {
      if (_capturedImagePath == null) return;
      // Navigator should return the result if it's for registration
      Navigator.of(context).pop(FaceVerificationResult(
        embedding: _currentEmbedding ?? [], 
        imagePath: _capturedImagePath!,
      ));
    } else {
      context.read<AttendanceBloc>().add(
        ClockInRequested(
          isClockIn: widget.isClockIn,
          imagePath: _capturedImagePath,
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
          faceEmbedding: _currentEmbedding,
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
              builder: (_) => widget.isClockIn
                  ? ClockInSuccessPage(
                      attendance: state.attendance,
                      branchName: _assignedBranch?['name'] ?? _assignedBranch?['Name'] ?? 'Lokasi Terdaftar',
                    )
                  : ClockOutSuccessPage(
                      attendance: state.attendance,
                      branchName: _assignedBranch?['name'] ?? _assignedBranch?['Name'] ?? 'Lokasi Terdaftar',
                    ),
            ),
          );
        } else if (state is AttendanceFailure) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => widget.isClockIn
                  ? ClockInFailedPage(
                      errorMessage: state.message,
                      isClockIn: widget.isClockIn,
                    )
                  : ClockOutFailedPage(
                      errorMessage: state.message,
                    ),
            ),
          );
        } else if (state is FaceRegistrationSuccess) {
          DialogUtils.showSuccess(
            context: context, 
            title: 'Wajah Terdaftar', 
            message: 'Data wajah anda telah berhasil disimpan untuk identitas absensi.',
            onConfirm: () => Navigator.of(context).pop(),
          );
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryRed.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.primaryRed, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PENTING:',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primaryRed, letterSpacing: 0.5),
                                ),
                                Text(
                                  'Silakan lakukan absensi di sekitar lokasi cabang ${_assignedBranch?['name'] ?? 'Anda'}.',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location & Geofencing Details
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_isWithinGeofence ? const Color(0xFF10B981) : AppColors.primaryRed).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16)
                              ),
                              child: Icon(
                                Icons.person_pin_circle_rounded,
                                color: _isWithinGeofence ? const Color(0xFF10B981) : AppColors.primaryRed,
                                size: 24
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'LOKASI SAYA SAAT INI',
                                    style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppColors.textTertiary)
                                  ),
                                  const SizedBox(height: 4),
                                  _isWithinGeofence && _currentAddress == null 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Text(
                                          _currentAddress ?? (_currentPosition != null 
                                              ? '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                              : 'Mencari lokasi...'),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.textTertiary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16)
                              ),
                              child: const Icon(
                                Icons.business_rounded,
                                color: AppColors.textTertiary,
                                size: 24
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TARGET LOKASI CABANG',
                                    style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppColors.textTertiary)
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _assignedBranch != null 
                                        ? '${_assignedBranch!['name'] ?? _assignedBranch!['Name']}\n${_targetBranchAddress ?? '(${_assignedBranch?['latitude'] ?? _assignedBranch?['Latitude']}, ${_assignedBranch?['longitude'] ?? _assignedBranch?['Longitude']})'}'
                                        : 'Cabang belum ditugaskan',
                                    style: TextStyle(
                                      fontSize: 13, 
                                      fontWeight: FontWeight.w700, 
                                      color: _assignedBranch != null ? AppColors.textPrimary : AppColors.primaryRed
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_distanceToBranch >= 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_isWithinGeofence ? const Color(0xFF10B981) : AppColors.primaryRed).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isWithinGeofence ? Icons.check_circle_rounded : Icons.warning_rounded,
                                  size: 16,
                                  color: _isWithinGeofence ? const Color(0xFF10B981) : AppColors.primaryRed,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isWithinGeofence 
                                      ? 'Berada dalam radius (Jarak: ${_distanceToBranch.toStringAsFixed(0)}m)'
                                      : 'Di luar radius (Jarak: ${_distanceToBranch.toStringAsFixed(0)}m)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _isWithinGeofence ? const Color(0xFF10B981) : AppColors.primaryRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Circular Camera Section
                if (_capturedImagePath == null) ...[
                  SizedBox(
                    height: 380,
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final circleSize = constraints.maxWidth * 0.75;
                          
                          return Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isFaceDetected 
                                    ? (widget.isRegistration || _isFaceMatched ? const Color(0xFF10B981) : Colors.orange)
                                    : AppColors.grayBorder, 
                                width: 4
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isFaceDetected ? Colors.blueAccent : Colors.black).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _cameraController != null && _cameraController!.value.isInitialized
                                ? FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      height: constraints.maxWidth * _cameraController!.value.aspectRatio,
                                      child: CameraPreview(_cameraController!),
                                    ),
                                  )
                                : const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isFaceMatched ? const Color(0xFF10B981) : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (!_isVerifying && _cameraController != null && _cameraController!.value.isInitialized) ? _takePicture : null,
                            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            label: Text(_isVerifying ? 'MEMPROSES...' : 'AMBIL FOTO'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF10B981), width: 2),
                          foregroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Captured Image Preview
                  Center(
                    child: Container(
                      height: 280,
                      width: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isFaceMatched || widget.isRegistration ? const Color(0xFF10B981) : AppColors.primaryRed, 
                          width: 4
                        ),
                        image: DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(_capturedImagePath!) as ImageProvider
                              : FileImage(File(_capturedImagePath!)),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isFaceMatched || widget.isRegistration ? const Color(0xFF10B981) : AppColors.primaryRed).withOpacity(0.2), 
                            blurRadius: 30, 
                            offset: const Offset(0, 15)
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                         _capturedImagePath = null;
                         _isFaceMatched = false;
                         _isFaceDetected = false;
                         _statusText = "Mencari wajah...";
                      });
                      _startCamera();
                    },
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
                      onPressed: (isLoading || _isVerifying || (!widget.isRegistration && !_isWithinGeofence)) ? null : _submitClockIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, 
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                      ),
                      child: (isLoading || _isVerifying) 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(
                              (!widget.isRegistration && !_isWithinGeofence) ? 'DI LUAR RADIUS' : (widget.isRegistration ? 'SIMPAN REGISTRASI' : (widget.isClockIn ? 'SUBMIT ABSEN MASUK' : 'SUBMIT ABSEN KELUAR')),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                         _capturedImagePath = null;
                         _isFaceMatched = false;
                         _isFaceDetected = false;
                         _statusText = "Mencari wajah...";
                      });
                      _startCamera();
                    },
                    child: const Text('Ambil Ulang Foto', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
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
