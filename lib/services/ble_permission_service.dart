import 'package:permission_handler/permission_handler.dart';

class BlePermissionService {
  const BlePermissionService._();

  static Future<bool> requestScanAndConnect() async {
    final bluetoothStatuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final bluetoothGranted = bluetoothStatuses.values.every(
      (status) => status.isGranted,
    );
    if (bluetoothGranted) return true;

    final locationStatus = await Permission.locationWhenInUse.request();
    return locationStatus.isGranted;
  }
}
