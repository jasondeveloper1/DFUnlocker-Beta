enum LicenseStatus {
  valid,
  malformed,
}

class LicenseService {
  LicenseService._();

  static const maxKeyLength = 64;
  static const minKeyLength = 8;

  static String normalize(String key) {
    return key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static LicenseStatus verify(String key) {
    final normalized = normalize(key);
    if (normalized.isEmpty || normalized.length > maxKeyLength) {
      return LicenseStatus.malformed;
    }
    if (normalized.length < minKeyLength) {
      return LicenseStatus.malformed;
    }
    return LicenseStatus.valid;
  }

  static bool validate(String key) => verify(key) == LicenseStatus.valid;
}
