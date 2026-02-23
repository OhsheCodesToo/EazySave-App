import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalogue_pdf_viewer_page.dart';
import 'grocery_data.dart';
import 'province_dropdown.dart';

class CataloguesPage extends StatefulWidget {
  const CataloguesPage({super.key});

  @override
  State<CataloguesPage> createState() => _CataloguesPageState();
}

class _CataloguesPageState extends State<CataloguesPage> {
  late final Future<GroceryData> _dataFuture;
  int _selectedStoreIndex = 0;
  bool _hasInitializedSelection = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = GroceryDataLoader.load();
  }

  Future<void> _openCataloguePdf(GroceryData data, String storeName) async {
    final String? url = data.storeCatalogueUrlsByName[storeName];

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No catalogue PDF available for $storeName yet.'),
        ),
      );
      return;
    }

    // On web, always open in a new browser tab
    if (kIsWeb) {
      final Uri uri = Uri.parse(url);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open catalogue PDF for $storeName.'),
          ),
        );
      }
      return;
    }

    // On mobile, try in-app viewer first, but fall back to external browser if needed
    if (!mounted) return;

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => CataloguePdfViewerPage(
            storeName: storeName,
            pdfUrl: url,
          ),
        ),
      );
    } catch (_) {
      // If in-app viewer fails, launch in external browser
      final Uri uri = Uri.parse(url);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open catalogue PDF for $storeName.'),
          ),
        );
      }
    }
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
            child: ProvinceDropdown(
              foregroundColor: primaryTeal,
              dropdownColor: pageBackground,
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            Navigator.of(context)
                .popUntil((Route<dynamic> route) => route.isFirst);
          },
        ),
        title: const Text('Catalogues'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: FutureBuilder<GroceryData>(
            future: _dataFuture,
            builder:
                (BuildContext context, AsyncSnapshot<GroceryData> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading catalogues: ${snapshot.error}'),
                );
              }

              final GroceryData? data = snapshot.data;
              if (data == null || data.stores.isEmpty) {
                return const Center(child: Text('No stores available.'));
              }

              if (!_hasInitializedSelection) {
                _hasInitializedSelection = true;
                _selectedStoreIndex = 0;
              }

              final String selectedStore = data.stores[_selectedStoreIndex];
              final List<GroceryProduct> pricedProducts = data.products
                  .where((p) => p.pricesByStore.containsKey(selectedStore))
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryTeal,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Catalogues',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (data.lastUpdated.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(
                              'Prices last updated ${data.lastUpdated}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List<Widget>.generate(
                                data.stores.length,
                                (int index) {
                                  final String storeName = data.stores[index];
                                  final bool selected =
                                      index == _selectedStoreIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(storeName),
                                      selected: selected,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedStoreIndex = index;
                                        });
                                      },
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.20),
                                      selectedColor:
                                          Colors.white.withValues(alpha: 0.35),
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
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openCataloguePdf(data, selectedStore),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: const Text('View catalogue'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: pricedProducts.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No prices available for this store.'),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: pricedProducts.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final GroceryProduct product =
                                      pricedProducts[index];
                                  final double price =
                                      product.pricesByStore[selectedStore] ?? 0;
                                  final String unit = product.unit.trim();
                                  final String name = unit.isEmpty
                                      ? product.name
                                      : '${product.name} ($unit)';
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('R ${price.toStringAsFixed(2)}'),
                                    ],
                                  );
                                },
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
