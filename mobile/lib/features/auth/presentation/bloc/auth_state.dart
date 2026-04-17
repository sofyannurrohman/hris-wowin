import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  final bool isBiometricSupported;
  final bool isBiometricEnabled;

  const AuthState({
    this.isBiometricSupported = false,
    this.isBiometricEnabled = false,
  });
  
  @override
  List<Object?> get props => [isBiometricSupported, isBiometricEnabled];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final Map<String, dynamic>? userProfile;

  const Authenticated({
    this.userProfile,
    super.isBiometricSupported = false,
    super.isBiometricEnabled = false,
  });

  @override
  List<Object?> get props => [...super.props, userProfile ?? {}];
}

class Unauthenticated extends AuthState {
  const Unauthenticated({
    super.isBiometricSupported = false,
    super.isBiometricEnabled = false,
  });

  @override
  List<Object?> get props => super.props;
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message, {
    super.isBiometricSupported = false,
    super.isBiometricEnabled = false,
  });

  @override
  List<Object?> get props => [...super.props, message];
}

class FaceRegistrationSuccess extends AuthState {}

class RegisterSuccess extends AuthState {}
