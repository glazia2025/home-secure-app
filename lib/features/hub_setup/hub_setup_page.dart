import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/app_colors.dart';
import '../../blocs/hub_setup/hub_setup_bloc.dart';
import '../../data/app_repository.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/cards.dart';
import '../../services/ble_permission_service.dart';
import '../../services/ble_provisioning_writer.dart';

class HubSetupPage extends StatelessWidget {
  const HubSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HubSetupBloc(context.read<AppRepository>()),
      child: const HubSetupView(),
    );
  }
}

class HubSetupView extends StatefulWidget {
  const HubSetupView({super.key});

  @override
  State<HubSetupView> createState() => _HubSetupViewState();
}

class _HubSetupViewState extends State<HubSetupView> {
  static const _hubProvisioningServiceUuid =
      '000000ff-0000-1000-8000-00805f9b34fb';
  static const _hubSsidCharacteristicUuid =
      '0000ff01-0000-1000-8000-00805f9b34fb';
  static const _hubPasswordCharacteristicUuid =
      '0000ff02-0000-1000-8000-00805f9b34fb';
  static const _hubTokenCharacteristicUuid =
      '0000ff03-0000-1000-8000-00805f9b34fb';

  final _formKey = GlobalKey<FormState>();
  final _wifiFormKey = GlobalKey<FormState>();
  final _homeNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _hubMacController = TextEditingController();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final List<ScanResult> _bleDevices = [];
  ScanResult? _selectedBleDevice;
  int _currentStep = 0;
  bool _isScanningBle = false;
  bool _isProvisioningBle = false;
  bool _provisioningSent = false;

  @override
  void dispose() {
    _homeNameController.dispose();
    _locationController.dispose();
    _hubMacController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<HubSetupBloc>().add(
      HubSetupSubmitted(
        hubMacAddress: _hubMacController.text.trim(),
        homeName: _homeNameController.text.trim(),
        location: _locationController.text.trim(),
      ),
    );
  }

