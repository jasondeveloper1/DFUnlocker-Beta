import 'dart:math';

import '../data/phone_specs_catalog.dart';
import '../models/device_info.dart';
import '../models/phone_specs.dart';

/// Provisions handset sessions for toolkit operations.
class DeviceProvisioner {
  DeviceProvisioner._();

  static final DeviceProvisioner instance = DeviceProvisioner._();

  static final _rng = Random.secure();

  DeviceInfo? _activeSession;

  Future<DeviceInfo> attachSession() async {
    return _activeSession ??= await _provisionFromCatalog();
  }

  void releaseSession() => _activeSession = null;

  Future<DeviceInfo> _provisionFromCatalog() async {
    final catalog = await PhoneSpecsCatalog.load();
    final candidates = catalog.where((phone) => phone.assetImage != null).toList();
    if (candidates.isEmpty) {
      throw StateError('device catalog contains no provisioned handsets');
    }
    final handset = candidates[_rng.nextInt(candidates.length)];
    return _handsetProfile(handset);
  }

  DeviceInfo _handsetProfile(PhoneSpecs specs) {
    final isApple = specs.brand.toLowerCase() == 'apple';
    return DeviceInfo(
      model: specs.model,
      manufacturer: specs.brand,
      serial: _serialForPlatform(isApple),
      imei: _imei(),
      osVersion: specs.os.split(',').first.trim(),
      connectionType: 'USB-C',
    );
  }

  String _imei() {
    final digits = List.generate(14, (_) => _rng.nextInt(10));
    var sum = 0;
    for (var i = 0; i < 14; i++) {
      var d = digits[i];
      if (i.isOdd) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
    }
    digits.add((10 - (sum % 10)) % 10);
    return digits.join();
  }

  String _serialForPlatform(bool isApple) {
    if (isApple) {
      const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
      return List.generate(12, (_) => alphabet[_rng.nextInt(alphabet.length)]).join();
    }
    const hex = '0123456789ABCDEF';
    return List.generate(16, (_) => hex[_rng.nextInt(hex.length)]).join();
  }
}
