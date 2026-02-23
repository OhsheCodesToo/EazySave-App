import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'grocery_data.dart';
import 'scroll_route.dart';
import 'create_list_page.dart';
import 'province_dropdown.dart';

class ViewListPage extends StatefulWidget {
  const ViewListPage({super.key});

  @override
  State<ViewListPage> createState() => _ViewListPageState();
}

class _ViewListPageState extends State<ViewListPage> {
  static const String _prefsKey = 'shopping_list';

  late Future<_HomeData> _homeFuture;
  int _selectedStoreIndex = 0;
  bool _hasInitializedSelection = false;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
  }

  Future<_HomeData> _loadHomeData() async {
    final data = await GroceryDataLoader.load();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final String listName = prefs.getString('current_list_name') ?? '';

    final Map<String, int> quantities = <String, int>{};
    bool hasChanges = false;
    final Set<String> validProductIds =
        data.products.map((p) => p.id).where((id) => id.isNotEmpty).toSet();

    if (raw != null && raw.isNotEmpty) {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((productId, quantityValue) {
        final int? quantity =
            quantityValue is int ? quantityValue : int.tryParse(quantityValue.toString());
        if (quantity == null || quantity <= 0) {
          hasChanges = true;
          return;
        }
        if (!validProductIds.contains(productId)) {
          hasChanges = true;
          return;
        }
        quantities[productId] = quantity;
      });
    }

    if (quantities.isEmpty) {
      hasChanges = true;
      for (final product in data.products) {
        if (product.essential) {
          quantities[product.id] = 1;
        }
      }
    }

    if (hasChanges) {
      await prefs.setString(_prefsKey, jsonEncode(quantities));
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

  Future<void> _openCreateList() async {
    await Navigator.of(context).push(
      buildScrollRoute<void>(
        const CreateListPage(showBackground: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBackground = Color(0xFFF5F5F5);
    const Color primaryTeal = Color(0xFF315762);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryTeal,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: primaryTeal.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: SizedBox(
                height: 34,
                child: Center(
                  child: ProvinceDropdown(
                    foregroundColor: primaryTeal,
                    dropdownColor: pageBackground,
                  ),
                ),
              ),
            ),
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                Navigator.of(context)
                    .popUntil((Route<dynamic> route) => route.isFirst);
              },
            ),
          ),
        ),
        title: const Text('View list'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: FutureBuilder<_HomeData>(
            future: _homeFuture,
            builder: (BuildContext context, AsyncSnapshot<_HomeData> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading home data: ${snapshot.error}'),
                );
              }

              final homeData = snapshot.data;
              if (homeData == null || homeData.stores.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('No recent list available.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _openCreateList,
                        child: const Text('Create your first list'),
                      ),
                    ],
                  ),
                );
              }

              if (!_hasInitializedSelection) {
                _hasInitializedSelection = true;
                _selectedStoreIndex = homeData.cheapestIndex;
              }

              final _StoreView selectedStore = homeData.stores[_selectedStoreIndex];

              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: <BoxShadow>[
                          // Ambient glow
                          BoxShadow(
                            color: primaryTeal.withValues(alpha: 0.16),
                            blurRadius: 36,
                            offset: const Offset(0, 0),
                          ),
                          // Deep drop
                          BoxShadow(
                            color: primaryTeal.withValues(alpha: 0.30),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                          // Tight accent
                          BoxShadow(
                            color: primaryTeal.withValues(alpha: 0.20),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      primaryTeal,
                                      const Color(0xFF212F45),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        blurRadius: 18,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: <Widget>[
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.06),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withValues(alpha: 0.46),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(1),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.22),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.center,
                                              colors: <Color>[
                                                Colors.white
                                                    .withValues(alpha: 0.24),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.center,
                                              colors: <Color>[
                                                Colors.white
                                                    .withValues(alpha: 0.14),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomRight,
                                              end: Alignment.center,
                                              colors: <Color>[
                                                Colors.black
                                                    .withValues(alpha: 0.14),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Last list overview',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (homeData.data.lastUpdated.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Prices last updated ${homeData.data.lastUpdated}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.92),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  // Store pills that fill width and toggle
                                  Row(
                                    children: List<Widget>.generate(
                                      homeData.stores.length,
                                      (int index) {
                                        final view = homeData.stores[index];
                                        final bool selected =
                                            index == _selectedStoreIndex;
                                        return Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: index < homeData.stores.length - 1
                                                  ? 4
                                                  : 0,
                                            ),
                                            child: ChoiceChip(
                                              label: Text(
                                                view.storeName,
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              selected: selected,
                                              onSelected: (_) {
                                                setState(() {
                                                  _selectedStoreIndex = index;
                                                });
                                              },
                                              backgroundColor:
                                                  Colors.white.withValues(alpha: 0.22),
                                              selectedColor:
                                                  Colors.white.withValues(alpha: 0.36),
                                              labelStyle:
                                                  theme.textTheme.bodyMedium?.copyWith(
                                                color: primaryTeal,
                                                fontWeight: selected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                              ),
                                              side: BorderSide(
                                                color: Colors.white.withValues(alpha: 0.35),
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: pageBackground,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: selectedStore.items.length + 2,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (BuildContext context, int index) {
                              if (index == 0) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      homeData.listName.isNotEmpty
                                          ? homeData.listName
                                          : 'Till slip - ${selectedStore.storeName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: <Widget>[
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            'QTY',
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'ITEM',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 84,
                                          child: Text(
                                            'AMOUNT',
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }
                              if (index == selectedStore.items.length + 1) {
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const SizedBox(width: 40),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'TOTAL',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 84,
                                      child: Text(
                                        'R ${selectedStore.formattedTotal}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              final _StoreLineItem item =
                                  selectedStore.items[index - 1];
                              final String unit = item.product.unit.trim();
                              final String quantityLabel =
                                  item.quantity.toString();
                              final String nameLabel = unit.isEmpty
                                  ? item.product.name
                                  : '${item.product.name} $unit';

                              return Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      quantityLabel,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      nameLabel,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 84,
                                    child: Text(
                                      'R ${item.lineTotal.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _openCreateList,
                        child: Text(
                          'Edit list',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
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
