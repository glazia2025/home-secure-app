part of 'sensor_pairing_bloc.dart';

sealed class SensorPairingEvent extends Equatable {
  const SensorPairingEvent();

  @override
  List<Object?> get props => [];
}

class SensorPairingSubmitted extends SensorPairingEvent {
  const SensorPairingSubmitted({
    required this.home,
    required this.sensorMacAddress,
    required this.name,
    required this.zone,
  });

  final Home home;
  final String sensorMacAddress;
  final String name;
  final String zone;

  @override
  List<Object?> get props => [home, sensorMacAddress, name, zone];
}
