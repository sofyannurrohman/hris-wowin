import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:hris_app/features/auth/domain/usecases/biometric_usecases.dart';
import 'package:hris_app/features/auth/domain/usecases/remember_me_usecases.dart';
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
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final GetRememberMeStatusUseCase getRememberMeStatusUseCase;
  final SetRememberMeEnabledUseCase setRememberMeEnabledUseCase;
  final GetRememberedCredentialsUseCase getRememberedCredentialsUseCase;
  final ClearRememberedCredentialsUseCase clearRememberedCredentialsUseCase;

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
    required this.forgotPasswordUseCase,
    required this.getRememberMeStatusUseCase,
    required this.setRememberMeEnabledUseCase,
    required this.getRememberedCredentialsUseCase,
    required this.clearRememberedCredentialsUseCase,
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
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<LoadRememberMeStatusRequested>(_onLoadRememberMeStatusRequested);
    on<ToggleRememberMeRequested>(_onToggleRememberMeRequested);
    on<LoadRememberedCredentialsRequested>(_onLoadRememberedCredentialsRequested);
  }


  Future<Map<String, bool>> _getAuthParams() async {
    final bio = await getBiometricStatusUseCase();
    final rememberMe = await getRememberMeStatusUseCase();
    return {
      'bio_supported': bio['supported'] ?? false,
      'bio_enabled': bio['enabled'] ?? false,
      'remember_me': rememberMe,
    };
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final params = await _getAuthParams();
    final result = await loginUseCase(event.email, event.password);
    
    await result.fold(
      (failure) async {
        emit(AuthError(
          failure.message, 
          isBiometricSupported: params['bio_supported']!, 
          isBiometricEnabled: params['bio_enabled']!,
          isRememberMeEnabled: params['remember_me']!,
        ));
      },
      (_) async {
        // Handle Remember Me
        await setRememberMeEnabledUseCase(event.rememberMe);
        if (!event.rememberMe) {
          await clearRememberedCredentialsUseCase();
        }

        final profileResult = await getProfileUseCase();
        Map<String, dynamic>? profile;
        profileResult.fold((_) => null, (p) => profile = p);
        emit(Authenticated(
          userProfile: profile,
          isBiometricSupported: params['bio_supported']!,
          isBiometricEnabled: params['bio_enabled']!,
          isRememberMeEnabled: event.rememberMe,
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
      (_) {
        emit(RegisterSuccess());
        // Restore unauthenticated state
        add(CheckAuthStatusRequested());
      },
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final params = await _getAuthParams();
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(
        failure.message, 
        isBiometricSupported: params['bio_supported']!, 
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
      )),
      (_) => emit(Unauthenticated(
        isBiometricSupported: params['bio_supported']!, 
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
      )),
    );
  }

  Future<void> _onCheckAuthStatusRequested(CheckAuthStatusRequested event, Emitter<AuthState> emit) async {
    final params = await _getAuthParams();
    final result = await checkAuthStatusUseCase();
    await result.fold(
      (failure) async => emit(Unauthenticated(
        isBiometricSupported: params['bio_supported']!, 
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
      )),
      (isAuthenticated) async {
        if (isAuthenticated) {
          final profileResult = await getProfileUseCase();
          Map<String, dynamic>? profile;
          profileResult.fold((_) => null, (p) => profile = p);
          emit(Authenticated(
            userProfile: profile,
            isBiometricSupported: params['bio_supported']!,
            isBiometricEnabled: params['bio_enabled']!,
            isRememberMeEnabled: params['remember_me']!,
          ));
        } else {
          emit(Unauthenticated(
            isBiometricSupported: params['bio_supported']!, 
            isBiometricEnabled: params['bio_enabled']!,
            isRememberMeEnabled: params['remember_me']!,
          ));
        }
      },
    );
  }

  Future<void> _onRegisterFaceRequested(RegisterFaceRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerFaceUseCase(event.embedding, event.selfiePath);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        emit(FaceRegistrationSuccess());
        // Restore auth status (could be authenticated or unauthenticated depending on context)
        add(CheckAuthStatusRequested());
      },
    );
  }

  Future<void> _onSessionExpired(SessionExpired event, Emitter<AuthState> emit) async {
    final params = await _getAuthParams();
    emit(Unauthenticated(
      isBiometricSupported: params['bio_supported']!, 
      isBiometricEnabled: params['bio_enabled']!,
      isRememberMeEnabled: params['remember_me']!,
    ));
  }

  Future<void> _onBiometricLoginRequested(BiometricLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final params = await _getAuthParams();
    final result = await biometricLoginUseCase();
    
    await result.fold(
      (failure) async => emit(AuthError(
        failure.message, 
        isBiometricSupported: params['bio_supported']!, 
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
      )),
      (_) async {
        final profileResult = await getProfileUseCase();
        Map<String, dynamic>? profile;
        profileResult.fold((_) => null, (p) => profile = p);
        emit(Authenticated(
          userProfile: profile,
          isBiometricSupported: params['bio_supported']!,
          isBiometricEnabled: params['bio_enabled']!,
          isRememberMeEnabled: params['remember_me']!,
        ));
      },
    );
  }

  Future<void> _onCheckBiometricSupportRequested(CheckBiometricSupportRequested event, Emitter<AuthState> emit) async {
    final params = await _getAuthParams();
    if (state is Authenticated) {
      emit(Authenticated(
        userProfile: (state as Authenticated).userProfile,
        isBiometricSupported: params['bio_supported']!,
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
      ));
    } else {
      emit(Unauthenticated(
        isBiometricSupported: params['bio_supported']!,
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
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
    final params = await _getAuthParams();
    final result = await changePasswordUseCase(event.oldPassword, event.newPassword);
    
    result.fold(
      (failure) => emit(AuthError(
        failure.message, 
        isBiometricSupported: params['bio_supported']!, 
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
      )),
      (_) {
        emit(ChangePasswordSuccess());
        // Restore authenticated state after success so AuthWrapper doesn't get stuck in loading
        emit(Authenticated(
          userProfile: currentProfile,
          isBiometricSupported: params['bio_supported']!,
          isBiometricEnabled: params['bio_enabled']!,
          isRememberMeEnabled: params['remember_me']!,
        ));
      },
    );
  }

  Future<void> _onForgotPasswordRequested(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final params = await _getAuthParams();
    final result = await forgotPasswordUseCase(event.email);
    
    result.fold(
      (failure) => emit(AuthError(
        failure.message, 
        isBiometricSupported: params['bio_supported']!, 
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
      )),
      (_) {
        emit(ForgotPasswordSuccess());
        // Restore unauthenticated state so AuthWrapper doesn't get stuck
        emit(Unauthenticated(
          isBiometricSupported: params['bio_supported']!,
          isBiometricEnabled: params['bio_enabled']!,
          isRememberMeEnabled: params['remember_me']!,
        ));
      },
    );
  }

  Future<void> _onLoadRememberMeStatusRequested(LoadRememberMeStatusRequested event, Emitter<AuthState> emit) async {
    final params = await _getAuthParams();
    if (state is Unauthenticated) {
      emit(Unauthenticated(
        isBiometricSupported: params['bio_supported']!,
        isBiometricEnabled: params['bio_enabled']!,
        isRememberMeEnabled: params['remember_me']!,
        rememberedCredentials: (state as Unauthenticated).rememberedCredentials,
      ));
    }
  }

  Future<void> _onToggleRememberMeRequested(ToggleRememberMeRequested event, Emitter<AuthState> emit) async {
    await setRememberMeEnabledUseCase(event.enabled);
    if (!event.enabled) {
      await clearRememberedCredentialsUseCase();
    }
    add(LoadRememberMeStatusRequested());
  }

  Future<void> _onLoadRememberedCredentialsRequested(LoadRememberedCredentialsRequested event, Emitter<AuthState> emit) async {
    final params = await _getAuthParams();
    if (params['remember_me']!) {
      final credResult = await getRememberedCredentialsUseCase();
      credResult.fold(
        (_) => null,
        (credentials) {
          if (credentials != null) {
            emit(Unauthenticated(
              rememberedCredentials: credentials,
              isBiometricSupported: params['bio_supported']!,
              isBiometricEnabled: params['bio_enabled']!,
              isRememberMeEnabled: params['remember_me']!,
            ));
          }
        },
      );
    }
  }
}
