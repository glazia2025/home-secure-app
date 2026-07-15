part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  registrationRequired,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.baseUrl = AppRepository.defaultBaseUrl,
    this.token,
    this.user,
    this.homes = const [],
    this.phoneNumber = "",
    this.otpSessionId,
    this.devOtp,
    this.error,
  });

  final AuthStatus status;
  final String baseUrl;
  final String? token;
  final AppUser? user;
  final List<Home> homes;
  final String phoneNumber;
  final String? otpSessionId;
  final String? devOtp;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isBusy => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    String? baseUrl,
    String? token,
    AppUser? user,
    List<Home>? homes,
    String? phoneNumber,
    String? otpSessionId,
    String? devOtp,
    String? error,
    bool clearToken = false,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      baseUrl: baseUrl ?? this.baseUrl,
      token: clearToken ? null : token ?? this.token,
      user: clearUser ? null : user ?? this.user,
      homes: homes ?? this.homes,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpSessionId: otpSessionId ?? this.otpSessionId,
      devOtp: devOtp ?? this.devOtp,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    baseUrl,
    token,
    user,
    homes,
    phoneNumber,
    otpSessionId,
    devOtp,
    error,
  ];
}
