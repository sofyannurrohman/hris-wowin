import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'reimbursement_event.dart';
import 'reimbursement_state.dart';

class ReimbursementBloc extends Bloc<ReimbursementEvent, ReimbursementState> {
  final ReimbursementRepository repository;

  ReimbursementBloc({required this.repository}) : super(ReimbursementInitial()) {
    on<SubmitReimbursementRequested>(_onSubmitReimbursement);
    on<FetchReimbursementHistoryRequested>(_onFetchHistory);
  }

  Future<void> _onSubmitReimbursement(SubmitReimbursementRequested event, Emitter<ReimbursementState> emit) async {
    emit(ReimbursementLoading());
    final result = await repository.submitReimbursement(
      title: event.title,
      description: event.description,
      amount: event.amount,
      attachmentPath: event.attachmentPath,
    );
    result.fold(
      (failure) => emit(ReimbursementFailure(failure.message)),
      (_) => emit(const ReimbursementActionSuccess('Reimbursement submitted successfully!')),
    );
  }

  Future<void> _onFetchHistory(FetchReimbursementHistoryRequested event, Emitter<ReimbursementState> emit) async {
    emit(ReimbursementLoading());
    final result = await repository.getMyHistory(page: event.page, limit: event.limit);
    result.fold(
      (failure) => emit(ReimbursementFailure(failure.message)),
      (history) => emit(ReimbursementHistoryLoaded(history)),
    );
  }
}
