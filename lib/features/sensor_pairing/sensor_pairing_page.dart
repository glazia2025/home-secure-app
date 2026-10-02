import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/app_colors.dart';
import '../../blocs/sensor_pairing/sensor_pairing_bloc.dart';
import '../../data/app_repository.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/cards.dart';
import '../../services/ble_permission_service.dart';
import '../../services/ble_provisioning_writer.dart';

class SensorPairingPage extends StatelessWidget {
  const SensorPairingPage({super.key, required this.home});

  final Home home;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SensorPairingBloc(context.read<AppRepository>()),
      child: SensorPairingView(home: home),
    );
  }
}

class SensorPairingView extends StatefulWidget {
  const SensorPairingView({super.key, required this.home});

  final Home home;

  @override
  State<SensorPairingView> createState() => _SensorPairingViewState();
}

class _SensorPairingViewState extends State<SensorPairingView> {
  static const _sensorProvisioningServiceUuid =
      '0000ff00-0000-1000-8000-00805f9b34fb';
  static const _sensorHubMacCharacteristicUuid =
      '0000ff10-0000-1000-8000-00805f9b34fb';
  static const _sensorProvisionKeyCharacteristicUuid =
      '0000ff11-0000-1000-8000-00805f9b34fb';

  final _formKey = GlobalKey<FormState>();
  final _sensorMacController = TextEditingController();
  final _nameController = TextEditingController(
    text: 'Front Door Frame Sensor',
  );
  final _zoneController = TextEditingController(text: 'Front Door Frame');
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _pairingPollTimer;
  final List<ScanResult> _bleDevices = [];
  ScanResult? _selectedBleDevice;
  int _currentStep = 0;
  bool _isScanningBle = false;
  bool _isProvisioningBle = false;
  bool _provisioningSent = false;
  bool _threadSensorPaired = false;
  String _threadCc = '';
  String _threadV = '';

  @override
  void dispose() {
    _sensorMacController.dispose();
    _nameController.dispose();
    _zoneController.dispose();
    _scanSubscription?.cancel();
    _pairingPollTimer?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _scanSensorQr() async {
    final payload = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SensorQrScannerPage()),
    );
    if (payload == null || payload.trim().isEmpty) return;

    final parsed = SensorQrPayload.parse(payload);
    setState(() {
      _sensorMacController.text = parsed.macAddress;
      _threadCc = parsed.cc;
      _threadV = parsed.v;
      if (parsed.name.isNotEmpty) _nameController.text = parsed.name;
      if (parsed.zone.isNotEmpty) _zoneController.text = parsed.zone;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SensorPairingBloc>().add(
      SensorPairingSubmitted(
        home: widget.home,
        eui: _sensorMacController.text.trim(),
        cc: _threadCc,
        v: _threadV,
        name: _nameController.text.trim(),
        zone: _zoneController.text.trim(),
      ),
    );
  }

  void _continue(SensorPairingState state) {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      _submit();
      setState(() => _currentStep = 2);
      return;
    }

    if (_provisioningSent || state.result?.sensor.identifierType == 'eui64') {
      Navigator.of(context).pop();
      return;
    }

    _sendSensorProvisioning(state.result);
  }

