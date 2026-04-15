import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:hris_app/features/auth/domain/usecases/biometric_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final RegisterFaceUseCase registerFaceUseCase;
  final BiometricLoginUseCase biometricLoginUseCase;
  final GetBiometricStatusUseCase getBiometricStatusUseCase;
  final SetBiometricEnabledUseCase setBiometricEnabledUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.registerFaceUseCase,
    required this.biometricLoginUseCase,
    required this.getBiometricStatusUseCase,
    required this.setBiometricEnabledUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatusRequested>(_onCheckAuthStatusRequested);
    on<RegisterFaceRequested>(_onRegisterFaceRequested);
    on<SessionExpired>(_onSessionExpired);
    on<BiometricLoginRequested>(_onBiometricLoginRequested);
    on<CheckBiometricSupportRequested>(_onCheckBiometricSupportRequested);
    on<ToggleBiometricRequested>(_onToggleBiometricRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(event.email, event.password);
    result.fold(
      (failure) {
        print('Login Error: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (_) => emit(Authenticated()),
    );
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerUseCase(
      event.name,
      event.email,
      event.employeeId,
      event.password,
      event.jobPositionId,
      event.branchId,
      embedding: event.embedding,
      selfiePath: event.selfiePath,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()), // Stay on unauthenticated but can navigate back to login
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatusRequested(CheckAuthStatusRequested event, Emitter<AuthState> emit) async {
    final result = await checkAuthStatusUseCase();
    result.fold(
      (failure) => emit(Unauthenticated()),
      (isAuthenticated) {
        if (isAuthenticated) {
          emit(Authenticated());
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _onRegisterFaceRequested(RegisterFaceRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerFaceUseCase(event.embedding, event.selfiePath);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(FaceRegistrationSuccess()),
    );
  }

  void _onSessionExpired(SessionExpired event, Emitter<AuthState> emit) {
    emit(Unauthenticated());
  }

  Future<void> _onBiometricLoginRequested(BiometricLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await biometricLoginUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Authenticated()),
    );
  }

  Future<void> _onCheckBiometricSupportRequested(CheckBiometricSupportRequested event, Emitter<AuthState> emit) async {
    final status = await getBiometricStatusUseCase();
    emit(Unauthenticated(
      isBiometricSupported: status['supported'] ?? false,
      isBiometricEnabled: status['enabled'] ?? false,
    ));
  }

  Future<void> _onToggleBiometricRequested(ToggleBiometricRequested event, Emitter<AuthState> emit) async {
    await setBiometricEnabledUseCase(event.enabled);
    add(CheckBiometricSupportRequested());
  }
}
