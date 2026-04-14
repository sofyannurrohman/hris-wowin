import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart' show XFile;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';

class AttendanceStats {
  final double totalHours;
  final double overtimeHours;
  final int attendanceDays;
  final int leaveDays;

  AttendanceStats({
    required this.totalHours,
    required this.overtimeHours,
    required this.attendanceDays,
    required this.leaveDays,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalHours: (json['total_hours'] as num).toDouble(),
      overtimeHours: (json['overtime_hours'] as num).toDouble(),
      attendanceDays: json['attendance_days'] as int,
      leaveDays: json['leave_days'] as int,
    );
  }
}

class AttendanceRepository {
  final ApiClient apiClient;

  AttendanceRepository({required this.apiClient});

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final webBrowserInfo = await deviceInfo.webBrowserInfo;
      return webBrowserInfo.userAgent ?? 'unknown_web';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    } else {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<String> clockIn(String photoPath, List<double> embedding) async {
    try {
      final position = await _getCurrentLocation();
      final xFile = XFile(photoPath);
      final bytes = await xFile.readAsBytes();
      final base64Photo = base64Encode(bytes);

      final data = {
        "latitude": position.latitude,
        "longitude": position.longitude,
        "selfie": base64Photo,
        "face_embedding": embedding,
      };

      final response = await apiClient.client.post(
        'attendance/checkin',
        data: data,
      );

      return response.data['message'] ?? 'Clock In Success';
    } on DioException catch (e) {
      final errorMsg = (e.response?.data is Map) ? (e.response?.data['error'] ?? e.response?.data['message'] ?? 'Terjadi kesalahan jaringan') : 'Terjadi kesalahan jaringan';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> clockOut(String photoPath, List<double> embedding) async {
    try {
      final position = await _getCurrentLocation();
      final xFile = XFile(photoPath);
      final bytes = await xFile.readAsBytes();
      final base64Photo = base64Encode(bytes);

      final data = {
        "latitude": position.latitude,
        "longitude": position.longitude,
        "selfie": base64Photo,
        "face_embedding": embedding,
      };

      final response = await apiClient.client.post(
        'attendance/checkout',
        data: data,
      );

      return response.data['message'] ?? 'Clock Out Success';
    } on DioException catch (e) {
      final errorMsg = (e.response?.data is Map) ? (e.response?.data['error'] ?? e.response?.data['message'] ?? 'Terjadi kesalahan jaringan') : 'Terjadi kesalahan jaringan';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Attendance>> fetchHistory({int page = 1, int limit = 10}) async {
    try {
      final response = await apiClient.client.get(
        'attendance/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Attendance.fromJson(json)).toList();
    } on DioException catch (e) {
      final errorMsg = (e.response?.data is Map) ? (e.response?.data['error'] ?? e.response?.data['message'] ?? 'Terjadi kesalahan jaringan') : 'Terjadi kesalahan jaringan';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<AttendanceStats> fetchStats() async {
    try {
      final response = await apiClient.client.get('attendance/stats');
      return AttendanceStats.fromJson(response.data['data']);
    } on DioException catch (e) {
      final errorMsg = (e.response?.data is Map) ? (e.response?.data['error'] ?? e.response?.data['message'] ?? 'Terjadi kesalahan jaringan') : 'Terjadi kesalahan jaringan';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
