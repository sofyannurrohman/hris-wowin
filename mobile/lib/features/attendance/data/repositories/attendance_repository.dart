import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart' show XFile;
import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/core/services/local_database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;

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
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      overtimeHours: (json['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      attendanceDays: json['attendance_days'] ?? 0,
      leaveDays: json['leave_days'] ?? 0,
    );
  }
}

class AttendanceRepository {
  final ApiClient apiClient;
  final LocalDatabaseService localDb;

  AttendanceRepository({required this.apiClient, required this.localDb});

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
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

  Future<Either<Failure, Attendance>> checkIn(double lat, double lng, String? photoPath, List<double>? faceEmbedding) async {
    try {
      String? base64Photo;
      if (photoPath != null) {
        final xFile = XFile(photoPath);
        final bytes = await xFile.readAsBytes();
        base64Photo = base64Encode(bytes);
      }

      final data = {
        "latitude": lat,
        "longitude": lng,
        "selfie": base64Photo,
        "face_embedding": faceEmbedding ?? [], 
      };

      final response = await apiClient.client.post(
        'attendance/checkin',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final attendanceData = response.data['data'];
        if (attendanceData != null) {
          return Right(Attendance.fromJson(attendanceData));
        }
      }
      return Left(ServerFailure('Gagal memproses data kehadiran dari server'));
    } on DioException catch (e) {
      final errorMsg = (e.response?.data is Map) ? (e.response?.data['error'] ?? e.response?.data['message'] ?? 'Terjadi kesalahan jaringan') : 'Terjadi kesalahan jaringan';
      return Left(ServerFailure(errorMsg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Attendance>> checkOut(double lat, double lng, String? photoPath, List<double>? faceEmbedding) async {
    try {
      String? base64Photo;
      if (photoPath != null) {
        final xFile = XFile(photoPath);
        final bytes = await xFile.readAsBytes();
        base64Photo = base64Encode(bytes);
      }

      final data = {
        "latitude": lat,
        "longitude": lng,
        "selfie": base64Photo,
        "face_embedding": faceEmbedding ?? [], 
      };

      final response = await apiClient.client.post(
        'attendance/checkout',
        data: data,
      );

      if (response.statusCode == 200) {
        final attendanceData = response.data['data'];
        if (attendanceData != null) {
          return Right(Attendance.fromJson(attendanceData));
        }
      }

      return Left(ServerFailure('Gagal memproses data kehadiran dari server'));
    } on DioException catch (e) {
      final errorMsg = (e.response?.data is Map) ? (e.response?.data['error'] ?? e.response?.data['message'] ?? 'Terjadi kesalahan jaringan') : 'Terjadi kesalahan jaringan';
      return Left(ServerFailure(errorMsg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<Attendance>>> getHistory({String? startDate, String? endDate}) async {
    try {
      final response = await apiClient.client.get('attendance/history', queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return Right(data.map((e) => Attendance.fromJson(e)).toList());
      }
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, AttendanceStats>> fetchStats() async {
    try {
      final response = await apiClient.client.get('attendance/stats');
      if (response.statusCode == 200) {
        return Right(AttendanceStats.fromJson(response.data['data']));
      }
      return Right(AttendanceStats(totalHours: 0, overtimeHours: 0, attendanceDays: 0, leaveDays: 0));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<int> getQueueCount() async {
    return await localDb.getQueueCount();
  }

  Future<void> saveOffline(String type, String photoPath, double lat, double lng, List<double> embedding) async {
    await localDb.insertAttendance({
      'type': type,
      'photoPath': photoPath,
      'latitude': lat,
      'longitude': lng,
      'embedding': jsonEncode(embedding),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, int>> syncQueue() async {
    final queue = await localDb.getAttendanceQueue();
    int success = 0;
    int fail = 0;

    for (var item in queue) {
      try {
        success++;
        await localDb.deleteAttendance(item['id']);
      } catch (e) {
        fail++;
      }
    }
    return {'success': success, 'fail': fail};
  }
}
