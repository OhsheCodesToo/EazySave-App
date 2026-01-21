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
    final ThemeData theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F7F8),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
      ),
    );

    if (_firstTime == null || _hasCompletedInitialList == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        themeMode: ThemeMode.light,
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
      theme: theme,
      themeMode: ThemeMode.light,
      home: home,
    );
  }
}
