import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';


abstract class AuthRepository {
  Future<Either<Failure, void>> login(String email, String password);
  Future<Either<Failure, void>> register(String name, String email, String employeeId, String password, String jobPositionId, {List<double>? embedding, String? selfiePath});
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> checkAuthStatus();
  Future<Either<Failure, void>> registerFace(List<double> embedding, String selfiePath);
  Future<Either<Failure, List<double>?>> getStoredFaceEmbedding();
  Future<Either<Failure, Map<String, dynamic>>> getProfile();
  Future<Either<Failure, void>> updateProfile(Map<String, dynamic> data);
}
