import 'package:flutter/material.dart';

import 'device_info.dart';

enum UnlockToolType {
  iCloudActivationLock,
  carrierLock,
  imeiBlacklist,
  frpRemoval,
}

extension UnlockToolTypeX on UnlockToolType {
  String get title => switch (this) {
        UnlockToolType.iCloudActivationLock => 'iCloud Activation Lock',
        UnlockToolType.carrierLock => 'Carrier Lock Removal',
        UnlockToolType.imeiBlacklist => 'IMEI Blacklist Removal',
        UnlockToolType.frpRemoval => 'FRP Removal',
      };

  String get shortTitle => switch (this) {
        UnlockToolType.iCloudActivationLock => 'iCloud Lock',
        UnlockToolType.carrierLock => 'Carrier Lock',
        UnlockToolType.imeiBlacklist => 'IMEI Blacklist',
        UnlockToolType.frpRemoval => 'FRP',
      };

  String get description => switch (this) {
        UnlockToolType.iCloudActivationLock =>
          'Remove Find My / activation lock from supported devices.',
        UnlockToolType.carrierLock =>
          'Unlock network restrictions for carrier-locked devices.',
        UnlockToolType.imeiBlacklist =>
          'Clear IMEI blacklist flags from device records.',
        UnlockToolType.frpRemoval =>
          'Bypass Factory Reset Protection on Android devices.',
      };

  IconData get icon => switch (this) {
        UnlockToolType.iCloudActivationLock => Icons.cloud_off_rounded,
        UnlockToolType.carrierLock => Icons.signal_cellular_alt_rounded,
        UnlockToolType.imeiBlacklist => Icons.shield_outlined,
        UnlockToolType.frpRemoval => Icons.lock_reset_rounded,
      };

  bool isCompatibleWith(DeviceInfo? device) {
    if (device == null) return true;

    return switch (this) {
      UnlockToolType.iCloudActivationLock => device.isApple,
      UnlockToolType.frpRemoval => device.isAndroid,
      UnlockToolType.carrierLock || UnlockToolType.imeiBlacklist => true,
    };
  }

  String? incompatibilityReason(DeviceInfo device) => switch (this) {
        UnlockToolType.iCloudActivationLock when device.isAndroid =>
          'Requires an Apple device (iPhone or iPad).',
        UnlockToolType.frpRemoval when device.isApple =>
          'Requires an Android device.',
        _ => null,
      };
}

enum UnlockFlowStep {
  connect,
  detect,
  process,
  done,
}
