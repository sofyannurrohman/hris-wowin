import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class GeminiOcrService {
  final String apiKey;

  GeminiOcrService({required this.apiKey});

  /// Processes the image locally on the device via Gemini Flash API 
  /// before sending JSON payload to backend to save VPS bandwidth.
  Future<Map<String, dynamic>> extractReceiptLocally(XFile imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final imageBytes = await File(imageFile.path).readAsBytes();
      
      final prompt = TextPart('''
        Analyze this store receipt and extract the following information in JSON format:
        {
          "receipt_no": "string or null",
          "total_amount": number,
          "date": "YYYY-MM-DD or null"
        }
        Return ONLY valid JSON.
      ''');
      
      final imagePart = DataPart('image/jpeg', imageBytes);
      
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final jsonString = _cleanJsonString(response.text ?? '{}');
      // Simulated parsing of JSON here. In a real app use jsonDecode
      
      return {
        "status": "success",
        "data": jsonString,
      };
    } catch (e) {
      return {
        "status": "error",
        "message": "Failed to extract locally: \${e.toString()}"
      };
    }
  }

  String _cleanJsonString(String input) {
    String cleaned = input.replaceAll('```json', '').replaceAll('```', '').trim();
    return cleaned;
  }
}
