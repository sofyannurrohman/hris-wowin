import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  void initialize() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  Future<List<Face>> processImage(InputImage inputImage) async {
    if (!_isInitialized) {
      throw Exception('FaceDetectorService is not initialized');
    }
    return await _faceDetector.processImage(inputImage);
  }

  Future<List<Face>> processImageFromFile(String filePath) async {
    if (!_isInitialized) {
      throw Exception('FaceDetectorService is not initialized');
    }
    final inputImage = InputImage.fromFilePath(filePath);
    return await _faceDetector.processImage(inputImage);
  }

  void dispose() {
    if (_isInitialized) {
      _faceDetector.close();
      _isInitialized = false;
    }
  }

  InputImage? createInputImageFromCameraImage(
      CameraImage image, CameraDescription camera) {
    // Get image rotation
    final int sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    // Determine format based on plane count (more reliable on flaky Android devices)
    final int numPlanes = image.planes.length;
    final InputImageFormat format = numPlanes == 3 
        ? InputImageFormat.yuv_420_888 
        : InputImageFormat.nv21;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }
}
