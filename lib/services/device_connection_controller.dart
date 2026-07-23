import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/runtime_config.dart';
import '../models/device_info.dart';
import 'usb_device_detector.dart';

class DeviceConnectionController extends ChangeNotifier {
  DeviceConnectionController._();

  static final DeviceConnectionController instance = DeviceConnectionController._();

  StreamSubscription<DeviceInfo?>? _subscription;
  DeviceInfo? _currentDevice;
  int _consecutiveNullPolls = 0;

  DeviceInfo? get currentDevice => _currentDevice;

  bool get isWatching => _subscription != null;

  void start() {
    if (_subscription != null) return;

    _subscription = UsbDeviceDetector.instance
        .watchDevice()
        .listen(
      _onDeviceUpdate,
      onError: (_) {},
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _onDeviceUpdate(DeviceInfo? device) {
    if (device != null) {
      _consecutiveNullPolls = 0;
      if (_currentDevice?.matches(device) ?? false) return;
      _currentDevice = device;
      notifyListeners();
      return;
    }

    _consecutiveNullPolls++;
    if (_currentDevice == null ||
        _consecutiveNullPolls < RuntimeConfig.disconnectGracePolls) {
      return;
    }

    _currentDevice = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
