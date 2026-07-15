import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvisioningWriter {
  const BleProvisioningWriter._();

  static Future<void> writeText(
    BluetoothCharacteristic characteristic,
    String value,
  ) async {
    final bytes = utf8.encode(value);
    final preferWithoutResponse =
        !characteristic.properties.write &&
        characteristic.properties.writeWithoutResponse;

    try {
      await _writeWhole(
        characteristic,
        bytes,
        withoutResponse: preferWithoutResponse,
      );
    } catch (_) {
      final fallbackWithoutResponse = !preferWithoutResponse;
      if (fallbackWithoutResponse &&
          !characteristic.properties.writeWithoutResponse) {
        rethrow;
      }
      if (!fallbackWithoutResponse && !characteristic.properties.write) {
        rethrow;
      }
      await _writeWhole(
        characteristic,
        bytes,
        withoutResponse: fallbackWithoutResponse,
      );
    }
  }

  static Future<void> writeJsonObject(
    BluetoothCharacteristic characteristic,
    Map<String, String> values,
  ) async {
    final bytes = utf8.encode('${jsonEncode(values)}\n');
    final preferWithoutResponse =
        characteristic.properties.writeWithoutResponse;

    try {
      await _tryRequestMtu(characteristic.device);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await _writeWhole(
        characteristic,
        bytes,
        withoutResponse: preferWithoutResponse,
      );
    } catch (_) {
      await _writeWithFallback(characteristic, bytes, preferWithoutResponse);
    }
  }

  static Future<void> _tryRequestMtu(BluetoothDevice device) async {
    try {
      await device.requestMtu(185, predelay: 0.5, timeout: 8);
    } catch (_) {}
  }

  static Future<void> _writeWhole(
    BluetoothCharacteristic characteristic,
    List<int> bytes, {
    required bool withoutResponse,
  }) async {
    await characteristic.write(
      bytes,
      withoutResponse: withoutResponse,
      allowLongWrite: false,
      timeout: 10,
    );
  }

  static Future<void> _writeWithFallback(
    BluetoothCharacteristic characteristic,
    List<int> bytes,
    bool preferWithoutResponse,
  ) async {
    try {
      await _writeChunks(
        characteristic,
        bytes,
        withoutResponse: preferWithoutResponse,
      );
      return;
    } catch (_) {
      final fallbackWithoutResponse = !preferWithoutResponse;
      if (fallbackWithoutResponse &&
          !characteristic.properties.writeWithoutResponse) {
        rethrow;
      }
      if (!fallbackWithoutResponse && !characteristic.properties.write) {
        rethrow;
      }
      await _writeChunks(
        characteristic,
        bytes,
        withoutResponse: fallbackWithoutResponse,
      );
    }
  }

  static Future<void> _writeChunks(
    BluetoothCharacteristic characteristic,
    List<int> bytes, {
    required bool withoutResponse,
  }) async {
    const chunkSize = 20;
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = offset + chunkSize > bytes.length
          ? bytes.length
          : offset + chunkSize;
      final chunk = bytes.sublist(offset, end);
      await characteristic.write(
        chunk,
        withoutResponse: withoutResponse,
        allowLongWrite: false,
        timeout: 10,
      );
      await Future<void>.delayed(const Duration(milliseconds: 75));
    }
  }
}
