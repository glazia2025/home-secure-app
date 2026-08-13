import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_repository.dart';
import '../../data/models.dart';

part 'sensor_pairing_event.dart';
part 'sensor_pairing_state.dart';

class SensorPairingBloc extends Bloc<SensorPairingEvent, SensorPairingState> {
  SensorPairingBloc(this._repository) : super(const SensorPairingState()) {
    on<SensorPairingSubmitted>(_onSubmitted);
  }

  final AppRepository _repository;

  Future<void> _onSubmitted(
    SensorPairingSubmitted event,
    Emitter<SensorPairingState> emit,
  ) async {
    emit(
      state.copyWith(status: SensorPairingStatus.submitting, clearError: true),
    );
    try {
      final result = await _repository.pairSensor(
        home: event.home,
        eui: event.eui,
        cc: event.cc,
        v: event.v,
        name: event.name,
        zone: event.zone,
      );
      emit(
        state.copyWith(
          status: SensorPairingStatus.success,
          result: result,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SensorPairingStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }
}
