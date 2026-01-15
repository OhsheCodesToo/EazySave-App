import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'grocery_data.dart';

class CreateListPage extends StatefulWidget {
  const CreateListPage({super.key});

  @override
  State<CreateListPage> createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  bool _isLoading = true;
  List<GroceryCategory> _categories = <GroceryCategory>[];
  GroceryCategory? _selectedCategory;

  final Map<String, ShoppingListItem> _shoppingList = <String, ShoppingListItem>{};

  static const String _prefsKey = 'shopping_list';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await GroceryDataLoader.load();
    await _loadShoppingListFromPrefs(data);
    if (!mounted) return;
    setState(() {
      _categories = data.categories;
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      _isLoading = false;
    });
  }

  Future<void> _loadShoppingListFromPrefs(GroceryData data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
    decoded.forEach((productId, quantityValue) {
      final int? quantity = quantityValue is int
          ? quantityValue
          : int.tryParse(quantityValue.toString());
      if (quantity == null || quantity <= 0) {
        return;
      }
      final product = _findProductById(data, productId);
      if (product != null) {
        _shoppingList[productId] = ShoppingListItem(
          product: product,
          quantity: quantity,
        );
      }
    });
  }

  Future<void> _saveShoppingListToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> toSave = <String, int>{};
    _shoppingList.forEach((productId, item) {
      if (item.quantity > 0) {
        toSave[productId] = item.quantity;
      }
    });
    await prefs.setString(_prefsKey, jsonEncode(toSave));
  }

  GroceryProduct? _findProductById(GroceryData data, String id) {
    for (final category in data.categories) {
      for (final product in category.products) {
        if (product.id == id) {
          return product;
        }
      }
    }
    return null;
  }

  void _selectCategory(GroceryCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Future<void> _addProduct(GroceryProduct product) async {
    setState(() {
      final existing = _shoppingList[product.id];
      if (existing != null) {
        existing.quantity += 1;
      } else {
        _shoppingList[product.id] = ShoppingListItem(product: product, quantity: 1);
      }
    });
    await _saveShoppingListToPrefs();
  }

  Future<void> _removeProduct(GroceryProduct product) async {
    setState(() {
      final existing = _shoppingList[product.id];
      if (existing == null) {
        return;
      }
      if (existing.quantity > 1) {
        existing.quantity -= 1;
      } else {
        _shoppingList.remove(product.id);
      }
    });
    await _saveShoppingListToPrefs();
  }

  int _quantityForProduct(GroceryProduct product) {
    return _shoppingList[product.id]?.quantity ?? 0;
  }

  int get _totalItems => _shoppingList.values.fold<int>(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: <Widget>[
        _buildCategorySelector(),
        const Divider(height: 1),
        Expanded(child: _buildProductList()),
        _buildShoppingListSummary(),
      ],
    );
  }

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No categories available'),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final category = _categories[index];
          final bool isSelected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category.name),
            selected: isSelected,
            onSelected: (_) => _selectCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    final category = _selectedCategory;
    if (category == null || category.products.isEmpty) {
      return const Center(child: Text('No products available'));
    }

    return ListView.separated(
      itemCount: category.products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final product = category.products[index];
        final quantity = _quantityForProduct(product);
        final cheapest = product.cheapestPrice;

        return ListTile(
          title: Text(product.name),
          subtitle: cheapest != null
              ? Text('From ${cheapest.toStringAsFixed(2)} per ${product.unit}')
              : Text(product.unit),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: quantity > 0 ? () => _removeProduct(product) : null,
              ),
              Text(quantity.toString()),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addProduct(product),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShoppingListSummary() {
    if (_shoppingList.isEmpty) {
      return Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(12),
        child: const Text('Shopping list is empty'),
      );
    }

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Shopping list ($_totalItems items)'),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _shoppingList.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final item = _shoppingList.values.elementAt(index);
                return Chip(
                  label: Text('${item.product.name} x${item.quantity}'),
                  onDeleted: () => _removeProduct(item.product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingListItem {
  final GroceryProduct product;
  int quantity;

  ShoppingListItem({required this.product, required this.quantity});
}
