class AppConstants {
  // Use localhost for Physical Device (run: adb reverse tcp:8081 tcp:8081)
  // Or use 10.0.2.2 for Android Emulator
  // Or use your specific LAN IP (e.g., 192.168.10.69) for Wi-Fi debugging
  // Use environment variable for Base URL, default to production
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://hris.wowinapps.cloud/api/v1/',
  );
  
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Face Verification Threshold (Lower = stricter)
  // Standard range for MobileFaceNet is 0.8 - 1.2
  static const double faceVerificationThreshold = 0.9;

  static const String rememberMeKey = 'remember_me';
  static const String emailKey = 'remembered_email';
  static const String passwordKey = 'remembered_password';
}
