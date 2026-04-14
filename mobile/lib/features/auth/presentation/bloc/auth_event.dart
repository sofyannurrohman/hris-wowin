import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String employeeId;
  final String password;
  final String jobPositionId;
  final List<double>? embedding;
  final String? selfiePath;

  const RegisterRequested(
    this.name,
    this.email,
    this.employeeId,
    this.password,
    this.jobPositionId, {
    this.embedding,
    this.selfiePath,
  });

  @override
  List<Object> get props => [name, email, employeeId, password, jobPositionId, embedding ?? [], selfiePath ?? ''];
}

class CheckAuthStatusRequested extends AuthEvent {}

class RegisterFaceRequested extends AuthEvent {
  final List<double> embedding;
  final String selfiePath;

  const RegisterFaceRequested(this.embedding, this.selfiePath);

  @override
  List<Object> get props => [embedding, selfiePath];
}

class SessionExpired extends AuthEvent {}
