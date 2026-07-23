import 'dart:async';
import 'dart:io';

import '../core/device_link_strategy.dart';
import '../core/runtime_config.dart';
import '../services/device_provisioner.dart';
import '../models/device_info.dart';

/// Read-only USB detection. Does not modify the connected device.
class UsbDeviceDetector {
  UsbDeviceDetector._();

  static final UsbDeviceDetector instance = UsbDeviceDetector._();

  static final _phoneNamePattern = RegExp(
    r'iPhone|iPad|iPod|Android|Galaxy|Pixel|OnePlus|Xiaomi|Redmi|'
    r'MTP|ADB Interface|Composite|Mobile|Phone|HUAWEI|HONOR|OPPO|vivo|realme',
    caseSensitive: false,
  );

  static final _ignoredNamePattern = RegExp(
    r'Billboard|Touch Bar|FaceTime|Camera|T2 Controller|Bluetooth|Keyboard|'
    r'Receiver|Trackpad|Ambient|Headset|Hub|Card Reader|Mass Storage',
    caseSensitive: false,
  );

  /// Poll every [interval] for a connected phone/tablet.
  Stream<DeviceInfo?> watchDevice({Duration? interval}) async* {
    final poll = interval ?? RuntimeConfig.devicePollInterval;

    if (RuntimeConfig.deviceLink == DeviceLinkStrategy.session) {
      yield await DeviceProvisioner.instance.attachSession();
      yield* Stream.periodic(poll, (_) => null)
          .asyncMap((_) => DeviceProvisioner.instance.attachSession());
      return;
    }

    yield await detectDevice();
    yield* Stream.periodic(poll, (_) => null).asyncMap((_) => detectDevice());
  }

  Future<DeviceInfo?> detectDevice() async {
    if (RuntimeConfig.deviceLink == DeviceLinkStrategy.session) {
      return DeviceProvisioner.instance.attachSession();
    }

    if (Platform.isMacOS) {
      return _detectMacOS();
    }
    if (Platform.isWindows) {
      return _detectWindows();
    }
    return null;
  }

  Future<DeviceInfo?> _detectMacOS() async {
    final fromIdevice = await _tryLibimobiledevice();
    if (fromIdevice != null) return fromIdevice;

    final fromAdb = await _tryAdb();
    if (fromAdb != null) return fromAdb;

    return _parseMacOsIoreg();
  }

  Future<DeviceInfo?> _detectWindows() async {
    final fromAdb = await _tryAdb();
    if (fromAdb != null) return fromAdb;

    return _detectWindowsPnP();
  }

  Future<DeviceInfo?> _tryLibimobiledevice() async {
    final idResult = await _run('idevice_id', ['-l']);
    if (idResult == null || idResult.stdout.trim().isEmpty) return null;

    final udid = idResult.stdout.trim().split('\n').first.trim();
    if (udid.isEmpty) return null;

    final info = await _run('ideviceinfo', ['-u', udid]);
    if (info == null) return null;

    final map = _parseKeyValueOutput(info.stdout);
    final productType = map['ProductType'] ?? 'iPhone';
    final model = _mapAppleProductType(productType) ?? map['DeviceName'] ?? productType;
    final imei = map['InternationalMobileEquipmentIdentity'];
    final serial = map['SerialNumber'] ?? udid;
    final os = map['ProductVersion'];

    return DeviceInfo(
      model: model,
      manufacturer: 'Apple',
      serial: serial,
      imei: imei?.isNotEmpty == true ? imei : null,
      osVersion: os != null ? 'iOS $os' : null,
      connectionType: 'USB',
    );
  }

