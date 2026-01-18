import 'package:flutter/material.dart';
import 'create_list_page.dart';
import 'home_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(
        onEditList: () => _onItemTapped(1),
      ),
      const CreateListPage(),
      const Center(child: Text('Messages', style: TextStyle(fontSize: 24))),
      const Center(child: Text('My lists', style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('EazySave'),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Create List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My lists',
          ),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
