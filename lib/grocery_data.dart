import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroceryData {
  final List<String> stores;
  final List<GroceryCategory> categories;
  final List<GroceryProduct> products;
  final String lastUpdated;
  final Map<String, String> storeLogosByName;
  final Map<String, String> storeCatalogueUrlsByName;

  GroceryData({
    required this.stores,
    required this.categories,
    required this.products,
    required this.lastUpdated,
    required this.storeLogosByName,
    required this.storeCatalogueUrlsByName,
  });

  factory GroceryData.fromJson(Map<String, dynamic> json) {
    final metaJson = json['meta'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final categoriesJson = json['categories'] as List<dynamic>? ?? <dynamic>[];
    final productsJson = json['products'] as List<dynamic>? ?? <dynamic>[];

    final storesJson = metaJson['stores'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> storeLogosJson =
        metaJson['store_logos'] as Map<String, dynamic>? ??
            <String, dynamic>{};
    final Map<String, dynamic> storeCataloguesJson =
        metaJson['store_catalogues'] as Map<String, dynamic>? ??
            <String, dynamic>{};
    final String lastUpdated = metaJson['last_updated']?.toString() ?? '';

    final Map<String, String> storeLogosByName = <String, String>{};
    storeLogosJson.forEach((dynamic key, dynamic value) {
      if (key == null || value == null) return;
      final String name = key.toString();
      final String url = value.toString();
      if (name.isNotEmpty && url.isNotEmpty) {
        storeLogosByName[name] = url;
      }
    });

    final Map<String, String> storeCatalogueUrlsByName = <String, String>{};
    storeCataloguesJson.forEach((dynamic key, dynamic value) {
      if (key == null || value == null) return;
      final String name = key.toString();
      final String url = value.toString();
      if (name.isNotEmpty && url.isNotEmpty) {
        storeCatalogueUrlsByName[name] = url;
      }
    });

    return GroceryData(
      stores: storesJson.map((e) => e.toString()).toList(),
      categories: categoriesJson
          .map((e) => GroceryCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      products: productsJson
          .map((e) => GroceryProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: lastUpdated,
      storeLogosByName: storeLogosByName,
      storeCatalogueUrlsByName: storeCatalogueUrlsByName,
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
    try {
      final data = await _loadFromSupabase();
      debugPrint('GroceryDataLoader: Loaded data from Supabase');
      return data;
    } catch (e, _) {
      // If Supabase is unavailable (offline, misconfigured, etc.),
      // fall back to the bundled JSON so the app still works.
      debugPrint(
          'GroceryDataLoader: Supabase failed, falling back to local JSON. Error: $e');
    }

    final jsonString = await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> decoded =
        jsonDecode(jsonString) as Map<String, dynamic>;
    debugPrint('GroceryDataLoader: Loaded data from local JSON asset');
    return GroceryData.fromJson(decoded);
  }

  static Future<GroceryData> _loadFromSupabase() async {
    final client = Supabase.instance.client;

    // 1) Load stores (id + name). Logos are optional and not used for now.
    final List<dynamic> storeRows = await client
        .from('stores')
        .select('id, name, catalogue_url')
        .order('name');
    final Map<String, String> storeIdToName = <String, String>{};
    final Map<String, String> storeLogosByName = <String, String>{};
    final Map<String, String> storeCatalogueUrlsByName = <String, String>{};
    for (final dynamic rowDynamic in storeRows) {
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(rowDynamic as Map);
      final String id = row['id']?.toString() ?? '';
      final String name = row['name']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) {
        storeIdToName[id] = name;
      }

      final String catalogueUrl = row['catalogue_url']?.toString() ?? '';
      if (name.isNotEmpty && catalogueUrl.isNotEmpty) {
        storeCatalogueUrlsByName[name] = catalogueUrl;
      }
    }
    final List<String> stores = storeIdToName.values.toList();

    // 2) Load categories
    final List<dynamic> categoryRows = await client
        .from('categories')
        .select('id, name, icon')
        .order('name');
    final List<GroceryCategory> categories = categoryRows
        .map((dynamic rowDynamic) {
          final Map<String, dynamic> row =
              Map<String, dynamic>.from(rowDynamic as Map);
          return GroceryCategory(
            id: row['id']?.toString() ?? '',
            name: row['name']?.toString() ?? '',
            icon: row['icon']?.toString() ?? '',
          );
        })
        .where((c) => c.id.isNotEmpty)
        .toList();

    // 3) Load products
    final List<dynamic> productRows = await client.from('products').select('''
      id,
      name,
      brand,
      category_id,
      unit,
      is_essential
    ''');

    // 4) Load search tags
    final List<dynamic> tagRows = await client
        .from('product_search_tags')
        .select('product_id, tags');
    final Map<String, List<String>> productIdToTags = <String, List<String>>{};
    for (final dynamic rowDynamic in tagRows) {
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(rowDynamic as Map);
      final String productId = row['product_id']?.toString() ?? '';
      if (productId.isEmpty) continue;
      final dynamic tagsValue = row['tags'];
      final List<String> tags = <String>[];
      if (tagsValue is List) {
        tags.addAll(tagsValue.map((e) => e.toString()));
      } else if (tagsValue != null) {
        tags.add(tagsValue.toString());
      }
      productIdToTags.putIfAbsent(productId, () => <String>[]).addAll(tags);
    }

    // 5) Load prices
    final List<dynamic> priceRows = await client.from('product_prices').select('''
      product_id,
      store_id,
      price,
      last_updated
    ''');
    final Map<String, Map<String, double>> productIdToPrices =
        <String, Map<String, double>>{};
    DateTime? mostRecentPriceUpdate;
    for (final dynamic rowDynamic in priceRows) {
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(rowDynamic as Map);
      final String productId = row['product_id']?.toString() ?? '';
      final String storeId = row['store_id']?.toString() ?? '';
      if (productId.isEmpty || storeId.isEmpty) continue;

      final String? storeName = storeIdToName[storeId];
      if (storeName == null || storeName.isEmpty) continue;

      final dynamic priceValue = row['price'];
      final num? numericPrice = priceValue is num
          ? priceValue
          : num.tryParse(priceValue?.toString() ?? '');
      if (numericPrice == null) continue;

      productIdToPrices
          .putIfAbsent(productId, () => <String, double>{})[storeName] =
          numericPrice.toDouble();

      final dynamic lastUpdatedValue = row['last_updated'];
      if (lastUpdatedValue != null) {
        final DateTime? parsed =
            DateTime.tryParse(lastUpdatedValue.toString());
        if (parsed != null) {
          if (mostRecentPriceUpdate == null ||
              parsed.isAfter(mostRecentPriceUpdate)) {
            mostRecentPriceUpdate = parsed;
          }
        }
      }
    }

    // 6) Build GroceryProduct list
    final List<GroceryProduct> products = <GroceryProduct>[];
    for (final dynamic rowDynamic in productRows) {
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(rowDynamic as Map);
      final String productId = row['id']?.toString() ?? '';
      if (productId.isEmpty) continue;

      final List<String> searchTags =
          productIdToTags[productId] ?? <String>[];
      final Map<String, double> pricesByStore =
          productIdToPrices[productId] ?? <String, double>{};

      products.add(GroceryProduct(
        id: productId,
        name: row['name']?.toString() ?? '',
        brand: row['brand']?.toString() ?? '',
        categoryId: row['category_id']?.toString() ?? '',
        unit: row['unit']?.toString() ?? '',
        essential: (row['is_essential'] as bool?) ?? false,
        searchTags: searchTags,
        pricesByStore: pricesByStore,
      ));
    }

    final String lastUpdated =
        mostRecentPriceUpdate?.toIso8601String() ?? '';

    debugPrint(
        'GroceryDataLoader: Supabase summary -> stores: \\${stores.length}, categories: \\${categories.length}, products: \\${products.length}, lastUpdated: \\${lastUpdated.isEmpty ? 'n/a' : lastUpdated}');

    return GroceryData(
      stores: stores,
      categories: categories,
      products: products,
      lastUpdated: lastUpdated,
      storeLogosByName: storeLogosByName,
      storeCatalogueUrlsByName: storeCatalogueUrlsByName,
    );
  }
}
