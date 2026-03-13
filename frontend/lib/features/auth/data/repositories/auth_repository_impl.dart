import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart' show XFile;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hris_app/core/error/failures.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/core/utils/constants.dart';
import 'package:hris_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final SharedPreferences prefs;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.prefs,
  });

  @override
  Future<Either<Failure, void>> login(String email, String password) async {
    try {
      final response = await apiClient.client.post('login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final accessToken = data['token'];
        final refreshToken = data['refresh_token'];
        
        await prefs.setString(AppConstants.tokenKey, accessToken);
        await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
        return const Right(null);
      } else {
        final msg = response.data is Map ? (response.data['message'] ?? 'Login failed') : 'Login failed';
        return Left(ServerFailure(msg));
      }
    } on DioException catch (e) {
      String errorMessage = 'Login failed';
      
      if (e.response != null) {
        if (e.response?.data is Map) {
          errorMessage = e.response?.data['message'] ?? 'Login failed';
        } else if (e.response?.data is String && e.response?.data.isNotEmpty) {
          // Sometimes error is returned as plain string or HTML on error
          errorMessage = e.response?.data;
        } else {
          errorMessage = 'Invalid email or password'; // Default for 401/403 if no body
        }
      } else {
        errorMessage = e.message ?? 'Connection error';
      }
      
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> register(String name, String email, String employeeId, String password, String jobPositionId, {List<double>? embedding, String? selfiePath}) async {
    try {
      String? base64Selfie;
      if (selfiePath != null) {
        final xFile = XFile(selfiePath);
        final bytes = await xFile.readAsBytes();
        base64Selfie = base64Encode(bytes);
      }

      final response = await apiClient.client.post(
        'register',
        data: {
          'name': name,
          'email': email,
          'employee_id': employeeId,
          'password': password,
          'job_position_id': jobPositionId,
          'face_embedding': embedding,
          'selfie': base64Selfie,
        },
      );
      
      if (response.statusCode == 201) {
        return const Right(null);
      } else {
        return Left(ServerFailure(response.data is Map ? (response.data['message'] ?? 'Registration failed') : 'Registration failed'));
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        return Left(ServerFailure(e.response?.data['message'] ?? 'Registration failed'));
      }
      return Left(ServerFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to logout'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        return const Right(true);
      }
      return const Right(false);
    } catch (e) {
      return const Left(CacheFailure('Failed to check auth status'));
    }
  }

  @override
  Future<Either<Failure, void>> registerFace(List<double> embedding, String selfiePath) async {
    try {
      final xFile = XFile(selfiePath);
      final bytes = await xFile.readAsBytes();
      final base64Selfie = base64Encode(bytes);

      final response = await apiClient.client.post('users/face-register', data: {
        'embedding': embedding,
        'selfie': base64Selfie,
      });

      if (response.statusCode == 200) {
        final stringList = embedding.map((e) => e.toString()).toList();
        await prefs.setStringList('face_embedding', stringList);
        return const Right(null);
      } else {
        return Left(ServerFailure(response.data is Map ? (response.data['message'] ?? 'Face registration failed') : 'Face registration failed'));
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        return Left(ServerFailure(e.response?.data['message'] ?? 'Face registration failed'));
      }
      return Left(ServerFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<double>?>> getStoredFaceEmbedding() async {
    try {
      final stringList = prefs.getStringList('face_embedding');
      if (stringList == null) return const Right(null);
      
      final embedding = stringList.map((e) => double.parse(e)).toList();
      return Right(embedding);
    } catch (e) {
      return const Left(CacheFailure('Failed to retrieve stored face data'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProfile() async {
    try {
      final response = await apiClient.client.get('employees/profile');
      if (response.statusCode == 200) {
        return Right(response.data['data']);
      } else {
        return Left(ServerFailure(response.data is Map ? (response.data['message'] ?? 'Failed to get profile') : 'Failed to get profile'));
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        return Left(ServerFailure(e.response?.data['message'] ?? 'Failed to get profile'));
      }
      return Left(ServerFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.client.put('employees/profile', data: data);
      if (response.statusCode == 200) {
        return const Right(null);
      } else {
        return Left(ServerFailure(response.data is Map ? (response.data['message'] ?? 'Failed to update profile') : 'Failed to update profile'));
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        return Left(ServerFailure(e.response?.data['message'] ?? 'Failed to update profile'));
      }
      return Left(ServerFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
