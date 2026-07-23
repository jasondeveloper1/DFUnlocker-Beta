import 'package:flutter_test/flutter_test.dart';
import 'package:dfu_unlocker/services/license_service.dart';

void main() {
  group('LicenseService', () {
    test('accepts published license keys', () {
      const keys = [
        'DFU-X7M2-9KPL-4R8N',
        'UNLOCK-PRO-2026-BETA',
        'LICENSE-A8F3-2H9Q-7X1M',
        'MASTER-KEY-DFU-2025',
        'BETA-ACCESS-K9P2-7H4M',
        'DFUUNLOCK-8842-XR9K',
        'PRO-LICENSE-3F8A-2K9Q',
        'DFU-PRO-7K9M-2X4P-8N1Q',
      ];
      for (final key in keys) {
        expect(LicenseService.verify(key), LicenseStatus.valid, reason: key);
      }
    });

    test('rejects empty or incomplete input', () {
      expect(LicenseService.verify(''), LicenseStatus.malformed);
      expect(LicenseService.verify('   '), LicenseStatus.malformed);
      expect(LicenseService.verify('SHORT'), LicenseStatus.malformed);
      expect(
        LicenseService.verify('A' * (LicenseService.maxKeyLength + 1)),
        LicenseStatus.malformed,
      );
    });
  });
}
