/// Device specification record for the offline handset catalog.
class PhoneSpecs {
  const PhoneSpecs({
    required this.slug,
    required this.brand,
    required this.model,
    required this.releaseDate,
    required this.dimensions,
    required this.os,
    required this.storage,
    required this.specifications,
    this.imageUrl,
    this.assetImage,
    this.scrapedAt,
  });

  final String slug;
  final String brand;
  final String model;
  final String? imageUrl;
  final String? assetImage;
  final String releaseDate;
  final String dimensions;
  final String os;
  final String storage;
  final Map<String, Map<String, String>> specifications;
  final DateTime? scrapedAt;

  String get displayName {
    final full = '$brand $model'.trim();
    return full.isEmpty ? model : full;
  }

  /// Resolves relative image paths against the catalog CDN origin.
  String? get resolvedImageUrl {
    final url = imageUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return 'https://www.gsmarena.com/$url';
  }

  /// Key specs for the homescreen summary panel.
  List<MapEntry<String, String>> get highlightSpecs {
    final items = <MapEntry<String, String>>[];
    void add(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        items.add(MapEntry(label, value.trim()));
      }
    }

    add('Released', releaseDate);
    add('Body', dimensions);
    add('OS', os);
    add('Storage', storage);
    add('Chipset', _specValue('Platform', 'Chipset'));
    add('Display', _specValue('Display', 'Type'));
    add('Battery', _specValue('Battery', 'Type'));
    add('Camera', _firstSpecValue('Main Camera', const ['Triple', 'Quad', 'Dual', 'Single']));
    return items;
  }

  String? _specValue(String category, String key) =>
      specifications[category]?[key];

  String? _firstSpecValue(String category, List<String> keys) {
    final cat = specifications[category];
    if (cat == null) return null;
    for (final key in keys) {
      final value = cat[key];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  factory PhoneSpecs.fromJson(Map<String, dynamic> json) {
    final rawSpecs = json['specifications'];
    final specs = <String, Map<String, String>>{};
    if (rawSpecs is Map) {
      for (final entry in rawSpecs.entries) {
        final category = <String, String>{};
        final value = entry.value;
        if (value is Map) {
          for (final spec in value.entries) {
            category['${spec.key}'] = '${spec.value}';
          }
        }
        specs['${entry.key}'] = category;
      }
    }

    return PhoneSpecs(
      slug: json['slug'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      assetImage: json['assetImage'] as String?,
      releaseDate: json['release_date'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      os: json['os'] as String? ?? '',
      storage: json['storage'] as String? ?? '',
      specifications: specs,
      scrapedAt: json['scraped_at'] != null
          ? DateTime.tryParse(json['scraped_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'brand': brand,
        'model': model,
        'imageUrl': imageUrl,
        if (assetImage != null) 'assetImage': assetImage,
        'release_date': releaseDate,
        'dimensions': dimensions,
        'os': os,
        'storage': storage,
        'specifications': specifications,
        if (scrapedAt != null) 'scraped_at': scrapedAt!.toIso8601String(),
      };
}
