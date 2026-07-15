part of 'sensor_pairing_bloc.dart';

enum SensorPairingStatus { initial, submitting, success, failure }

class SensorPairingState extends Equatable {
  const SensorPairingState({
    this.status = SensorPairingStatus.initial,
    this.result,
    this.error,
  });

  final SensorPairingStatus status;
  final PairSensorResult? result;
  final String? error;

  bool get isSubmitting => status == SensorPairingStatus.submitting;

  SensorPairingState copyWith({
    SensorPairingStatus? status,
    PairSensorResult? result,
    String? error,
    bool clearError = false,
  }) {
    return SensorPairingState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, result, error];
}
