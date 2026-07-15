import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_repository.dart';
import '../../data/models.dart';

part 'hub_setup_event.dart';
part 'hub_setup_state.dart';

class HubSetupBloc extends Bloc<HubSetupEvent, HubSetupState> {
  HubSetupBloc(this._repository) : super(const HubSetupState()) {
    on<HubSetupSubmitted>(_onSubmitted);
  }

  final AppRepository _repository;

  Future<void> _onSubmitted(
    HubSetupSubmitted event,
    Emitter<HubSetupState> emit,
  ) async {
    emit(state.copyWith(status: HubSetupStatus.submitting, clearError: true));
    try {
      final setup = await _repository.startHubSetup(
        hubMacAddress: event.hubMacAddress,
        homeName: event.homeName,
        location: event.location,
      );
      emit(
        state.copyWith(
          status: HubSetupStatus.success,
          setupSession: setup,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: HubSetupStatus.failure, error: error.toString()),
      );
    }
  }
}
