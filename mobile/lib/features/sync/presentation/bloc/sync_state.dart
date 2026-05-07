part of 'sync_bloc.dart';

abstract class SyncState extends Equatable {
  const SyncState();
  
  @override
  List<Object> get props => [];
}

class SyncInitial extends SyncState {}
class SyncInProgress extends SyncState {}
class SyncSuccess extends SyncState {}
class SyncMasterDataSuccess extends SyncState {}
class SyncFailure extends SyncState {
  final String error;
  const SyncFailure(this.error);
  
  @override
  List<Object> get props => [error];
}
