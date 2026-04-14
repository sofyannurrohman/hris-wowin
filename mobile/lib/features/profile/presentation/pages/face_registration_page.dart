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
    _mlService.initialize();
    
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
      print("Error processing image: \$e");
    }
    _isProcessing = false;
  }

  Future<void> _extractFaceEmbedding(CameraImage image, Face face) async {
    try {
      imglib.Image convertedImage = _convertCameraImage(image);
      final embedding = _mlService.predict(convertedImage);
      
      // Stop the stream and take a high res picture for baseline
      await _cameraController!.stopImageStream();
      final xFile = await _cameraController!.takePicture();
      
      if (mounted) {
        setState(() {
          _currentEmbedding = embedding;
          _currentSelfiePath = xFile.path;
          _statusText = "Data wajah berhasil diambil. Siap disimpan.";
        });
      }
    } catch (e) {
      print("Error extracting embedding: \$e");
      if (mounted) {
        setState(() {
          _statusText = "Gagal memproses wajah.";
        });
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _currentEmbedding != null
                          ? () {
                              context.read<AuthBloc>().add(RegisterFaceRequested(_currentEmbedding!, _currentSelfiePath!));
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B60F1),
                        disabledBackgroundColor: Colors.grey,
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
