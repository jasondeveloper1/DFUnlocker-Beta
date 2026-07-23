import 'device_link_strategy.dart';

/// Compile-time runtime profile for the desktop engine.
class RuntimeConfig {
  RuntimeConfig._();

  static const deviceLink = DeviceLinkStrategy.session;
  static const licenseVerificationDelay = Duration(milliseconds: 1200);
  static const devicePollInterval = Duration(seconds: 2);
  static const deviceScanDelay = Duration(milliseconds: 1500);
  static const disconnectGracePolls = 3;
}
