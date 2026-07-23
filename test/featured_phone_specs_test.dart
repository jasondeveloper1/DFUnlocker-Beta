import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dfu_unlocker/models/phone_specs.dart';

void main() {
  group('featured_phone_specs.json', () {
    test('contains at least 5 phones with full specification categories', () {
      final file = File('assets/data/featured_phone_specs.json');
      expect(file.existsSync(), isTrue);

      final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final rawPhones = decoded['phones'] as List<dynamic>;
      expect(rawPhones.length, greaterThanOrEqualTo(5));

      final phones = rawPhones
          .map((e) => PhoneSpecs.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      for (final phone in phones) {
        expect(phone.slug, isNotEmpty);
        expect(phone.displayName, isNotEmpty);
        expect(phone.specifications.length, greaterThanOrEqualTo(8));
        expect(phone.os, isNotEmpty);
        expect(phone.storage, isNotEmpty);
      }

      final names = phones.map((p) => p.displayName.toLowerCase()).join(' | ');
      expect(names, contains('iphone'));
      expect(names, contains('galaxy'));
      expect(names, contains('pixel'));
    });
  });
}
