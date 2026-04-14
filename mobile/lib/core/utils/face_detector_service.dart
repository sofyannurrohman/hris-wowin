import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  void initialize() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true, // for smile/eyes open probabilities
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

    // Get image format
    final processFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (processFormat == null ||
        (processFormat != InputImageFormat.nv21 &&
            processFormat != InputImageFormat.yuv_420_888 &&
            processFormat != InputImageFormat.bgra8888)) {
      return null;
    }

    // Since format is supported, we can process it
    if (image.planes.length != 1 && image.planes.length != 3) {
      return null;
    }

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: processFormat, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}
