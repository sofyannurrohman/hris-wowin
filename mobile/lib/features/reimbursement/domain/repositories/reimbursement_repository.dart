import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';
import 'package:hris_app/features/reimbursement/domain/entities/reimbursement.dart';

abstract class ReimbursementRepository {
  Future<Either<Failure, void>> submitReimbursement({
    required String title,
    String? description,
    required double amount,
    String? attachmentPath,
  });
  Future<Either<Failure, List<Reimbursement>>> getMyHistory({int page = 1, int limit = 10});
  Future<Either<Failure, List<Reimbursement>>> getAllPending({int page = 1, int limit = 20});
  Future<Either<Failure, void>> approveReimbursement(String id, String status);
}
