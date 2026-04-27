import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';


abstract class AuthRepository {
  Future<Either<Failure, void>> login(String email, String password);
  Future<Either<Failure, void>> loginWithBiometric();
  Future<Either<Failure, bool>> isBiometricSupported();
  Future<Either<Failure, void>> setBiometricEnabled(bool enabled);
  Future<Either<Failure, bool>> getBiometricEnabled();
  Future<Either<Failure, void>> register(String name, String email, String employeeId, String password, String jobPositionId, String branchId, {List<double>? embedding, String? selfiePath});
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> checkAuthStatus();
  Future<Either<Failure, void>> registerFace(List<double> embedding, String selfiePath);
  Future<Either<Failure, List<double>?>> getStoredFaceEmbedding();
  Future<Either<Failure, Map<String, dynamic>>> getProfile();
  Future<Either<Failure, List<Map<String, dynamic>>>> getBranches();
  Future<Either<Failure, List<Map<String, dynamic>>>> getJobPositions();
  Future<Either<Failure, void>> updateProfile(Map<String, dynamic> data);
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword);
  Future<Either<Failure, void>> forgotPassword(String email);
}

