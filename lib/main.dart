import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/app_remote_config.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/maintenance_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'services/auth_service.dart';
import 'services/remote_config_service.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';
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
        theme: AppTheme.darkTheme,
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

  AppRemoteConfig _config = const AppRemoteConfig.defaults();
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
      // Keep the branded splash visible for a minimum duration.
      const minimumSplashDuration = Duration(seconds: 3);
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = minimumSplashDuration - elapsed;

      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
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
        // Already on home after splash
        return;
      case 'page:search':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        return;
      case 'page:profile':
        // Profile is handled by MainShell bottom nav
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

    return MainShell(
      logoUrl: _config.logoUrl,
      announcement: _config.announcement,
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
