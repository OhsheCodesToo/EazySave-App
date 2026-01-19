import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nav_bar.dart';

class MyListsPage extends StatefulWidget {
  const MyListsPage({super.key});

  @override
  State<MyListsPage> createState() => _MyListsPageState();
}

class _MyListsPageState extends State<MyListsPage> {
  late Future<List<_SavedList>> _savedListsFuture;

  @override
  void initState() {
    super.initState();
    _savedListsFuture = _loadSavedLists();
  }

  Future<List<_SavedList>> _loadSavedLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('saved_lists');
    if (raw == null || raw.isEmpty) {
      return <_SavedList>[];
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return <_SavedList>[];
    }

    final List<_SavedList> lists = <_SavedList>[];
    for (final dynamic entry in decoded) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final Map<String, dynamic> map = entry;
      final Map<String, dynamic> itemsRaw =
          (map['items'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final Map<String, int> items = <String, int>{};
      itemsRaw.forEach((String productId, dynamic quantityValue) {
        final int? quantity = quantityValue is int
            ? quantityValue
            : int.tryParse(quantityValue.toString());
        if (quantity != null && quantity > 0) {
          items[productId] = quantity;
        }
      });

      final String storeName = map['storeName'] as String? ?? 'Unknown store';
      final String name = map['name'] as String? ?? '';
      final double total = (map['total'] as num?)?.toDouble() ?? 0;
      final DateTime createdAt = DateTime.tryParse(
            map['createdAt'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      lists.add(
        _SavedList(
          id: map['id'] as String? ?? '',
          name: name,
          storeName: storeName,
          total: total,
          createdAt: createdAt,
          items: items,
        ),
      );
    }

    // Sort newest first.
    lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lists;
  }

  Future<void> _refresh() async {
    setState(() {
      _savedListsFuture = _loadSavedLists();
    });
  }

  Future<void> _loadList(_SavedList list) async {
    final prefs = await SharedPreferences.getInstance();
    // Overwrite the main shopping_list used by CreateListPage.
    await prefs.setString('shopping_list', jsonEncode(list.items));

    // Also remember this list's name for the Home page header.
    final String effectiveName =
        list.name.isNotEmpty ? list.name : '${list.storeName} list';
    await prefs.setString('current_list_name', effectiveName);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const NavBar(initialIndex: 1),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My lists'),
      ),
      body: FutureBuilder<List<_SavedList>>(
        future: _savedListsFuture,
        builder:
            (BuildContext context, AsyncSnapshot<List<_SavedList>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading saved lists'),
            );
          }

          final List<_SavedList> lists = snapshot.data ?? <_SavedList>[];
          if (lists.isEmpty) {
            return const Center(
              child: Text('No saved lists yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: lists.length,
              itemBuilder: (BuildContext context, int index) {
                final _SavedList list = lists[index];
                final DateTime created = list.createdAt;
                final String dateString =
                    '${created.year.toString().padLeft(4, '0')}-'
                    '${created.month.toString().padLeft(2, '0')}-'
                    '${created.day.toString().padLeft(2, '0')}';

                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(
                    list.name.isNotEmpty
                        ? list.name
                        : '${list.storeName} list',
                  ),
                  subtitle: Text(
                    '$dateString • ${list.items.length} items • R ${list.total.toStringAsFixed(2)}',
                  ),
                  trailing: TextButton(
                    onPressed: () => _loadList(list),
                    child: const Text('Load'),
                  ),
                  onTap: () => _loadList(list),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SavedList {
  _SavedList({
    required this.id,
    required this.name,
    required this.storeName,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String name;
  final String storeName;
  final double total;
  final DateTime createdAt;
  final Map<String, int> items;
}
