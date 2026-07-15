part of 'hub_setup_bloc.dart';

sealed class HubSetupEvent extends Equatable {
  const HubSetupEvent();

  @override
  List<Object?> get props => [];
}

class HubSetupSubmitted extends HubSetupEvent {
  const HubSetupSubmitted({
    required this.hubMacAddress,
    required this.homeName,
    required this.location,
  });

  final String hubMacAddress;
  final String homeName;
  final String location;

  @override
  List<Object?> get props => [hubMacAddress, homeName, location];
}
