class AppConstants {
  // Use localhost for Physical Device (run: adb reverse tcp:8081 tcp:8081)
  // Or use 10.0.2.2 for Android Emulator
  // Or use your specific LAN IP (e.g., 192.168.10.69) for Wi-Fi debugging
  // static const String baseUrl = 'http://localhost:8081/api/v1/';
  static const String baseUrl = 'https://hris.wowinapps.cloud/api/v1/';
  
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Face Verification Threshold (Lower = stricter)
  // Standard range for MobileFaceNet is 0.8 - 1.2
  static const double faceVerificationThreshold = 0.9;
}
