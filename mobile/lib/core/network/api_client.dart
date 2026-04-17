import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hris_app/core/utils/constants.dart';

class ApiClient {
  late Dio dio;
  final SharedPreferences prefs;

  // StreamController to broadcast 401 Unauthorized events
  final StreamController<bool> _unauthorizedController =
      StreamController<bool>.broadcast();
  Stream<bool> get onUnauthorized => _unauthorizedController.stream;

  ApiClient({required this.prefs}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = prefs.getString(AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Don't broadcast 401 for login endpoint to avoid session expired state during login attempts
          if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('login')) {
            // Remove token immediately
            await prefs.remove(AppConstants.tokenKey);
            // Broadcast the unauthorized event
            _unauthorizedController.add(true);
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => dio;
  String get baseUrl => dio.options.baseUrl;

  // Cleanup stream controller
  void dispose() {
    _unauthorizedController.close();
  }
}
