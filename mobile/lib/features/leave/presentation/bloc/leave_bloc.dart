import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/leave/domain/usecases/leave_usecases.dart';
import 'leave_event.dart';
import 'leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final SubmitLeaveUseCase submitLeaveUseCase;
  final GetMyLeavesUseCase getMyLeavesUseCase;
  final GetAllLeavesUseCase getAllLeavesUseCase;
  final ApproveLeaveUseCase approveLeaveUseCase;
  final GetLeaveBalancesUseCase getLeaveBalancesUseCase;

  LeaveBloc({
    required this.submitLeaveUseCase,
    required this.getMyLeavesUseCase,
    required this.getAllLeavesUseCase,
    required this.approveLeaveUseCase,
    required this.getLeaveBalancesUseCase,
  }) : super(LeaveInitial()) {
    on<SubmitLeaveRequested>(_onSubmitLeave);
    on<FetchMyLeavesRequested>(_onFetchMyLeaves);
    on<FetchAllLeavesRequested>(_onFetchAllLeaves);
    on<ApproveLeaveRequested>(_onApproveLeave);
    on<FetchLeaveBalancesRequested>(_onFetchLeaveBalances);
  }

  Future<void> _onSubmitLeave(SubmitLeaveRequested event, Emitter<LeaveState> emit) async {
    emit(LeaveLoading());
    final result = await submitLeaveUseCase(event.leaveTypeId, event.startDate, event.endDate, event.reason, attachmentPath: event.attachmentPath);
    result.fold(
      (failure) => emit(LeaveActionFailure(failure.message)),
      (_) => emit(const LeaveActionSuccess('Leave submitted successfully!')),
    );
  }

  Future<void> _onFetchMyLeaves(FetchMyLeavesRequested event, Emitter<LeaveState> emit) async {
    emit(LeaveLoading());
    final result = await getMyLeavesUseCase(page: event.page, limit: event.limit);
    result.fold(
      (failure) => emit(LeavesFailure(failure.message)),
      (leaves) => emit(LeavesLoaded(leaves)),
    );
  }

  Future<void> _onFetchAllLeaves(FetchAllLeavesRequested event, Emitter<LeaveState> emit) async {
    emit(LeaveLoading());
    final result = await getAllLeavesUseCase(status: event.status, page: event.page, limit: event.limit);
    result.fold(
      (failure) => emit(LeavesFailure(failure.message)),
      (leaves) => emit(LeavesLoaded(leaves)),
    );
  }

  Future<void> _onApproveLeave(ApproveLeaveRequested event, Emitter<LeaveState> emit) async {
    emit(LeaveLoading());
    final result = await approveLeaveUseCase(event.leaveId, event.status);
    result.fold(
      (failure) => emit(LeaveActionFailure(failure.message)),
      (_) => emit(LeaveActionSuccess('Leave status updated to ${event.status}')),
    );
  }

  Future<void> _onFetchLeaveBalances(FetchLeaveBalancesRequested event, Emitter<LeaveState> emit) async {
    final result = await getLeaveBalancesUseCase();
    result.fold(
      (failure) => emit(LeavesFailure(failure.message)),
      (balances) => emit(LeaveBalancesLoaded(balances)),
    );
  }
}
