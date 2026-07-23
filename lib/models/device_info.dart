class DeviceInfo {
  const DeviceInfo({
    required this.model,
    required this.manufacturer,
    required this.serial,
    required this.connectionType,
    this.imei,
    this.osVersion,
  });

  final String model;
  final String manufacturer;
  final String serial;
  final String connectionType;
  final String? imei;
  final String? osVersion;

  bool get isApple =>
      manufacturer.toLowerCase() == 'apple' ||
      model.toLowerCase().startsWith('iphone') ||
      model.toLowerCase().startsWith('ipad') ||
      model.toLowerCase().startsWith('ipod');

  bool get isAndroid => !isApple;

  String get displayIdentifier => imei ?? serial;

  String get imeiLabel => imei != null ? 'IMEI' : 'Device ID';

  bool matches(DeviceInfo other) =>
      manufacturer == other.manufacturer &&
      model == other.model &&
      serial == other.serial;
}
