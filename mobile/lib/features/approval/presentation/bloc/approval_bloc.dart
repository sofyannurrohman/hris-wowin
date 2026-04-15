import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/leave/domain/entities/leave.dart';
import 'package:hris_app/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_app/features/reimbursement/domain/entities/reimbursement.dart';
import 'package:hris_app/features/reimbursement/domain/repositories/reimbursement_repository.dart';

// Events
abstract class ApprovalEvent extends Equatable {
  const ApprovalEvent();
  @override
  List<Object?> get props => [];
}

class FetchPendingApprovalsRequested extends ApprovalEvent {}

class ApproveLeaveRequested extends ApprovalEvent {
  final String leaveId;
  final String status;
  const ApproveLeaveRequested(this.leaveId, this.status);
  @override
  List<Object?> get props => [leaveId, status];
}

class ApproveReimbursementRequested extends ApprovalEvent {
  final String reimbursementId;
  final String status;
  const ApproveReimbursementRequested(this.reimbursementId, this.status);
  @override
  List<Object?> get props => [reimbursementId, status];
}

// States
abstract class ApprovalState extends Equatable {
  const ApprovalState();
  @override
  List<Object?> get props => [];
}

class ApprovalInitial extends ApprovalState {}
class ApprovalLoading extends ApprovalState {}
class ApprovalActionLoading extends ApprovalState {}

class ApprovalDataLoaded extends ApprovalState {
  final List<Leave> pendingLeaves;
  final List<Reimbursement> pendingReimbursements;
  const ApprovalDataLoaded({required this.pendingLeaves, required this.pendingReimbursements});
  @override
  List<Object?> get props => [pendingLeaves, pendingReimbursements];
}

class ApprovalActionSuccess extends ApprovalState {
  final String message;
  const ApprovalActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ApprovalFailure extends ApprovalState {
  final String message;
  const ApprovalFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  final LeaveRepository leaveRepository;
  final ReimbursementRepository reimbursementRepository;

  ApprovalBloc({required this.leaveRepository, required this.reimbursementRepository}) : super(ApprovalInitial()) {
    on<FetchPendingApprovalsRequested>(_onFetchPending);
    on<ApproveLeaveRequested>(_onApproveLeave);
    on<ApproveReimbursementRequested>(_onApproveReimbursement);
  }

  Future<void> _onFetchPending(FetchPendingApprovalsRequested event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    final leaveResult = await leaveRepository.getAllLeaves('pending', 1, 100);
    final reimbursementResult = await reimbursementRepository.getAllPending(page: 1, limit: 100);

    List<Leave> leaves = [];
    List<Reimbursement> reimbursements = [];

    leaveResult.fold((f) => null, (l) => leaves = l);
    reimbursementResult.fold((f) => null, (r) => reimbursements = r);

    emit(ApprovalDataLoaded(pendingLeaves: leaves, pendingReimbursements: reimbursements));
  }

  Future<void> _onApproveLeave(ApproveLeaveRequested event, Emitter<ApprovalState> emit) async {
    final currentState = state;
    emit(ApprovalActionLoading());
    final result = await leaveRepository.approveLeave(event.leaveId, event.status);
    result.fold(
      (failure) => emit(ApprovalFailure(failure.message)),
      (_) {
        emit(ApprovalActionSuccess('Leave request ${event.status}'));
        add(FetchPendingApprovalsRequested());
      },
    );
  }

  Future<void> _onApproveReimbursement(ApproveReimbursementRequested event, Emitter<ApprovalState> emit) async {
    emit(ApprovalActionLoading());
    final result = await reimbursementRepository.approveReimbursement(event.reimbursementId, event.status);
    result.fold(
      (failure) => emit(ApprovalFailure(failure.message)),
      (_) {
        emit(ApprovalActionSuccess('Reimbursement request ${event.status}'));
        add(FetchPendingApprovalsRequested());
      },
    );
  }
}
