import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'grocery_data.dart';
import 'nav_bar.dart';

class CompareStoresPage extends StatefulWidget {
  const CompareStoresPage({super.key});

  @override
  State<CompareStoresPage> createState() => _CompareStoresPageState();
}

class _CompareStoresPageState extends State<CompareStoresPage> {
  static const String _prefsKey = 'shopping_list';

  late Future<List<_StoreComparisonResult>> _comparisonFuture;

  @override
  void initState() {
    super.initState();
    _comparisonFuture = _buildComparison();
  }

  Future<List<_StoreComparisonResult>> _buildComparison() async {
    final data = await GroceryDataLoader.load();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

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

    final List<_StoreComparisonResult> results = <_StoreComparisonResult>[];

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

      results.add(_StoreComparisonResult(
        storeName: storeName,
        total: total,
        items: items,
      ));
    }

    results.removeWhere((r) => r.items.isEmpty);
    results.sort((a, b) => a.total.compareTo(b.total));

    if (results.isEmpty) {
      return results;
    }

    double maxTotal = results.first.total;
    for (final r in results) {
      if (r.total > maxTotal) {
        maxTotal = r.total;
      }
    }

    for (final r in results) {
      final double saving = maxTotal - r.total;
      r.saving = saving > 0 ? saving : 0;
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Stores'),
      ),
      body: FutureBuilder<List<_StoreComparisonResult>>(
        future: _comparisonFuture,
        builder: (BuildContext context,
            AsyncSnapshot<List<_StoreComparisonResult>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading comparison: ${snapshot.error}'),
            );
          }

          final results = snapshot.data ?? <_StoreComparisonResult>[];
          if (results.isEmpty) {
            return const Center(
              child: Text('No items in your list to compare.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: results.length,
            itemBuilder: (BuildContext context, int index) {
              final result = results[index];
              final bool isCheapest = index == 0;
              return _StoreCard(
                result: result,
                isCheapest: isCheapest,
              );
            },
          );
        },
      ),
    );
  }
}

class _StoreComparisonResult {
  _StoreComparisonResult({
    required this.storeName,
    required this.total,
    required this.items,
  });

  final String storeName;
  final double total;
  final List<_StoreLineItem> items;
  double saving = 0;
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

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.result,
    required this.isCheapest,
  });

  final _StoreComparisonResult result;
  final bool isCheapest;

  String get _formattedTotal => result.total.toStringAsFixed(2);

  String get _formattedSaving => result.saving.toStringAsFixed(2);

  String _storeUrl() {
    final name = result.storeName.toLowerCase();
    if (name.contains('shoprite')) {
      return 'https://www.shoprite.co.za';
    }
    if (name.contains('pick n pay') || name.contains('pick n')) {
      return 'https://www.pnp.co.za';
    }
    return '';
  }

  Future<void> _openStoreSite() async {
    final url = _storeUrl();
    if (url.isEmpty) {
      return;
    }
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareList() async {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Shopping list for ${result.storeName}:');
    buffer.writeln('Total: R $_formattedTotal');
    buffer.writeln('');
    for (final item in result.items) {
      buffer.writeln(
        '${item.product.name} x${item.quantity} - R ${item.lineTotal.toStringAsFixed(2)}',
      );
    }
    buffer.writeln('');
    buffer.writeln('Shared from EazySave');

    await Share.share(
      buffer.toString(),
      subject: 'EazySave shopping list for ${result.storeName}',
    );
  }

  Future<void> _onSavePressed(BuildContext context) async {
    final TextEditingController controller = TextEditingController(
      text: '${result.storeName} list',
    );

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Save list'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'List name',
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? existing = prefs.getString('saved_lists');
    List<dynamic> saved = <dynamic>[];
    if (existing != null && existing.isNotEmpty) {
      final dynamic decoded = jsonDecode(existing);
      if (decoded is List<dynamic>) {
        saved = decoded;
      }
    }

    final Map<String, int> itemQuantities = <String, int>{};
    for (final _StoreLineItem item in result.items) {
      itemQuantities[item.product.id] = item.quantity;
    }

    final DateTime now = DateTime.now();
    final Map<String, dynamic> entry = <String, dynamic>{
      'id': now.millisecondsSinceEpoch.toString(),
      'name': name,
      'storeName': result.storeName,
      'total': result.total,
      'createdAt': now.toIso8601String(),
      'items': itemQuantities,
    };

    saved.add(entry);
    await prefs.setString('saved_lists', jsonEncode(saved));

    // Remember this as the current list name for the Home page.
    await prefs.setString('current_list_name', name);

    await prefs.setBool('has_completed_initial_list', true);

    // Navigate to Home tab and clear the stack so Home becomes the new root.
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const NavBar(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isCheapest
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surface;

    final Color textColor = isCheapest
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: cardColor,
      child: ExpansionTile(
        initiallyExpanded: isCheapest,
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            result.storeName[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          result.storeName,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Total: R $_formattedTotal',
              style: TextStyle(color: textColor),
            ),
            if (result.saving > 0)
              Text(
                'Save R $_formattedSaving vs other store',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
              )
            else
              Text(
                'No saving compared to the other store',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        children: <Widget>[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: <Widget>[
                ...result.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${item.product.name} x${item.quantity}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'R ${item.lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _onSavePressed(context),
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _openStoreSite,
                        child: const Text('Open store site'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _shareList,
                        child: const Text('Share list'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
