import 'dart:convert';

import 'package:eazysave_app/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'compare_stores_page.dart';
import 'grocery_data.dart';

class CreateListPage extends StatefulWidget {
  const CreateListPage({super.key});

  @override
  State<CreateListPage> createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  bool _isLoading = true;

  final List<GroceryProduct> _allProducts = <GroceryProduct>[];

  final Map<String, ShoppingListItem> _shoppingList = <String, ShoppingListItem>{};

  static const String _prefsKey = 'shopping_list';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Opacity(
          opacity: 1,
          child: Image.asset(
            'assets/welcome_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Container(color: Colors.white.withValues(alpha: 0.20)),
      ],
    );
  }

  Future<void> _loadData() async {
    final data = await GroceryDataLoader.load();
    await _loadShoppingListFromPrefs(data);
    final List<GroceryProduct> allProducts = List<GroceryProduct>.from(data.products);
    if (!mounted) return;
    setState(() {
      _allProducts
        ..clear()
        ..addAll(allProducts);
      _isLoading = false;
    });
  }

  Future<void> _loadShoppingListFromPrefs(GroceryData data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      for (final product in data.products) {
        if (product.essential) {
          _shoppingList[product.id] = ShoppingListItem(
            product: product,
            quantity: 1,
          );
        }
      }
      return;
    }

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
    for (final product in data.products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
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

  Future<void> _deleteProduct(GroceryProduct product) async {
    setState(() {
      _shoppingList.remove(product.id);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildBackground(),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _buildBackground(),
        Column(
          children: <Widget>[
            Expanded(
              child: _buildProductList(),
            ),
            _buildProductSearchBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _onCompareStoresPressed,
                  child: const Text('Compare stores'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  Future<void> _onSuggestionSelected(GroceryProduct product) async {
    await _addProduct(product);
    if (!mounted) return;
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  List<GroceryProduct> _searchResults() {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return <GroceryProduct>[];
    }

    return _allProducts
        .where((product) => product.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _onCompareStoresPressed() async {
    await _saveShoppingListToPrefs();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const CompareStoresPage(),
      ),
    );
  }

  Widget _buildProductSearchBar() {
    final results = _searchResults();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search products',
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (results.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final product = results[index];
                final cheapest = product.cheapestPrice;
                return ListTile(
                  title: Text(product.name),
                  subtitle: cheapest != null
                      ? Text(
                          'From ${cheapest.toStringAsFixed(2)} per ${product.unit}',
                        )
                      : Text(product.unit),
                  onTap: () => _onSuggestionSelected(product),
                );
              },
            ),
          ),
      ],
    );
  }
 
  Widget _buildProductList() {
    final List<ShoppingListItem> items = _shoppingList.values.toList();

    if (items.isEmpty) {
      return const Center(child: Text('No products in this list'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final item = items[index];
        final product = item.product;
        final quantity = item.quantity;
        final String quantityLabel = quantity.toString();
        final cheapest = product.cheapestPrice;

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -2),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            title: Text(product.name),
            subtitle: cheapest != null
                ? Text('From ${cheapest.toStringAsFixed(2)} per ${product.unit}')
                : Text(product.unit),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      quantity > 0 ? () => _removeProduct(product) : null,
                ),
                Text(quantityLabel),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _addProduct(product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteProduct(product),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShoppingListItem {
  final GroceryProduct product;
  int quantity;

  ShoppingListItem({required this.product, required this.quantity});
}
