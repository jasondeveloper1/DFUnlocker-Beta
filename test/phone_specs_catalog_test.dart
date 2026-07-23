import 'package:flutter_test/flutter_test.dart';
import 'package:dfu_unlocker/data/phone_specs_catalog.dart';
import 'package:dfu_unlocker/models/device_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('findByDevice matches Galaxy S23 from offline cache', () async {
    final catalog = await PhoneSpecsCatalog.load();
    final device = DeviceInfo(
      model: 'Galaxy S23',
      manufacturer: 'Samsung',
      serial: 'TEST',
      connectionType: 'USB-C',
      osVersion: 'Android 13',
    );

    final match = PhoneSpecsCatalog.findByDevice(device, catalog);
    expect(match, isNotNull);
    expect(match!.model, 'Galaxy S23');
    expect(match.resolvedImageUrl, isNotNull);
    expect(match.highlightSpecs, isNotEmpty);
  });
}
