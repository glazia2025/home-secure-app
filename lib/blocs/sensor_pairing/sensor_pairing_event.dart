part of 'sensor_pairing_bloc.dart';

sealed class SensorPairingEvent extends Equatable {
  const SensorPairingEvent();

  @override
  List<Object?> get props => [];
}

class SensorPairingSubmitted extends SensorPairingEvent {
  const SensorPairingSubmitted({
    required this.home,
    required this.eui,
    required this.cc,
    required this.v,
    required this.name,
    required this.zone,
  });

  final Home home;
  final String eui;
  final String cc;
  final String v;
  final String name;
  final String zone;

  @override
  List<Object?> get props => [home, eui, cc, v, name, zone];
}