  Future<void> _scanHubQr() async {
    final payload = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const HubQrScannerPage()));
    if (payload == null || payload.trim().isEmpty) return;

    final parsed = HubQrPayload.parse(payload);
    setState(() {
      _hubMacController.text = parsed.macAddress;
    });
  }

  void _continue(HubSetupState state) {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (_hubMacController.text.trim().isEmpty) {
        AppToast.show(context, 'Scan the hub QR code first');
        return;
      }
      _submit();
      setState(() => _currentStep = 2);
      return;
    }

    if (_provisioningSent) {
      Navigator.of(context).pop();
      return;
    }

    _sendProvisioningPayload(state.setupSession);
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
    return BlocListener<HubSetupBloc, HubSetupState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == HubSetupStatus.success) {
          AppToast.show(context, 'Select hub over Bluetooth');
          _startBleScan();
        }
        if (state.status == HubSetupStatus.failure) {
          setState(() => _currentStep = 1);
          AppToast.show(context, state.error ?? 'Failed to create token');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Hub')),
        body: BlocBuilder<HubSetupBloc, HubSetupState>(
          builder: (context, state) {
            final setup = state.setupSession;
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
                                  (state.setupSession == null ||
                                      _isProvisioningBle)
                              ? null
                              : details.onStepContinue,
                          icon: isLastStep
                              ? _provisioningSent
                                    ? Icons.check
                                    : Icons.bluetooth_connected
                              : _currentStep == 1
                              ? Icons.vpn_key_outlined
                              : Icons.arrow_forward,
                          label: isLastStep
                              ? _provisioningSent
                                    ? 'Done'
                                    : 'Send to hub'
                              : _currentStep == 1
                              ? 'Create token'
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
                  title: const Text('Home'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  content: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create the home that this hub will secure.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _homeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Home name',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Home name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location or address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Scan'),
                  isActive: _currentStep >= 1,
                  state: setup != null
                      ? StepState.complete
                      : _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan the QR printed on the hub. It should contain the hub MAC address.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        onPressed: _scanHubQr,
                        icon: Icons.qr_code_scanner,
                        label: 'Scan hub QR',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hubMacController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Hub MAC address',
                          prefixIcon: Icon(Icons.router_outlined),
                        ),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        ErrorBanner(message: state.error!),
                      ],
                    ],
                  ),
                ),
                Step(
                  title: const Text('BLE'),
                  isActive: _currentStep >= 2,
                  state: setup != null ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        setup == null
                            ? 'Creating provisioning token...'
                            : 'Select the hub Bluetooth device, enter Wi-Fi details, then send credentials securely to the hub.',
                      ),
                      const SizedBox(height: 16),
                      if (setup == null)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        _BleDevicePicker(
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
                        Form(
                          key: _wifiFormKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _ssidController,
                                decoration: const InputDecoration(
                                  labelText: 'Wi-Fi SSID',
                                  prefixIcon: Icon(Icons.wifi),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'SSID is required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Wi-Fi password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Password is required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (setup != null) ...[
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _provisioningSent
                              ? const _BleProvisioningSuccessBanner(
                                  message:
                                      'Provisioning sent. The hub will connect to Wi-Fi and register with the backend.',
                                )
                              : Text(
                                  'Setup code valid until ${_formatExpiry(setup.expiresAt)}',
                                  key: const ValueKey('expires'),
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

  Future<void> _startBleScan() async {
    final allowed = await BlePermissionService.requestScanAndConnect();
    if (!allowed) {
      if (mounted) AppToast.show(context, 'Bluetooth permission is required');
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (mounted) AppToast.show(context, 'Turn on Bluetooth to scan hubs');
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
    final name = _deviceName(result);
    return name.isNotEmpty || result.advertisementData.serviceUuids.isNotEmpty;
  }

  Future<void> _sendProvisioningPayload(SetupSession? setup) async {
    if (setup == null) return;
    if (_selectedBleDevice == null) {
      AppToast.show(context, 'Select a Bluetooth hub first');
      return;
    }
    if (!_wifiFormKey.currentState!.validate()) return;

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
      final characteristics = _findHubProvisioningCharacteristics(services);
      if (characteristics == null) {
        throw StateError('Hub provisioning characteristics not found');
      }

      await device
          .requestMtu(185, predelay: 0.5, timeout: 8)
          .catchError((_) => 23);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await BleProvisioningWriter.writeText(
        characteristics.ssid,
        _ssidController.text.trim(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await BleProvisioningWriter.writeText(
        characteristics.password,
        _passwordController.text,
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await BleProvisioningWriter.writeText(
        characteristics.token,
        setup.provisioningToken,
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;
      setState(() => _provisioningSent = true);
      AppToast.show(context, 'Wi-Fi credentials sent to hub');
    } catch (error) {
      if (mounted) AppToast.show(context, 'BLE provisioning failed: $error');
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
      if (mounted) setState(() => _isProvisioningBle = false);
    }
  }

  _HubProvisioningCharacteristics? _findHubProvisioningCharacteristics(
    List<BluetoothService> services,
  ) {
    for (final service in services) {
      if (!_uuidMatches(
        service.serviceUuid.str128,
        _hubProvisioningServiceUuid,
      )) {
        continue;
      }

      BluetoothCharacteristic? ssid;
      BluetoothCharacteristic? password;
      BluetoothCharacteristic? token;
      for (final characteristic in service.characteristics) {
        final uuid = characteristic.characteristicUuid.str128;
        if (!_canWrite(characteristic)) continue;
        if (_uuidMatches(uuid, _hubSsidCharacteristicUuid)) {
          ssid = characteristic;
        } else if (_uuidMatches(uuid, _hubPasswordCharacteristicUuid)) {
          password = characteristic;
        } else if (_uuidMatches(uuid, _hubTokenCharacteristicUuid)) {
          token = characteristic;
        }
      }

      if (ssid != null && password != null && token != null) {
        return _HubProvisioningCharacteristics(
          ssid: ssid,
          password: password,
          token: token,
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

class _HubProvisioningCharacteristics {
  const _HubProvisioningCharacteristics({
    required this.ssid,
    required this.password,
    required this.token,
  });

  final BluetoothCharacteristic ssid;
  final BluetoothCharacteristic password;
  final BluetoothCharacteristic token;
}

class _BleDevicePicker extends StatelessWidget {
  const _BleDevicePicker({
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
                  'Available Bluetooth devices',
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
                    ? 'Scanning for hubs...'
                    : 'No Bluetooth devices found. Put the hub in pairing mode and scan again.',
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
                        const Icon(Icons.settings_remote_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deviceName(result),
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

class _BleProvisioningSuccessBanner extends StatelessWidget {
  const _BleProvisioningSuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('provisioning-success'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3D2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2ED47A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF7DDE9E)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _deviceName(ScanResult result) {
  final advertisedName = result.advertisementData.advName.trim();
  if (advertisedName.isNotEmpty) return advertisedName;

  final platformName = result.device.platformName.trim();
  if (platformName.isNotEmpty) return platformName;

  return 'Unknown device';
}

String _formatExpiry(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class HubQrScannerPage extends StatefulWidget {
  const HubQrScannerPage({super.key});

  @override
  State<HubQrScannerPage> createState() => _HubQrScannerPageState();
}

class _HubQrScannerPageState extends State<HubQrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Hub QR')),
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
                'Point the camera at the hub QR code',
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

class HubQrPayload {
  const HubQrPayload({required this.macAddress});

  final String macAddress;

  static HubQrPayload parse(String raw) {
    final trimmed = raw.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return HubQrPayload(
          macAddress:
              (decoded['hubMacAddress'] ??
                      decoded['macAddress'] ??
                      decoded['mac'] ??
                      '')
                  .toString()
                  .trim(),
        );
      }
    } catch (_) {}

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.isNotEmpty) {
      return HubQrPayload(
        macAddress:
            (uri.queryParameters['hubMacAddress'] ??
                    uri.queryParameters['macAddress'] ??
                    uri.queryParameters['mac'] ??
                    '')
                .trim(),
      );
    }

    return HubQrPayload(macAddress: trimmed);
  }
}
