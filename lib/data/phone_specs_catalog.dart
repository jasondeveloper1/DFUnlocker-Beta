import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/device_info.dart';
import '../models/phone_specs.dart';

/// Offline handset specification catalog.
class PhoneSpecsCatalog {
  PhoneSpecsCatalog._();

  static const assetPath = 'assets/data/featured_phone_specs.json';

  static List<PhoneSpecs>? _cache;
  static Map<String, PhoneSpecs>? _index;

  static Future<List<PhoneSpecs>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('phone specs asset must be an object');
    }
    final list = decoded['phones'];
    if (list is! List) {
      throw const FormatException('phone specs asset missing phones[]');
    }
    _cache = list
        .whereType<Map>()
        .map((e) => PhoneSpecs.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    _index = _buildIndex(_cache!);
    return _cache!;
  }

  static Map<String, PhoneSpecs> _buildIndex(List<PhoneSpecs> catalog) {
    final index = <String, PhoneSpecs>{};
    for (final phone in catalog) {
      for (final key in _lookupKeys(phone)) {
        index.putIfAbsent(key, () => phone);
      }
    }
    return index;
  }

  static Iterable<String> _lookupKeys(PhoneSpecs phone) sync* {
    yield _normalize(phone.model);
    yield _normalize(phone.displayName);
    yield _normalize('${phone.brand} ${phone.model}');
  }

  static PhoneSpecs? findByDevice(DeviceInfo device, List<PhoneSpecs> catalog) {
    final model = _normalize(device.model);
    final manufacturer = _normalize(device.manufacturer);
    final combined = _normalize('${device.manufacturer} ${device.model}');

    final index = _index;
    if (index != null) {
      return index[combined] ?? index[model];
    }

    PhoneSpecs? best;
    var bestScore = 0;
    for (final phone in catalog) {
      final score = _matchScore(
        model: model,
        manufacturer: manufacturer,
        combined: combined,
        phone: phone,
      );
      if (score > bestScore) {
        bestScore = score;
        best = phone;
      }
    }
    return bestScore >= 60 ? best : null;
  }

  static int _matchScore({
    required String model,
    required String manufacturer,
    required String combined,
    required PhoneSpecs phone,
  }) {
    final phoneModel = _normalize(phone.model);
    final phoneBrand = _normalize(phone.brand);
    final phoneName = _normalize(phone.displayName);

    if (model == phoneModel || combined == phoneName) return 100;
    if (phoneName.contains(model) && model.length >= 4) return 90;
    if (model.contains(phoneModel) && phoneModel.length >= 4) return 85;
    if (combined.contains(phoneModel) && phoneBrand == manufacturer) return 80;
    if (phoneName.contains(model) && phoneBrand == manufacturer) return 75;
    return 0;
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  static void clearCache() {
    _cache = null;
    _index = null;
  }
}
