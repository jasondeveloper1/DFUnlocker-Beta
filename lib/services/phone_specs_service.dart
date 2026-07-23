import '../data/phone_specs_catalog.dart';
import '../models/device_info.dart';
import '../models/phone_specs.dart';

/// Handset specification resolver backed by the bundled catalog.
class PhoneSpecsService {
  PhoneSpecsService._();

  static final PhoneSpecsService instance = PhoneSpecsService._();

  final Map<String, PhoneSpecs> _sessionCache = {};
  List<PhoneSpecs>? _catalog;

  bool get isReady => _catalog != null;

  Future<void> warmUp() async {
    _catalog ??= await PhoneSpecsCatalog.load();
  }

  /// Synchronous lookup after [warmUp].
  PhoneSpecs? resolveSync(DeviceInfo device) {
    if (_catalog == null) return null;

    final key = _cacheKey(device);
    final cached = _sessionCache[key];
    if (cached != null) return cached;

    final match = PhoneSpecsCatalog.findByDevice(device, _catalog!);
    if (match != null) _sessionCache[key] = match;
    return match;
  }

  Future<PhoneSpecs?> resolve(DeviceInfo device) async {
    await warmUp();
    return resolveSync(device);
  }

  String _cacheKey(DeviceInfo device) =>
      '${device.manufacturer}|${device.model}'.toLowerCase();
}
