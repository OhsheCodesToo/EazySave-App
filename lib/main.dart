import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome.dart';
import 'nav_bar.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _firstTime;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getBool('first_time') ?? true;
    setState(() {
      _firstTime = first;
    });
  }

  void _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    setState(() {
      _firstTime = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_firstTime == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
      home: _firstTime == true
          ? WelcomeScreen(
              isFirstTime: true,
              onContinue: _completeWelcome,
            )
          : const NavBar(),
    );
  }
}
