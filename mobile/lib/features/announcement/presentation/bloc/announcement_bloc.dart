import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/announcement/data/models/announcement_model.dart';
import 'package:hris_app/features/announcement/data/repositories/announcement_repository.dart';

// Events
abstract class AnnouncementEvent extends Equatable {
  const AnnouncementEvent();
  @override
  List<Object?> get props => [];
}

class FetchAnnouncementsRequested extends AnnouncementEvent {}

// States
abstract class AnnouncementState extends Equatable {
  const AnnouncementState();
  @override
  List<Object?> get props => [];
}

class AnnouncementInitial extends AnnouncementState {}
class AnnouncementLoading extends AnnouncementState {}
class AnnouncementLoaded extends AnnouncementState {
  final List<Announcement> announcements;
  const AnnouncementLoaded(this.announcements);
  @override
  List<Object?> get props => [announcements];
}
class AnnouncementFailure extends AnnouncementState {
  final String message;
  const AnnouncementFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  final AnnouncementRepository repository;

  AnnouncementBloc({required this.repository}) : super(AnnouncementInitial()) {
    on<FetchAnnouncementsRequested>((event, emit) async {
      emit(AnnouncementLoading());
      final result = await repository.getAnnouncements();
      result.fold(
        (failure) => emit(AnnouncementFailure(failure.message)),
        (lists) => emit(AnnouncementLoaded(lists)),
      );
    });
  }
}
