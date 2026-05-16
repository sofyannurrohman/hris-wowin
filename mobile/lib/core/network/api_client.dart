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
          // Don't broadcast 401 for login/refresh endpoints to avoid loops
          if (e.response?.statusCode == 401 && 
              !e.requestOptions.path.contains('login') && 
              !e.requestOptions.path.contains('refresh-token')) {
            
            final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Create a fresh Dio instance to avoid interceptor recursion
                final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
                final response = await refreshDio.post('refresh-token', data: {
                  'refresh_token': refreshToken,
                });

                if (response.statusCode == 200) {
                  final data = response.data['data'];
                  final newToken = data['token'];
                  final newRefreshToken = data['refresh_token'];

                  // Save new tokens
                  await prefs.setString(AppConstants.tokenKey, newToken);
                  await prefs.setString(AppConstants.refreshTokenKey, newRefreshToken);

                  // Update original request header and retry
                  e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  
                  // Use the original dio to retry, it will use the updated header
                  final retryResponse = await dio.fetch(e.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (refreshError) {
                // If refresh fails, we must logout
              }
            }

            // Remove tokens and broadcast unauthorized event
            await prefs.remove(AppConstants.tokenKey);
            await prefs.remove(AppConstants.refreshTokenKey);
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
