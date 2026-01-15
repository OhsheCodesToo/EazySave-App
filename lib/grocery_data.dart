import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class GroceryData {
  final List<String> stores;
  final List<GroceryCategory> categories;

  GroceryData({required this.stores, required this.categories});

  factory GroceryData.fromJson(Map<String, dynamic> json) {
    final storesJson = json['stores'] as List<dynamic>? ?? <dynamic>[];
    final categoriesJson = json['categories'] as List<dynamic>? ?? <dynamic>[];

    return GroceryData(
      stores: storesJson.map((e) => e.toString()).toList(),
      categories: categoriesJson
          .map((e) => GroceryCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GroceryCategory {
  final String id;
  final String name;
  final List<GroceryProduct> products;

  GroceryCategory({
    required this.id,
    required this.name,
    required this.products,
  });

  factory GroceryCategory.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'] as List<dynamic>? ?? <dynamic>[];
    return GroceryCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      products: productsJson
          .map((e) => GroceryProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GroceryProduct {
  final String id;
  final String name;
  final String unit;
  final Map<String, double> pricesByStore;

  GroceryProduct({
    required this.id,
    required this.name,
    required this.unit,
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

    return GroceryProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
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
