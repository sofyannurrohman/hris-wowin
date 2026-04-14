import 'package:equatable/equatable.dart';
import 'package:hris_app/features/leave/domain/entities/leave.dart';

import 'package:hris_app/features/leave/domain/entities/leave_balance.dart';

abstract class LeaveState extends Equatable {
  const LeaveState();
  
  @override
  List<Object?> get props => [];
}

class LeaveBalancesLoaded extends LeaveState {
  final List<LeaveBalance> balances;

  const LeaveBalancesLoaded(this.balances);

  @override
  List<Object?> get props => [balances];
}


class LeaveInitial extends LeaveState {}

class LeaveLoading extends LeaveState {}

class LeaveActionSuccess extends LeaveState {
  final String message;

  const LeaveActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class LeaveActionFailure extends LeaveState {
  final String message;

  const LeaveActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class LeavesLoaded extends LeaveState {
  final List<Leave> leaves;

  const LeavesLoaded(this.leaves);

  @override
  List<Object?> get props => [leaves];
}

class LeavesFailure extends LeaveState {
  final String message;

  const LeavesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