  Future<DeviceInfo?> _tryAdb() async {
    final devicesResult = await _run('adb', ['devices']);
    if (devicesResult == null) return null;

    final lines = devicesResult.stdout
        .split('\n')
        .where((l) => l.contains('\tdevice'))
        .map((l) => l.split('\t').first.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (lines.isEmpty) return null;

    final serial = lines.first;
    final model = await _adbProp('ro.product.model') ?? 'Android device';
    final manufacturer = await _adbProp('ro.product.manufacturer') ?? 'Unknown';
    final androidVersion = await _adbProp('ro.build.version.release');
    final imei = await _tryAdbImei();

    return DeviceInfo(
      model: model,
      manufacturer: _capitalize(manufacturer),
      serial: serial,
      imei: imei,
      osVersion: androidVersion != null ? 'Android $androidVersion' : null,
      connectionType: 'USB (ADB)',
    );
  }

  Future<String?> _adbProp(String key) async {
    final result = await _run('adb', ['shell', 'getprop', key]);
    if (result == null) return null;
    final value = result.stdout.trim();
    return value.isEmpty ? null : value;
  }

  Future<String?> _tryAdbImei() async {
    final result = await _run('adb', ['shell', 'service', 'call', 'iphonesubinfo', '1']);
    if (result == null || result.exitCode != 0) return null;
    final match = RegExp(r"'([0-9]+)'").allMatches(result.stdout).map((m) => m.group(1)).join();
    if (match.length >= 14 && match.length <= 16) return match;
    return null;
  }

  Future<DeviceInfo?> _parseMacOsIoreg() async {
    final result = await _run('ioreg', ['-p', 'IOUSB', '-l', '-w', '0']);
    if (result == null) return null;

    final entries = _splitIoregEntries(result.stdout);
    DeviceInfo? best;

    for (final entry in entries) {
      final device = _parseIoregEntry(entry);
      if (device == null) continue;
      best = device;
      if (device.model.toLowerCase().contains('iphone') ||
          device.model.toLowerCase().contains('ipad')) {
        break;
      }
    }

    return best;
  }

  DeviceInfo? _parseIoregEntry(String entry) {
    final productName = _ioregValue(entry, 'USB Product Name') ??
        _ioregValue(entry, 'kUSBProductString');
    if (productName == null || _ignoredNamePattern.hasMatch(productName)) return null;
    if (!_phoneNamePattern.hasMatch(productName)) return null;

    final serial = _ioregValue(entry, 'USB Serial Number') ??
        _ioregValue(entry, 'kUSBSerialNumberString') ??
        'Unknown';
    if (serial == '0000000000000000' || serial == '0000000000000001') return null;

    final vendorId = int.tryParse(_ioregValue(entry, 'idVendor') ?? '');
    final productId = int.tryParse(_ioregValue(entry, 'idProduct') ?? '');
    final vendorString = _ioregValue(entry, 'kUSBVendorString');

    final manufacturer = vendorId == 1452 || (vendorString?.contains('Apple') ?? false)
        ? 'Apple'
        : (vendorString?.isNotEmpty == true ? vendorString! : _vendorName(vendorId));
    final model = productName == 'iPhone' || productName == 'iPad'
        ? _mapAppleProductId(productId) ?? productName
        : productName;

    return DeviceInfo(
      model: model,
      manufacturer: manufacturer,
      serial: serial,
      connectionType: 'USB',
      osVersion: productName.contains('iPhone') || productName.contains('iPad')
          ? 'iOS (trust device for more details)'
          : null,
    );
  }

  Future<DeviceInfo?> _detectWindowsPnP() async {
    final script = r'''
Get-CimInstance Win32_PnPEntity |
  Where-Object { $_.Name -match 'iPhone|iPad|iPod|Android|ADB|MTP|Samsung|Pixel|Galaxy|OnePlus|Xiaomi|Mobile' } |
  Select-Object -First 1 Name, DeviceID |
  ConvertTo-Json -Compress
''';
    final result = await _run('powershell', ['-NoProfile', '-Command', script]);
    if (result == null || result.stdout.trim().isEmpty) return null;

    final raw = result.stdout.trim();
    if (raw == '' || raw == 'null') return null;

    final nameMatch = RegExp(r'"Name"\s*:\s*"([^"]+)"').firstMatch(raw);
    final idMatch = RegExp(r'"DeviceID"\s*:\s*"([^"]+)"').firstMatch(raw);
    if (nameMatch == null) return null;

    final name = nameMatch.group(1)!;
    final deviceId = idMatch?.group(1) ?? 'Unknown';

    final isApple = name.contains('iPhone') || name.contains('iPad') || name.contains('Apple');
    return DeviceInfo(
      model: name,
      manufacturer: isApple ? 'Apple' : 'Android',
      serial: _extractWindowsSerial(deviceId),
      connectionType: 'USB',
    );
  }

  String _extractWindowsSerial(String deviceId) {
    final parts = deviceId.split('\\');
    return parts.length > 1 ? parts.last : deviceId;
  }

  List<String> _splitIoregEntries(String output) {
    final lines = output.split('\n');
    final entries = <String>[];
    var buffer = <String>[];

    for (final line in lines) {
      if (line.contains('+-o ') && buffer.isNotEmpty) {
        entries.add(buffer.join('\n'));
        buffer = [line];
      } else {
        buffer.add(line);
      }
    }
    if (buffer.isNotEmpty) entries.add(buffer.join('\n'));
    return entries;
  }

  String? _ioregValue(String entry, String key) {
    final match = RegExp('"$key" = "([^"]*)"').firstMatch(entry);
    return match?.group(1);
  }

  Map<String, String> _parseKeyValueOutput(String output) {
    final map = <String, String>{};
    for (final line in output.split('\n')) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim();
      final value = line.substring(idx + 1).trim();
      map[key] = value;
    }
    return map;
  }

  String? _mapAppleProductId(int? productId) {
    if (productId == null) return null;
    const map = {
      4776: 'iPhone',
      4779: 'iPhone',
      4786: 'iPhone',
      4791: 'iPhone',
      4800: 'iPhone',
    };
    return map[productId];
  }

  String? _mapAppleProductType(String productType) {
    const map = {
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,4': 'iPhone 13 mini',
      'iPhone14,5': 'iPhone 13',
      'iPhone15,2': 'iPhone 14 Pro',
      'iPhone15,3': 'iPhone 14 Pro Max',
      'iPhone15,4': 'iPhone 15',
      'iPhone15,5': 'iPhone 15 Plus',
      'iPhone16,1': 'iPhone 15 Pro',
      'iPhone16,2': 'iPhone 15 Pro Max',
    };
    return map[productType] ?? productType.replaceAll(',', ' ');
  }

  String _vendorName(int? vendorId) {
    return switch (vendorId) {
      1452 => 'Apple',
      1256 => 'Samsung',
      6353 => 'Google',
      10007 => 'OnePlus',
      4817 => 'Xiaomi',
      _ => 'Unknown',
    };
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<ProcessResult?> _run(String command, List<String> args) async {
    try {
      final result = await Process.run(command, args);
      if (result.exitCode != 0) return null;
      return result;
    } on ProcessException {
      return null;
    }
  }
}
