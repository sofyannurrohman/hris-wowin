import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hris_app/core/utils/face_detector_service.dart';
import 'package:hris_app/core/utils/ml_service.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:image/image.dart' as imglib;
import 'package:hris_app/core/utils/snackbar_utils.dart';

class _FaceProcessingParams {
  final String path;
  final Rect boundingBox;
  _FaceProcessingParams(this.path, this.boundingBox);
}

Future<imglib.Image?> _decodeAndCropFaceBackground(_FaceProcessingParams params) async {
  try {
    final bytes = await File(params.path).readAsBytes();
    final imglib.Image? capturedImage = imglib.decodeImage(bytes);
    if (capturedImage == null) return null;

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
          // Face is good
          if (mounted && !_isFaceDetected) {
            setState(() {
              _isFaceDetected = true;
              _statusText = "Wajah terdeteksi. Mengambil data...";
            });
          }

          if (_currentEmbedding == null) {
            await _extractFaceEmbedding(image, face);
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

  Future<void> _extractFaceEmbedding(CameraImage image, Face face) async {
    try {
      imglib.Image convertedImage = _convertCameraImage(image);
      
      // Pre-process for ML: crop to face bounding box
      final imglib.Image faceCrop = imglib.copyCrop(
        convertedImage,
        x: face.boundingBox.left.toInt(),
        y: face.boundingBox.top.toInt(),
        width: face.boundingBox.width.toInt(),
        height: face.boundingBox.height.toInt(),
      );

      if (!_mlService.isInitialized) {
        debugPrint("MLService not initialized, skipping extraction.");
        return;
      }
      final embedding = _mlService.predict(faceCrop);
      
      if (mounted) {
        setState(() {
          _currentEmbedding = embedding;
          _statusText = "Data wajah berhasil diambil. Siap disimpan.";
        });
      }
    } catch (e) {
      debugPrint("Error extracting embedding: $e");
    }
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
      
      // Face detection on the captured file
      final faces = await _faceDetectorService.processImageFromFile(xFile.path);
      
      if (faces.isEmpty) {
        if (mounted) {
          SnackBarUtils.showError(context, "Wajah tidak ditemukan di foto. Coba lagi.");
          _initializeServices(); // Restart stream/camera
        }
        return;
      }

      final face = faces.first;
      
      // OFF-LOAD HEAVY DECODING AND CROPPING TO ISOLATE
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
        setState(() {
          _currentEmbedding = embedding;
          _currentSelfiePath = xFile.path;
          _statusText = "Data wajah berhasil diambil. Siap disimpan.";
        });
      }
    } catch (e) {
      print("Manual capture error: $e");
      if (mounted) {
        setState(() => _statusText = "Gagal memproses wajah.");
        SnackBarUtils.showError(context, "Gagal: $e");
        _initializeServices();
      }
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
    // Rotate image to portrait since NV21 from Android camera is landscape
    return imglib.copyRotate(img, angle: -90);
  }

  imglib.Image _convertBGRA8888(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final imglib.Image img = imglib.Image.fromBytes(width: width, height: height, bytes: image.planes[0].bytes.buffer, order: imglib.ChannelOrder.bgra);
    return img; // iOS usually handles rotation appropriately
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
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else
              const Expanded(child: Center(child: CircularProgressIndicator())),
            
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _statusText,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (_currentEmbedding == null)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: (_cameraController != null && _cameraController!.value.isInitialized) ? _takePictureManual : null,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text("Ambil Foto Wajah", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (_currentEmbedding != null)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(RegisterFaceRequested(_currentEmbedding!, _currentSelfiePath!));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B60F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is AuthLoading) {
                              return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                            }
                            return Text("Simpan Data Wajah", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold));
                          }
                        ),
                      ),
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
