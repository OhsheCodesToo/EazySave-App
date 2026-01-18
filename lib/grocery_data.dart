import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class GroceryData {
  final List<String> stores;
  final List<GroceryCategory> categories;
  final List<GroceryProduct> products;
  final String lastUpdated;

  GroceryData({
    required this.stores,
    required this.categories,
    required this.products,
    required this.lastUpdated,
  });

  factory GroceryData.fromJson(Map<String, dynamic> json) {
    final metaJson = json['meta'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final categoriesJson = json['categories'] as List<dynamic>? ?? <dynamic>[];
    final productsJson = json['products'] as List<dynamic>? ?? <dynamic>[];

    final storesJson = metaJson['stores'] as List<dynamic>? ?? <dynamic>[];
    final String lastUpdated = metaJson['last_updated']?.toString() ?? '';

    return GroceryData(
      stores: storesJson.map((e) => e.toString()).toList(),
      categories: categoriesJson
          .map((e) => GroceryCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      products: productsJson
          .map((e) => GroceryProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: lastUpdated,
    );
  }
}

class GroceryCategory {
  final String id;
  final String name;
  final String icon;

  GroceryCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory GroceryCategory.fromJson(Map<String, dynamic> json) {
    return GroceryCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }
}

class GroceryProduct {
  final String id;
  final String name;
  final String brand;
  final String categoryId;
  final String unit;
  final bool essential;
  final List<String> searchTags;
  final Map<String, double> pricesByStore;

  GroceryProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.unit,
    required this.essential,
    required this.searchTags,
    required this.pricesByStore,
  });

  factory GroceryProduct.fromJson(Map<String, dynamic> json) {
    final pricesJson = json['prices'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final prices = <String, double>{};
    pricesJson.forEach((key, value) {
      final num? v = value is num ? value : num.tryParse(value.toString());
      if (v != null) {
        prices[key] = v.toDouble();
      }
    });

    final tagsJson = json['search_tags'] as List<dynamic>? ?? <dynamic>[];

    return GroceryProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      essential: (json['essential'] as bool?) ?? false,
      searchTags: tagsJson.map((e) => e.toString()).toList(),
      pricesByStore: prices,
    );
  }

  double? get cheapestPrice {
    if (pricesByStore.isEmpty) return null;
    return pricesByStore.values.reduce((a, b) => a < b ? a : b);
  }
}

class GroceryDataLoader {
  static const String _assetPath = 'assets/grocery_data.json';
  static Future<GroceryData>? _cached;

  static Future<GroceryData> load() {
    _cached ??= _loadInternal();
    return _cached!;
  }

  static Future<GroceryData> _loadInternal() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return GroceryData.fromJson(decoded);
  }
}
