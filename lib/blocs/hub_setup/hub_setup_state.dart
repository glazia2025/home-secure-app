part of 'hub_setup_bloc.dart';

enum HubSetupStatus { initial, submitting, success, failure }

class HubSetupState extends Equatable {
  const HubSetupState({
    this.status = HubSetupStatus.initial,
    this.setupSession,
    this.error,
  });

  final HubSetupStatus status;
  final SetupSession? setupSession;
  final String? error;

  bool get isSubmitting => status == HubSetupStatus.submitting;

  HubSetupState copyWith({
    HubSetupStatus? status,
    SetupSession? setupSession,
    String? error,
    bool clearError = false,
  }) {
    return HubSetupState(
      status: status ?? this.status,
      setupSession: setupSession ?? this.setupSession,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, setupSession, error];
}
