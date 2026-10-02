part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthBaseUrlChanged extends AuthEvent {
  const AuthBaseUrlChanged(this.baseUrl);

  final String baseUrl;

  @override
  List<Object?> get props => [baseUrl];
}

class AuthOtpRequested extends AuthEvent {
  const AuthOtpRequested(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthPhoneChangeRequested extends AuthEvent {
  const AuthPhoneChangeRequested();
}

class AuthOtpVerified extends AuthEvent {
  const AuthOtpVerified({required this.phoneNumber, required this.otp});

  final String phoneNumber;
  final String otp;

  @override
  List<Object?> get props => [phoneNumber, otp];
}

class AuthOtpRegistrationCompleted extends AuthEvent {
  const AuthOtpRegistrationCompleted({
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  final String name;
  final String email;
  final String phoneNumber;

  @override
  List<Object?> get props => [name, email, phoneNumber];
}
