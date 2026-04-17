import 'package:equatable/equatable.dart';

abstract class ReimbursementEvent extends Equatable {
  const ReimbursementEvent();

  @override
  List<Object?> get props => [];
}

class SubmitReimbursementRequested extends ReimbursementEvent {
  final String title;
  final String? description;
  final double amount;
  final String? attachmentPath;

  const SubmitReimbursementRequested({
    required this.title,
    this.description,
    required this.amount,
    this.attachmentPath,
  });

  @override
  List<Object?> get props => [title, description, amount, attachmentPath];
}

class FetchReimbursementHistoryRequested extends ReimbursementEvent {
  final int page;
  final int limit;

  const FetchReimbursementHistoryRequested({this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [page, limit];
}

class ApproveReimbursementRequested extends ReimbursementEvent {
  final String id;
  final String status;

  const ApproveReimbursementRequested(this.id, this.status);

  @override
  List<Object> get props => [id, status];
}

class UpdateReimbursementRequested extends ReimbursementEvent {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final String? attachmentPath;

  const UpdateReimbursementRequested({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    this.attachmentPath,
  });

  @override
  List<Object> get props => [id, title, description ?? '', amount, attachmentPath ?? ''];
}

class DeleteReimbursementRequested extends ReimbursementEvent {
  final String id;

  const DeleteReimbursementRequested(this.id);

  @override
  List<Object> get props => [id];
}
