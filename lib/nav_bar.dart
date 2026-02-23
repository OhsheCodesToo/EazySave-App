import 'package:flutter/material.dart';

import 'home_layout_demo_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: HomeLayoutDemoPage(),
    );
  }
}