  void _cancel() {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentStep -= 1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SensorPairingBloc, SensorPairingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SensorPairingStatus.success) {
          if (state.result?.sensor.identifierType == 'eui64') {
            AppToast.show(
              context,
              'Waiting for the hub to commission the sensor',
            );
            _startThreadPairingPoll(state.result!.sensor.id);
          } else {
            AppToast.show(context, 'Select sensor over Bluetooth');
            _startBleScan();
          }
        }
        if (state.status == SensorPairingStatus.failure) {
          setState(() => _currentStep = 1);
          AppToast.show(context, state.error ?? 'Failed to pair sensor');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Sensor')),
        body: BlocBuilder<SensorPairingBloc, SensorPairingState>(
          builder: (context, state) {
            final result = state.result;
            return Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () => _continue(state),
              onStepCancel: _cancel,
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == 2;
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          loading: _currentStep == 1 && state.isSubmitting,
                          onPressed:
                              isLastStep &&
                                  (state.result == null || _isProvisioningBle)
                              ? null
                              : details.onStepContinue,
                          icon: isLastStep
                              ? _provisioningSent ||
                                        result?.sensor.identifierType == 'eui64'
                                    ? Icons.check
                                    : Icons.bluetooth_connected
                              : _currentStep == 1
                              ? Icons.add_link_outlined
                              : Icons.arrow_forward,
                          label: isLastStep
                              ? _provisioningSent ||
                                        result?.sensor.identifierType == 'eui64'
                                    ? 'Done'
                                    : 'Send to sensor'
                              : _currentStep == 1
                              ? 'Create provisioning'
                              : 'Continue',
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Hub'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This sensor will be linked to ${widget.home.hub.name}. After pairing, the hub can fetch the pending sensor provision key from the backend.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      DetailRow(
                        icon: Icons.router_outlined,
                        label: 'Hub',
                        value: widget.home.hub.macAddress,
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Scan'),
                  isActive: _currentStep >= 1,
                  state: result != null
                      ? StepState.complete
                      : _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  content: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan the QR printed on the frame sensor. Its sensor ID (EUI-64) is required.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          onPressed: _scanSensorQr,
                          icon: Icons.qr_code_scanner,
                          label: 'Scan sensor QR',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _sensorMacController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Sensor ID',
                            prefixIcon: Icon(Icons.qr_code_scanner),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Sensor ID is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Sensor name',
                            prefixIcon: Icon(Icons.sensors_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Sensor name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _zoneController,
                          decoration: const InputDecoration(
                            labelText: 'Zone',
                            prefixIcon: Icon(Icons.meeting_room_outlined),
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 12),
                          ErrorBanner(message: state.error!),
                        ],
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Join'),
                  isActive: _currentStep >= 2,
                  state: result != null
                      ? StepState.complete
                      : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result == null
                            ? 'Creating sensor pairing request...'
                            : result.sensor.identifierType == 'eui64'
                            ? _threadSensorPaired
                                  ? 'Sensor joined the Thread network successfully.'
                                  : 'Place the sensor near the hub. The hub will commission it onto the Thread network automatically.'
                            : 'Select the sensor Bluetooth device, then send its hub pairing credentials over BLE.',
                      ),
                      const SizedBox(height: 16),
                      if (result == null)
                        const Center(child: CircularProgressIndicator())
                      else if (result.sensor.identifierType == 'eui64') ...[
                        Center(
                          child: _threadSensorPaired
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.accent,
                                  size: 44,
                                )
                              : const CircularProgressIndicator(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _threadSensorPaired
                              ? 'Pairing confirmed by the hub.'
                              : 'Waiting for pairing confirmation from the hub…',
                        ),
                      ] else ...[
                        _SensorBleDevicePicker(
                          devices: _bleDevices,
                          selectedDevice: _selectedBleDevice,
                          isScanning: _isScanningBle,
                          onScan: _startBleScan,
                          onSelected: (device) {
                            setState(() {
                              _selectedBleDevice = device;
                              _provisioningSent = false;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _provisioningSent
                              ? const _SensorProvisioningSuccessBanner(
                                  message:
                                      'Sensor pairing credentials sent. The sensor can now join this hub.',
                                )
                              : Text(
                                  'The app sends [hub_mac, prov_key] to the selected sensor.',
                                  key: const ValueKey('sensor-pair-hint'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _startThreadPairingPoll(String sensorId) {
    _pairingPollTimer?.cancel();
    _pairingPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final homes = await context.read<AppRepository>().homes();
        final sensors = homes
            .where((home) => home.id == widget.home.id)
            .expand((home) => home.sensors);
        final paired = sensors.any(
          (sensor) =>
              sensor.id == sensorId &&
              const {'paired', 'online'}.contains(sensor.status),
        );
        if (!mounted || !paired) return;
        _pairingPollTimer?.cancel();
        setState(() => _threadSensorPaired = true);
        AppToast.show(context, 'Sensor paired successfully');
      } catch (_) {
        // Keep waiting; transient refresh failures should not abort commissioning.
      }
    });
  }

  Future<void> _startBleScan() async {
    final allowed = await BlePermissionService.requestScanAndConnect();
    if (!allowed) {
      if (mounted) AppToast.show(context, 'Bluetooth permission is required');
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (mounted) AppToast.show(context, 'Turn on Bluetooth to scan sensors');
      return;
    }

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _bleDevices
          ..clear()
          ..addAll(results.where(_isUsefulBleResult));
        if (_selectedBleDevice != null &&
            !_bleDevices.any(
              (result) =>
                  result.device.remoteId == _selectedBleDevice!.device.remoteId,
            )) {
          _selectedBleDevice = null;
        }
      });
    });

    setState(() {
      _isScanningBle = true;
      _bleDevices.clear();
      _selectedBleDevice = null;
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 12),
        androidUsesFineLocation: false,
      );
    } catch (error) {
      if (mounted) AppToast.show(context, 'Unable to scan: $error');
    } finally {
      if (mounted) setState(() => _isScanningBle = false);
    }
  }

  bool _isUsefulBleResult(ScanResult result) {
    final name = _sensorDeviceName(result);
    return name.isNotEmpty || result.advertisementData.serviceUuids.isNotEmpty;
  }

  Future<void> _sendSensorProvisioning(PairSensorResult? result) async {
    if (result == null) return;
    if (_selectedBleDevice == null) {
      AppToast.show(context, 'Select a Bluetooth sensor first');
      return;
    }

    final provisionKey = _provisionKeyFrom(result);
    if (provisionKey.isEmpty) {
      AppToast.show(context, 'Provision key is missing');
      return;
    }
    if (provisionKey.length != 32) {
      AppToast.show(context, 'Provision key must be 32 characters');
      return;
    }

    final hubMacAddress = widget.home.hub.macAddress.trim().toUpperCase();
    if (hubMacAddress.length != 17) {
      AppToast.show(context, 'Hub MAC address is invalid');
      return;
    }

    setState(() => _isProvisioningBle = true);

    final device = _selectedBleDevice!.device;
    try {
      await FlutterBluePlus.stopScan();
      await device.connect(
        license: License.commercial,
        timeout: const Duration(seconds: 15),
        mtu: null,
      );

      final services = await device.discoverServices();
      final characteristics = _findSensorProvisioningCharacteristics(services);
      if (characteristics == null) {
        throw StateError('Sensor provisioning characteristics not found');
      }

      await device
          .requestMtu(185, predelay: 0.5, timeout: 8)
          .catchError((_) => 23);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await BleProvisioningWriter.writeText(
        characteristics.hubMac,
        hubMacAddress,
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await BleProvisioningWriter.writeText(
        characteristics.provisionKey,
        provisionKey,
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;
      setState(() => _provisioningSent = true);
      AppToast.show(context, 'Sensor pairing credentials sent');
    } catch (error) {
      if (mounted) AppToast.show(context, 'BLE provisioning failed: $error');
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
      if (mounted) setState(() => _isProvisioningBle = false);
    }
  }

  String _provisionKeyFrom(PairSensorResult result) {
    final fromSensorPayload = result.sensorPayload['provisionKey'];
    if (fromSensorPayload != null) {
      return fromSensorPayload.toString().trim();
    }

    final fromSensor = result.sensor.provisioning['provisionKey'];
    if (fromSensor != null) {
      return fromSensor.toString().trim();
    }

    final fromHubPayload = result.hubPayload['provisionKey'];
    if (fromHubPayload != null) {
      return fromHubPayload.toString().trim();
    }

    return '';
  }

  _SensorProvisioningCharacteristics? _findSensorProvisioningCharacteristics(
    List<BluetoothService> services,
  ) {
    for (final service in services) {
      if (!_uuidMatches(
        service.serviceUuid.str128,
        _sensorProvisioningServiceUuid,
      )) {
        continue;
      }

      BluetoothCharacteristic? hubMac;
      BluetoothCharacteristic? provisionKey;
      for (final characteristic in service.characteristics) {
        final uuid = characteristic.characteristicUuid.str128;
        if (!_canWrite(characteristic)) continue;
        if (_uuidMatches(uuid, _sensorHubMacCharacteristicUuid)) {
          hubMac = characteristic;
        } else if (_uuidMatches(uuid, _sensorProvisionKeyCharacteristicUuid)) {
          provisionKey = characteristic;
        }
      }

      if (hubMac != null && provisionKey != null) {
        return _SensorProvisioningCharacteristics(
          hubMac: hubMac,
          provisionKey: provisionKey,
        );
      }
    }

    return null;
  }

  bool _uuidMatches(String actual, String expected128) {
    final normalizedActual = actual.toLowerCase();
    final normalizedExpected = expected128.toLowerCase();
    if (normalizedActual == normalizedExpected) return true;
    final shortExpected = normalizedExpected.substring(4, 8);
    return normalizedActual == shortExpected ||
        normalizedActual == '0x$shortExpected';
  }

  bool _canWrite(BluetoothCharacteristic characteristic) {
    return characteristic.properties.write ||
        characteristic.properties.writeWithoutResponse;
  }
}

class _SensorProvisioningCharacteristics {
  const _SensorProvisioningCharacteristics({
    required this.hubMac,
    required this.provisionKey,
  });

  final BluetoothCharacteristic hubMac;
  final BluetoothCharacteristic provisionKey;
}

class _SensorBleDevicePicker extends StatelessWidget {
  const _SensorBleDevicePicker({
    required this.devices,
    required this.selectedDevice,
    required this.isScanning,
    required this.onScan,
    required this.onSelected,
  });

  final List<ScanResult> devices;
  final ScanResult? selectedDevice;
  final bool isScanning;
  final VoidCallback onScan;
  final ValueChanged<ScanResult> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth_searching, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Available Bluetooth sensors',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Scan again',
                onPressed: isScanning ? null : onScan,
                icon: isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                isScanning
                    ? 'Scanning for sensors...'
                    : 'No Bluetooth sensors found. Put the sensor in pairing mode and scan again.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...devices.map((result) {
              final selected =
                  selectedDevice?.device.remoteId == result.device.remoteId;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.16)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(result),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected
                              ? AppColors.accent
                              : AppColors.mutedText,
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.sensors_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sensorDeviceName(result),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${result.device.remoteId.str}  •  RSSI ${result.rssi}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SensorProvisioningSuccessBanner extends StatelessWidget {
  const _SensorProvisioningSuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sensor-provisioning-success'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _sensorDeviceName(ScanResult result) {
  final advertisedName = result.advertisementData.advName.trim();
  if (advertisedName.isNotEmpty) return advertisedName;

  final platformName = result.device.platformName.trim();
  if (platformName.isNotEmpty) return platformName;

  return 'Unknown sensor';
}

class SensorQrScannerPage extends StatefulWidget {
  const SensorQrScannerPage({super.key});

  @override
  State<SensorQrScannerPage> createState() => _SensorQrScannerPageState();
}

class _SensorQrScannerPageState extends State<SensorQrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Sensor QR')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              String? code;
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  code = barcode.rawValue;
                  break;
                }
              }
              if (code == null || code.isEmpty) return;
              _handled = true;
              Navigator.of(context).pop(code);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black.withValues(alpha: 0.72),
              child: const Text(
                'Point the camera at the sensor QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SensorQrPayload {
  const SensorQrPayload({
    required this.macAddress,
    required this.name,
    required this.zone,
    this.cc = '',
    this.v = '',
  });

  final String macAddress;
  final String name;
  final String zone;
  final String cc;
  final String v;

  static SensorQrPayload parse(String raw) {
    final trimmed = raw.trim();
    // Thread Joiner QR: v=1&&eui=<16-hex>&&cc=<PSKd>
    if (trimmed.startsWith('v=1&&')) {
      final fields = <String, String>{};
      for (final part in trimmed.split('&&')) {
        final separator = part.indexOf('=');
        if (separator < 0) continue;
        fields[part.substring(0, separator)] = part.substring(separator + 1);
      }
      final eui64 = (fields['eui'] ?? '').trim().toUpperCase();
      final pskd = (fields['cc'] ?? '').trim().toUpperCase();
      if (RegExp(r'^[A-F0-9]{16}$').hasMatch(eui64) && pskd.isNotEmpty) {
        return SensorQrPayload(
          macAddress: eui64,
          name: '',
          zone: '',
          cc: pskd,
          v: fields['v'] ?? '1',
        );
      }
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return SensorQrPayload(
          macAddress:
              (decoded['sensorMacAddress'] ??
                      decoded['macAddress'] ??
                      decoded['mac'] ??
                      '')
                  .toString()
                  .trim(),
          name: (decoded['name'] ?? '').toString().trim(),
          zone: (decoded['zone'] ?? '').toString().trim(),
        );
      }
    } catch (_) {}

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.isNotEmpty) {
      return SensorQrPayload(
        macAddress:
            (uri.queryParameters['sensorMacAddress'] ??
                    uri.queryParameters['macAddress'] ??
                    uri.queryParameters['mac'] ??
                    '')
                .trim(),
        name: (uri.queryParameters['name'] ?? '').trim(),
        zone: (uri.queryParameters['zone'] ?? '').trim(),
      );
    }

    return SensorQrPayload(macAddress: trimmed, name: '', zone: '');
  }
}
