import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome.dart';
import 'nav_bar.dart';
import 'services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _firstTime;
  bool? _hasCompletedInitialList;

  @override
  void initState() {
    super.initState();
    _loadStartupFlags();
  }

  Future<void> _loadStartupFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final bool first = prefs.getBool('first_time') ?? true;
    final bool completed = prefs.getBool('has_completed_initial_list') ?? false;
    setState(() {
      _firstTime = first;
      _hasCompletedInitialList = completed;
    });
  }

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    await prefs.setBool('has_completed_initial_list', false);
    setState(() {
      _firstTime = false;
      _hasCompletedInitialList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_firstTime == null || _hasCompletedInitialList == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final Widget home;
    if (_firstTime == true) {
      home = WelcomeScreen(
        isFirstTime: true,
        onContinue: _completeWelcome,
      );
    } else if (_hasCompletedInitialList == false) {
      // User has completed welcome but not their first full list yet:
      // start them on the Create List tab.
      home = const NavBar(initialIndex: 1);
    } else {
      // Normal flow: start on Home tab.
      home = const NavBar();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}
