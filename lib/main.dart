import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // Run migration check before app starts (async, non-blocking)
    _runMigration();
    runApp(const JagatFilmApp());
  }, (error, stack) {
    // Catch unhandled errors - prevent crash
    debugPrint('Unhandled error: $error');
  });
}

/// Migration check: if app version changed, clear potentially incompatible data
Future<void> _runMigration() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = packageInfo.buildNumber;
    final savedBuild = prefs.getString('last_build_number') ?? '';

    if (savedBuild != currentBuild && savedBuild.isNotEmpty) {
      // Version changed! Clear old cached data that might be incompatible
      // Keep user auth data (user, token) but clear anything else
      debugPrint('Migration: $savedBuild → $currentBuild');
      // Currently no cached data to clear, but this is the hook for future use
    }

    // Save current build number
    await prefs.setString('last_build_number', currentBuild);
  } catch (_) {
    // Migration failure should never crash the app
  }
}

class JagatFilmApp extends StatelessWidget {
  const JagatFilmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()..loadUser(),
      child: MaterialApp(
        title: 'JagatFilm',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF6C63FF),
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            secondary: Color(0xFFFF6584),
            surface: Color(0xFF1A1A2E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F0F1A),
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1A1A2E),
            selectedItemColor: Color(0xFF6C63FF),
            unselectedItemColor: Colors.grey,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            final auth = Provider.of<AuthService>(context, listen: false);
            if (!auth.isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              return;
            }
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Cari',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
