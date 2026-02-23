import 'dart:ui';

import 'package:flutter/material.dart';

import 'catalogues_page.dart';
import 'create_list_page.dart';
import 'messages_page.dart';
import 'scroll_route.dart';
import 'view_list_page.dart';
import 'province_dropdown.dart';

class HomeLayoutDemoPage extends StatefulWidget {
  const HomeLayoutDemoPage({super.key});

  @override
  State<HomeLayoutDemoPage> createState() => _HomeLayoutDemoPageState();
}

class _HomeLayoutDemoPageState extends State<HomeLayoutDemoPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    const Color pageBackground = Color(0xFFF5F5F5);
    const Color primaryTeal = Color(0xFF315762);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: Container(
            color: pageBackground,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                    // Header / app bar mimic.
                    Container(
                      height: kToolbarHeight,
                      color: pageBackground,
                      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                      child: IconTheme(
                        data: const IconThemeData(
                          color: primaryTeal,
                        ),
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: primaryTeal,
                          ),
                          child: Row(
                            children: <Widget>[
                              DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.16),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
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
                                      Navigator.of(context).maybePop();
                                    },
                                  ),
                                ),
                              const SizedBox(width: 4),
                              const Text(
                                'EazySave',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
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
                          ),
                        ),
                      ),
                    ),

                    // Banner.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                                      Color.lerp(primaryTeal, Colors.white, 0.30)!,
                                      Colors.white,
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
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'EazySave',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: primaryTeal,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Plan your shop and save more every time.',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: primaryTeal.withValues(alpha: 0.92),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.38),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_cart_outlined,
                                      color: primaryTeal,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    // 2x2 grid of buttons.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: LayoutBuilder(
                        builder: (BuildContext context,
                            BoxConstraints innerConstraints) {
                          const double gap = 12;
                          
                          Widget buildTile({
                            required int index,
                            required String label,
                            required IconData icon,
                          }) {
                            return Expanded(
                              child: Container(
                                height: 108,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: <Widget>[
                                      // Base teal background
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: <Color>[
                                              const Color(0xFF284B56),
                                              const Color(0xFF1A2332),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Inner glass stack
                                      Positioned.fill(
                                        child: Padding(
                                          padding: const EdgeInsets.all(1),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
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
                                              borderRadius: BorderRadius.circular(15),
                                              child: Stack(
                                                children: <Widget>[
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.06),
                                                      border: Border.all(
                                                        color: Colors.white.withValues(alpha: 0.46),
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.all(1),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(14),
                                                        border: Border.all(
                                                          color: Colors.white.withValues(alpha: 0.22),
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
                                                          Colors.white.withValues(alpha: 0.24),
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
                                                          Colors.white.withValues(alpha: 0.14),
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
                                                          Colors.black.withValues(alpha: 0.14),
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
                                      // Content
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            _openSection(index);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Row(
                                              children: <Widget>[
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.14),
                                                    borderRadius: BorderRadius.circular(14),
                                                    border: Border.all(
                                                      color: Colors.white.withValues(alpha: 0.35),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    icon,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    label,
                                                    style: theme.textTheme.titleSmall?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    buildTile(
                                      index: 0,
                                      label: 'View list',
                                      icon: Icons.list_alt,
                                    ),
                                    const SizedBox(width: gap),
                                    buildTile(
                                      index: 1,
                                      label: 'Create list',
                                      icon: Icons.add_box_outlined,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: gap),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    buildTile(
                                      index: 2,
                                      label: 'Catalogues',
                                      icon: Icons.menu_book_outlined,
                                    ),
                                    const SizedBox(width: gap),
                                    buildTile(
                                      index: 3,
                                      label: 'Deals',
                                      icon: Icons.local_offer_outlined,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                  ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSection(int index) async {
    Widget destination;
    switch (index) {
      case 0:
        destination = const ViewListPage();
        break;
      case 1:
        destination = const CreateListPage(showBackground: false);
        break;
      case 2:
        destination = const CataloguesPage();
        break;
      case 3:
      default:
        destination = const MessagesPage(showBackground: false);
        break;
    }

    await Navigator.of(context).push(buildScrollRoute<void>(destination));
  }
}
