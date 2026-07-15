import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_repository.dart';
import '../../data/models.dart';
import '../../services/push_notification_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthBaseUrlChanged>(_onBaseUrlChanged);
    on<AuthOtpRequested>(_onOtpRequested);
    on<AuthOtpVerified>(_onOtpVerified);
    on<AuthOtpRegistrationCompleted>(_onOtpRegistrationCompleted);
  }

  final AppRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final baseUrl = await _repository.getBaseUrl();
    try {
      final session = await _repository.restoreSession();
      if (session == null) {
        emit(
          state.copyWith(status: AuthStatus.unauthenticated, baseUrl: baseUrl),
        );
        return;
      }
      await _registerPushToken();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          baseUrl: baseUrl,
          token: session.token,
          user: session.user,
          homes: session.homes,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          baseUrl: baseUrl,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final session = await _repository.login(event.email, event.password);
      await _registerPushToken();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          token: session.token,
          user: session.user,
          homes: session.homes,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final session = await _repository.register(
        event.name,
        event.email,
        event.password,
      );
      await _registerPushToken();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          token: session.token,
          user: session.user,
          homes: session.homes,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _unregisterPushToken();
    await _repository.clearToken();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearToken: true,
        clearUser: true,
        homes: const [],
      ),
    );
  }

  Future<void> _onOtpRequested(
    AuthOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final result = await _repository.requestOtp(event.phoneNumber);
      emit(
        state.copyWith(
          status: AuthStatus.otpSent,
          phoneNumber: result.phoneNumber,
          devOtp: result.otp,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onOtpVerified(
    AuthOtpVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final result = await _repository.verifyOtp(event.phoneNumber, event.otp);
      final session = result.session;
      if (session != null) {
        await _registerPushToken();
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            token: session.token,
            user: session.user,
            homes: session.homes,
            clearError: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.registrationRequired,
          phoneNumber: result.phoneNumber ?? event.phoneNumber,
          otpSessionId: result.otpSessionId,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: AuthStatus.otpSent, error: error.toString()));
    }
  }

  Future<void> _onOtpRegistrationCompleted(
    AuthOtpRegistrationCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final otpSessionId = state.otpSessionId;
      if (otpSessionId == null) {
        throw Exception('OTP registration session missing');
      }
      final session = await _repository.completeOtpRegistration(
        otpSessionId: otpSessionId,
        name: event.name,
        email: event.email,
        phoneNumber: event.phoneNumber,
      );
      await _registerPushToken();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          token: session.token,
          user: session.user,
          homes: session.homes,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.registrationRequired,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onBaseUrlChanged(
    AuthBaseUrlChanged event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.saveBaseUrl(event.baseUrl);
    emit(state.copyWith(baseUrl: await _repository.getBaseUrl()));
  }

  Future<void> _registerPushToken() async {
    try {
      await PushNotificationService.registerDevice(_repository);
    } catch (_) {}
  }

  Future<void> _unregisterPushToken() async {
    try {
      await PushNotificationService.unregisterDevice(_repository);
    } catch (_) {}
  }
}
