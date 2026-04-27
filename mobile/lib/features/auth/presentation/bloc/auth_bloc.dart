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
  final GetProfileUseCase getProfileUseCase;
  final ChangePasswordUseCase changePasswordUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.registerFaceUseCase,
    required this.biometricLoginUseCase,
    required this.getBiometricStatusUseCase,
    required this.setBiometricEnabledUseCase,
    required this.getProfileUseCase,
    required this.changePasswordUseCase,
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
    on<ChangePasswordRequested>(_onChangePasswordRequested);
  }


  Future<Map<String, bool>> _getBioStatus() async {
    final status = await getBiometricStatusUseCase();
    return {
      'supported': status['supported'] ?? false,
      'enabled': status['enabled'] ?? false,
    };
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final bio = await _getBioStatus();
    final result = await loginUseCase(event.email, event.password);
    
    await result.fold(
      (failure) async {
        emit(AuthError(failure.message, isBiometricSupported: bio['supported']!, isBiometricEnabled: bio['enabled']!));
      },
      (_) async {
        final profileResult = await getProfileUseCase();
        Map<String, dynamic>? profile;
        profileResult.fold((_) => null, (p) => profile = p);
        emit(Authenticated(
          userProfile: profile,
          isBiometricSupported: bio['supported']!,
          isBiometricEnabled: bio['enabled']!,
        ));
      },
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
      (_) => emit(RegisterSuccess()),
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final bio = await _getBioStatus();
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message, isBiometricSupported: bio['supported']!, isBiometricEnabled: bio['enabled']!)),
      (_) => emit(Unauthenticated(isBiometricSupported: bio['supported']!, isBiometricEnabled: bio['enabled']!)),
    );
  }

  Future<void> _onCheckAuthStatusRequested(CheckAuthStatusRequested event, Emitter<AuthState> emit) async {
    final bio = await _getBioStatus();
    final result = await checkAuthStatusUseCase();
    await result.fold(
      (failure) async => emit(Unauthenticated(isBiometricSupported: bio['supported']!, isBiometricEnabled: bio['enabled']!)),
      (isAuthenticated) async {
        if (isAuthenticated) {
          final profileResult = await getProfileUseCase();
          Map<String, dynamic>? profile;
          profileResult.fold((_) => null, (p) => profile = p);
          emit(Authenticated(
            userProfile: profile,
            isBiometricSupported: bio['supported']!,
            isBiometricEnabled: bio['enabled']!,
          ));
        } else {
          emit(Unauthenticated(isBiometricSupported: bio['supported']!, isBiometricEnabled: bio['enabled']!));
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

  Future<void> _onSessionExpired(SessionExpired event, Emitter<AuthState> emit) async {
    final bio = await _getBioStatus();
    emit(Unauthenticated(isBiometricSupported: bio['supported']!, isBiometricEnabled: bio['enabled']!));
  }

  Future<void> _onBiometricLoginRequested(BiometricLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final bio = await _getBioStatus();
    final result = await biometricLoginUseCase();
    
    await result.fold(
      (failure) async => emit(AuthError(failure.message, isBiometricSupported: bio['supported']!, isBiometricEnabled: bio['enabled']!)),
      (_) async {
        final profileResult = await getProfileUseCase();
        Map<String, dynamic>? profile;
        profileResult.fold((_) => null, (p) => profile = p);
        emit(Authenticated(
          userProfile: profile,
          isBiometricSupported: bio['supported']!,
          isBiometricEnabled: bio['enabled']!,
        ));
      },
    );
  }

  Future<void> _onCheckBiometricSupportRequested(CheckBiometricSupportRequested event, Emitter<AuthState> emit) async {
    final bio = await _getBioStatus();
    if (state is Authenticated) {
      emit(Authenticated(
        userProfile: (state as Authenticated).userProfile,
        isBiometricSupported: bio['supported']!,
        isBiometricEnabled: bio['enabled']!,
      ));
    } else {
      emit(Unauthenticated(
        isBiometricSupported: bio['supported']!,
        isBiometricEnabled: bio['enabled']!,
      ));
    }
  }

  Future<void> _onToggleBiometricRequested(ToggleBiometricRequested event, Emitter<AuthState> emit) async {
    await setBiometricEnabledUseCase(event.enabled);
    add(CheckBiometricSupportRequested());
  }

  Future<void> _onChangePasswordRequested(ChangePasswordRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    Map<String, dynamic>? currentProfile;
    if (currentState is Authenticated) {
      currentProfile = currentState.userProfile;
    }

    emit(AuthLoading());
    final bio = await _getBioStatus();
    final result = await changePasswordUseCase(event.oldPassword, event.newPassword);
    
    result.fold(
      (failure) => emit(AuthError(
        failure.message, 
        isBiometricSupported: bio['supported']!, 
        isBiometricEnabled: bio['enabled']!
      )),
      (_) {
        emit(ChangePasswordSuccess());
        // Restore authenticated state after success so AuthWrapper doesn't get stuck in loading
        emit(Authenticated(
          userProfile: currentProfile,
          isBiometricSupported: bio['supported']!,
          isBiometricEnabled: bio['enabled']!,
        ));
      },
    );
  }

}
