import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as imglib;
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  late Interpreter _interpreter;
  bool _isInitialized = false;

  void initialize() async {
    try {
      Delegate delegate;
      if (!kIsWeb && Platform.isAndroid) {
        delegate = GpuDelegateV2();
      } else {
        delegate = GpuDelegate();
      }

      var interpreterOptions = InterpreterOptions()..addDelegate(delegate);
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite',
          options: interpreterOptions);
      _isInitialized = true;
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  List<double> predict(imglib.Image image) {
    if (!_isInitialized) throw Exception('MLService is not initialized');

    // Resize image to expected input shape: [1, 112, 112, 3]
    imglib.Image resizedImage = imglib.copyResizeCropSquare(image, size: 112);

    List input = imageToByteListFloat32(resizedImage, 112, 127.5, 127.5);
    List output = List.generate(1, (index) => List.filled(192, 0.0));

    _interpreter.run(input, output);
    
    // Normalize the output vector
    List<double> rawOutput = output[0];
    return _normalize(rawOutput);
  }

  List imageToByteListFloat32(
      imglib.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixelSafe(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  List<double> _normalize(List<double> input) {
    double sum = 0.0;
    for (int i = 0; i < input.length; i++) {
      sum += input[i] * input[i];
    }
    double length = sqrt(sum);
    for (int i = 0; i < input.length; i++) {
      input[i] /= length;
    }
    return input;
  }

  double calculateEuclideanDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) {
      throw Exception('Embeddings must have the same length');
    }
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  void dispose() {
    if (_isInitialized) {
      _interpreter.close();
      _isInitialized = false;
    }
  }
}
