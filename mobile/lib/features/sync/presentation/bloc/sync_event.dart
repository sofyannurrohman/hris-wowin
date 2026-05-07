part of 'sync_bloc.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object> get props => [];
}

class SyncStarted extends SyncEvent {}
class SyncDataRequested extends SyncEvent {}
class SyncMasterDataRequested extends SyncEvent {}
