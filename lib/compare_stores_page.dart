import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'grocery_data.dart';
import 'nav_bar.dart';
import 'province_dropdown.dart';

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
    const Color pageBackground = Color(0xFFF5F5F5);
    const Color primaryTeal = Color(0xFF315762);
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
        title: Text(
          'Compare Stores',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: pageBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: FutureBuilder<List<_StoreComparisonResult>>(
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

              final _StoreComparisonResult cheapest = results.first;
              final _StoreComparisonResult mostExpensive = results.last;
              final double bestSaving = cheapest.saving;
              final int totalItemCount = cheapest.items.fold<int>(
                0,
                (int sum, _StoreLineItem item) => sum + item.quantity,
              );

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: results.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return _ComparisonHeader(
                      cheapestStoreName: cheapest.storeName,
                      cheapestTotal: cheapest.total,
                      mostExpensiveTotal: mostExpensive.total,
                      saving: bestSaving,
                      itemCount: totalItemCount,
                    );
                  }

                  final result = results[index - 1];
                  final bool isCheapest = (index - 1) == 0;
                  return _StoreCard(
                    result: result,
                    isCheapest: isCheapest,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader({
    required this.cheapestStoreName,
    required this.cheapestTotal,
    required this.mostExpensiveTotal,
    required this.saving,
    required this.itemCount,
  });

  final String cheapestStoreName;
  final double cheapestTotal;
  final double mostExpensiveTotal;
  final double saving;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF315762),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Best deal',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$itemCount items',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cheapestStoreName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Total:',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      if (saving > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Save ${_AnimatedMoneyText.format(saving)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _AnimatedMoneyText(
                      amount: cheapestTotal,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Text(
                        'Most expensive:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _AnimatedMoneyText(
                        amount: mostExpensiveTotal,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMoneyText extends StatelessWidget {
  const _AnimatedMoneyText({
    required this.amount,
    required this.style,
  });

  final double amount;
  final TextStyle? style;

  static String format(double amount) => 'R ${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Text(
          format(value),
          style: style,
        );
      },
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
      final String unit = item.product.unit.trim();
      final String quantityLabel = unit.isEmpty ? 'x${item.quantity}' : '$unit x${item.quantity}';
      buffer.writeln(
        '${item.product.name} $quantityLabel - R ${item.lineTotal.toStringAsFixed(2)}',
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
    final theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF315762),
          width: 1.5,
        ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isCheapest,
            onExpansionChanged: (bool expanded) {
              if (expanded) {
                HapticFeedback.lightImpact();
              }
            },
            leading: CircleAvatar(
              backgroundColor: cs.surface,
              child: Text(
                result.storeName.isNotEmpty
                    ? result.storeName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            title: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    result.storeName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isCheapest)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF315762),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'CHEAPEST',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Total: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      _AnimatedMoneyText(
                        amount: result.total,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    result.saving > 0
                        ? 'Save R $_formattedSaving vs most expensive'
                        : 'No saving compared to the other store',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: <Widget>[
                    ...result.items.map((item) {
                      final String unit = item.product.unit.trim();
                      final String quantityLabel = unit.isEmpty
                          ? 'x${item.quantity}'
                          : '$unit x${item.quantity}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${item.product.name} $quantityLabel',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'R ${item.lineTotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _onSavePressed(context),
                            child: const Text('Save'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _openStoreSite,
                            child: const Text('Open'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _shareList,
                            child: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
