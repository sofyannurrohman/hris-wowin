import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/sync_repository.dart';

part 'sync_event.dart';
part 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository syncRepository;
  late StreamSubscription _connectivitySubscription;

  SyncBloc({required this.syncRepository}) : super(SyncInitial()) {
    on<SyncStarted>(_onSyncStarted);
    on<SyncDataRequested>(_onSyncDataRequested);
    on<SyncMasterDataRequested>(_onSyncMasterDataRequested);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // In connectivity_plus 6.x, it returns List<ConnectivityResult>
      if (results.any((r) => r != ConnectivityResult.none)) {
        add(SyncDataRequested());
      }
    });
  }

  Future<void> _onSyncStarted(SyncStarted event, Emitter<SyncState> emit) async {
    add(SyncDataRequested());
  }

  Future<void> _onSyncDataRequested(SyncDataRequested event, Emitter<SyncState> emit) async {
    emit(SyncInProgress());
    try {
      await syncRepository.syncAll();
      emit(SyncSuccess());
    } catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }

  Future<void> _onSyncMasterDataRequested(SyncMasterDataRequested event, Emitter<SyncState> emit) async {
    emit(SyncInProgress());
    try {
      await syncRepository.pullMasterData();
      emit(SyncMasterDataSuccess());
    } catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
