import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';
import 'package:hris_app/features/leave/domain/entities/leave.dart';
import 'package:hris_app/features/leave/domain/entities/leave_balance.dart';

abstract class LeaveRepository {
  Future<Either<Failure, void>> submitLeave(String leaveTypeId, String startDate, String endDate, String reason, {String? attachmentPath});
  Future<Either<Failure, List<Leave>>> getMyLeaves(int page, int limit);
  Future<Either<Failure, List<Leave>>> getAllLeaves(String? status, int page, int limit);
  Future<Either<Failure, void>> approveLeave(String leaveId, String status);
  Future<Either<Failure, List<LeaveBalance>>> getMyBalances();
  Future<Either<Failure, void>> updateLeave(String leaveId, String leaveTypeId, String startDate, String endDate, String reason, {String? attachmentPath});
  Future<Either<Failure, void>> deleteLeave(String leaveId);
}

