import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/app_remote_config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'services/auth_service.dart';
import 'services/preload_service.dart';
import 'services/remote_config_service.dart';
import 'services/update_service.dart';
import 'widgets/remote_config_popup.dart';

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
    // Run migration check before app starts (async, non-blocking).
    _runMigration();
    runApp(const JagatFilmApp());
  }, (error, stack) {
    // Catch unhandled errors - prevent crash.
    debugPrint('Unhandled error: $error');
  });
}

/// Migration check: if app version changed, clear potentially incompatible data.
Future<void> _runMigration() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = packageInfo.buildNumber;
    final savedBuild = prefs.getString('last_build_number') ?? '';

    if (savedBuild != currentBuild && savedBuild.isNotEmpty) {
      debugPrint('Migration: $savedBuild → $currentBuild');
      // Keep auth data. Add targeted cache migrations here when needed.
    }

    await prefs.setString('last_build_number', currentBuild);
  } catch (_) {
    // Migration failure should never crash the app.
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
  final RemoteConfigService _remoteConfigService = RemoteConfigService();
  final PreloadService _preloadService = PreloadService();

  AppRemoteConfig _config = const AppRemoteConfig.defaults();
  PreloadResult? _preloadResult;
  int _currentIndex = 0;
  bool _isLoadingConfig = true;
  bool _sessionPopupShown = false;
  bool _noticesRunning = false;
  bool _automaticUpdateChecked = false;

  @override
  void initState() {
    super.initState();
    _loadRemoteConfig(showSplash: true);
  }

  @override
  void dispose() {
    _remoteConfigService.dispose();
    super.dispose();
  }

  Future<void> _loadRemoteConfig({required bool showSplash}) async {
    final startedAt = DateTime.now();

    if (showSplash && mounted) {
      setState(() => _isLoadingConfig = true);
    }

    AppRemoteConfig loadedConfig;
    try {
      loadedConfig = await _remoteConfigService.fetch();
    } catch (_) {
      loadedConfig = const AppRemoteConfig.defaults();
    }

    if (!mounted) return;
    setState(() => _config = loadedConfig);

    if (showSplash) {
      // Keep the branded splash visible for five seconds from app start.
      // Use remaining time to preload drama data and images in parallel.
      const minimumSplashDuration = Duration(seconds: 5);
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = minimumSplashDuration - elapsed;

      // Start preload in parallel with remaining splash time
      final preloadFuture = _preloadService.preload(
        config: loadedConfig,
        context: mounted ? context : null,
      );

      if (remaining > Duration.zero) {
        // Wait for both: minimum splash duration AND preload (whichever is longer,
        // but cap preload at splash duration so we never exceed 5s significantly)
        final results = await Future.wait([
          Future.delayed(remaining),
          preloadFuture.timeout(remaining + const Duration(milliseconds: 500),
              onTimeout: () => const PreloadResult.empty()),
        ]);
        if (mounted) _preloadResult = results[1] as PreloadResult;
      } else {
        // Splash already exceeded, just grab whatever preload finished
        if (mounted) {
          _preloadResult = await preloadFuture
              .timeout(const Duration(seconds: 1),
                  onTimeout: () => const PreloadResult.empty());
        }
      }
    }

    if (!mounted) return;
    setState(() => _isLoadingConfig = false);

    if (!_config.maintenanceMode) {
      _scheduleSessionNotices();
    }
  }

  void _scheduleSessionNotices() {
    if (_noticesRunning) return;
    _noticesRunning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _presentSessionNotices();
    });
  }

  Future<void> _presentSessionNotices() async {
    try {
      if (!mounted || _config.maintenanceMode) return;

      final minimumUpdateShown = await UpdateService.checkMinimumVersion(
        context,
        minimumVersion: _config.minimumVersion,
        forceUpdate: _config.forceUpdate,
      );
      if (!mounted || minimumUpdateShown) return;

      if (_config.popupEnabled &&
          _config.hasPopupContent &&
          !_sessionPopupShown) {
        _sessionPopupShown = true;
        final action = await showRemoteConfigPopup(context, _config);
        if (!mounted) return;
        if (action != null && action.isNotEmpty) {
          await _handlePopupAction(action);
          if (action == 'page:update') {
            _automaticUpdateChecked = true;
            return;
          }
        }
      }

      if (!_automaticUpdateChecked && mounted) {
        _automaticUpdateChecked = true;
        await UpdateService.checkForUpdate(context);
      }
    } catch (_) {
      // Remote notices and updates are optional and must never crash the app.
    } finally {
      _noticesRunning = false;
    }
  }

  Future<void> _handlePopupAction(String action) async {
    if (!mounted) return;

    switch (action) {
      case 'page:home':
        setState(() => _currentIndex = 0);
        return;
      case 'page:search':
        setState(() => _currentIndex = 1);
        return;
      case 'page:profile':
        _onBottomNavigationTap(2);
        return;
      case 'page:update':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpdateScreen()),
        );
        return;
      case 'page:login':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      case 'external':
        await _openExternalPopupUrl();
        return;
      default:
        return;
    }
  }

  Future<void> _openExternalPopupUrl() async {
    final uri = Uri.tryParse(_config.popupExternalUrl);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan')),
        );
      }
    }
  }

  void _onBottomNavigationTap(int index) {
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return _RemoteSplash(config: _config);
    }

    if (_config.maintenanceMode) {
      return MaintenanceScreen(
        config: _config,
        onRetry: () => _loadRemoteConfig(showSplash: false),
      );
    }

    final screens = [
      HomeScreen(
        logoUrl: _config.logoUrl,
        announcement: _config.announcement,
        preloadedDramas: _preloadResult,
      ),
      const SearchScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationTap,
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

class _RemoteSplash extends StatelessWidget {
  final AppRemoteConfig config;

  const _RemoteSplash({required this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: config.splashImageUrl.isNotEmpty
            ? Image.network(
                config.splashImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackBackground(),
              )
            : _fallbackBackground(),
      ),
    );
  }

  Widget _fallbackBackground() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F1A), Color(0xFF26204A)],
        ),
      ),
    );
  }
}
