import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/core/utils/face_detector_service.dart';
import 'package:hris_app/core/utils/ml_service.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:image/image.dart' as imglib;
import 'package:hris_app/core/utils/snackbar_utils.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart' hide RegisterFaceRequested;

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

    // Bake orientation to ensure the image is upright before we use coordinates from MLKit
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


class FaceRegistrationPage extends StatefulWidget {
  const FaceRegistrationPage({super.key});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  CameraController? _cameraController;
  final FaceDetectorService _faceDetectorService = FaceDetectorService();
  final MLService _mlService = MLService();
  
  bool _isProcessing = false;
  bool _isFaceDetected = false;
  String _statusText = "Mencari wajah...";
  
  List<double>? _currentEmbedding;
  String? _currentSelfiePath;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _resetState() {
    setState(() {
      _currentEmbedding = null;
      _currentSelfiePath = null;
      _isFaceDetected = false;
      _statusText = "Mencari wajah...";
    });
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _faceDetectorService.initialize();
    await _mlService.initialize();
    
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
    
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: !kIsWeb && Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isProcessing) {
        _processCameraImage(image, frontCamera);
      }
    });

    if (mounted) setState(() {});
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
            _statusText = "Wajah tidak terdeteksi. Posisikan wajah di tengah.";
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
          if (mounted && !_isFaceDetected) {
            setState(() {
              _isFaceDetected = true;
              _statusText = "Wajah terdeteksi. Silakan ambil foto.";
            });
          }
        }
      }
    } catch (e) {
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

  Future<void> _takePictureManual() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      setState(() => _statusText = "Mengambil foto...");
      
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}

      final xFile = await _cameraController!.takePicture();
      
      setState(() => _statusText = "Memproses wajah...");
      
      final faces = await _faceDetectorService.processImageFromFile(xFile.path);
      
      if (faces.isEmpty) {
        if (mounted) {
          SnackBarUtils.showError(context, "Wajah tidak ditemukan di foto. Coba lagi.");
          _initializeServices();
        }
        return;
      }

      final face = faces.first;
      
      final imglib.Image? faceCrop = await compute(
        _decodeAndCropFaceBackground, 
        _FaceProcessingParams(xFile.path, face.boundingBox)
      );
      
      if (faceCrop == null) {
        throw Exception("Gagal memproses file foto.");
      }

      if (!_mlService.isInitialized) {
        throw Exception("Sistem AI belum siap: ${_mlService.lastError ?? 'Tunggu sebentar'}");
      }
      final embedding = _mlService.predict(faceCrop);
      
      if (mounted) {
        setState(() => _statusText = "Menyimpan data...");
      }

      // Save the baked and cropped image to a temporary file for upload
      final tempDir = await getTemporaryDirectory();
      final facePath = p.join(tempDir.path, 'face_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final faceFile = File(facePath);
      await faceFile.writeAsBytes(imglib.encodeJpg(faceCrop));

      if (mounted) {
        setState(() {
          _currentEmbedding = embedding;
          _currentSelfiePath = faceFile.path;
          _statusText = "Data wajah berhasil diambil. Siap disimpan.";
        });
      }
    } catch (e) {
      debugPrint("Manual capture error: $e");
      if (mounted) {
        setState(() => _statusText = "Gagal memproses wajah.");
        SnackBarUtils.showError(context, "Gagal: $e");
        _initializeServices();
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectorService.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is FaceRegistrationSuccess) {
          SnackBarUtils.showSuccess(context, 'Registrasi Wajah Berhasil!');
          context.read<AuthBloc>().add(CheckAuthStatusRequested());
          context.read<ProfileBloc>().add(LoadProfileRequested());
          context.read<AttendanceBloc>().add(FetchHomeDataRequested());
          Navigator.of(context).pop();
        } else if (state is AuthError) {
          SnackBarUtils.showError(context, 'Gagal: ${state.message}');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("Registrasi Wajah", style: GoogleFonts.inter(fontSize: 18, color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            if (_cameraController != null && _cameraController!.value.isInitialized)
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      final circleSize = size.width * 0.8;
                      
                      return Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _currentSelfiePath != null
                            ? Image.file(
                                File(_currentSelfiePath!),
                                fit: BoxFit.cover,
                              )
                            : FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxWidth * _cameraController!.value.aspectRatio,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                      );
                    },
                  ),
                ),
              )
            else
              const Expanded(child: Center(child: CircularProgressIndicator())),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -10)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _statusText,
                    style: GoogleFonts.inter(
                      color: _currentEmbedding != null ? Colors.greenAccent : (_isFaceDetected ? Colors.blueAccent : Colors.white70), 
                      fontSize: 16, 
                      fontWeight: FontWeight.w700
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_currentEmbedding == null || _currentSelfiePath == null)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (_cameraController != null && _cameraController!.value.isInitialized) ? _takePictureManual : null,
                        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                        label: Text("Ambil Foto Wajah", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFaceDetected ? const Color(0xFF1B60F1) : Colors.white24,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  if (_currentEmbedding != null && _currentSelfiePath != null)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _resetState,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text("Ulangi", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(RegisterFaceRequested(_currentEmbedding!, _currentSelfiePath!));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B60F1),
                                elevation: 8,
                                shadowColor: const Color(0xFF1B60F1).withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  if (state is AuthLoading) {
                                    return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3));
                                  }
                                  return Text("Simpan", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16));
                                }
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
