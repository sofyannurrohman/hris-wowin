class AppConstants {
  // Use 10.0.2.2 for Android Emulator, or localhost for Web/Desktop/iOS
  // static const String baseUrl = 'http://10.0.2.2:8081/api/v1'; 
  static const String baseUrl = 'http://localhost:8081/api/v1/';
  
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Face Verification Threshold (Lower = stricter)
  // Standard range for MobileFaceNet is 0.8 - 1.2
  static const double faceVerificationThreshold = 0.9;
}
