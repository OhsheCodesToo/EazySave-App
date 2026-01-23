import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'grocery_data.dart';
import 'package:eazysave_app/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onEditList});

  final VoidCallback onEditList;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _prefsKey = 'shopping_list';

  late Future<_HomeData> _homeFuture;
  int _selectedStoreIndex = 0;
  bool _hasInitializedSelection = false;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
  }

  @override
  void dispose() {
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

  Future<_HomeData> _loadHomeData() async {
    final data = await GroceryDataLoader.load();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final String listName = prefs.getString('current_list_name') ?? '';

    final Map<String, int> quantities = <String, int>{};

    if (raw != null && raw.isNotEmpty) {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((productId, quantityValue) {
        final int? quantity = quantityValue is int
            ? quantityValue
            : int.tryParse(quantityValue.toString());
        if (quantity != null && quantity > 0) {
          quantities[productId] = quantity;
        }
      });
    } else {
      for (final product in data.products) {
        if (product.essential) {
          quantities[product.id] = 1;
        }
      }
    }

    final List<_StoreView> stores = <_StoreView>[];

    for (final storeName in data.stores) {
      double total = 0;
      final List<_StoreLineItem> items = <_StoreLineItem>[];

      quantities.forEach((productId, quantity) {
        GroceryProduct? product;
        for (final p in data.products) {
          if (p.id == productId) {
            product = p;
            break;
          }
        }
        if (product == null) {
          return;
        }
        final double? price = product.pricesByStore[storeName];
        if (price == null) {
          return;
        }
        final double lineTotal = price * quantity;
        total += lineTotal;
        items.add(_StoreLineItem(
          product: product,
          quantity: quantity,
          unitPrice: price,
          lineTotal: lineTotal,
        ));
      });

      if (items.isNotEmpty) {
        stores.add(_StoreView(
          storeName: storeName,
          total: total,
          items: items,
        ));
      }
    }

    if (stores.isEmpty) {
      return _HomeData(
        data: data,
        stores: stores,
        cheapestIndex: 0,
        listName: listName,
      );
    }

    stores.sort((a, b) => a.total.compareTo(b.total));
    const int cheapestIndex = 0;

    return _HomeData(
      data: data,
      stores: stores,
      cheapestIndex: cheapestIndex,
      listName: listName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _homeFuture,
      builder: (BuildContext context, AsyncSnapshot<_HomeData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _buildBackground(),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }
        if (snapshot.hasError) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _buildBackground(),
              Center(
                child: Text('Error loading home data: ${snapshot.error}'),
              ),
            ],
          );
        }

        final homeData = snapshot.data;
        if (homeData == null || homeData.stores.isEmpty) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _buildBackground(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('No recent list available.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.onEditList,
                      child: const Text('Create your first list'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (!_hasInitializedSelection) {
          _hasInitializedSelection = true;
          _selectedStoreIndex = homeData.cheapestIndex;
        }

        final _StoreView selectedStore = homeData.stores[_selectedStoreIndex];

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildBackground(),
            Column(
              children: <Widget>[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Last list overview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        List<Widget>.generate(homeData.stores.length, (int index) {
                      final view = homeData.stores[index];
                      final bool selected = index == _selectedStoreIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(view.storeName),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedStoreIndex = index;
                            });
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                if (homeData.data.lastUpdated.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Prices last updated ${homeData.data.lastUpdated}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedStore.items.length + 2,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  homeData.listName.isNotEmpty
                                      ? homeData.listName
                                      : 'Till slip - ${selectedStore.storeName}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            );
                          }
                          if (index == selectedStore.items.length + 1) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Total',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'R ${selectedStore.formattedTotal}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          }
                          final _StoreLineItem item =
                              selectedStore.items[index - 1];
                          final String unit = item.product.unit.trim();
                          final String quantityLabel = unit.isEmpty
                              ? 'x${item.quantity}'
                              : '$unit x${item.quantity}';
                          return Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${item.product.name} $quantityLabel',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('R ${item.lineTotal.toStringAsFixed(2)}'),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      ),
                      onPressed: widget.onEditList,
                      child: const Text('Edit list'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HomeData {
  _HomeData({
    required this.data,
    required this.stores,
    required this.cheapestIndex,
    required this.listName,
  });

  final GroceryData data;
  final List<_StoreView> stores;
  final int cheapestIndex;
  final String listName;
}

class _StoreView {
  _StoreView({
    required this.storeName,
    required this.total,
    required this.items,
  });

  final String storeName;
  final double total;
  final List<_StoreLineItem> items;

  int get itemCount =>
      items.fold<int>(0, (int sum, _StoreLineItem item) => sum + item.quantity);

  String get formattedTotal => total.toStringAsFixed(2);
}

class _StoreLineItem {
  _StoreLineItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final GroceryProduct product;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
}
