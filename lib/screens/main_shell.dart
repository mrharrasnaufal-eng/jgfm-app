import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'coin_screen.dart';
import 'for_you_screen.dart';
import 'home_screen.dart';
import 'notification_inbox_screen.dart';
import 'profile_screen.dart';
import 'watchlist_screen.dart';

/// MainShell — wrapper bottom navigation dengan IndexedStack.
/// Preserve state setiap tab menggunakan IndexedStack.
/// Bell icon + unread badge overlay di kanan atas semua screen.
class MainShell extends StatefulWidget {
  /// Optional parameters forwarded to HomeScreen from startup logic.
  final String? logoUrl;
  final String? announcement;

  const MainShell({
    super.key,
    this.logoUrl,
    this.announcement,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _unreadCount = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        logoUrl: widget.logoUrl ?? '',
        announcement: widget.announcement ?? '',
      ),
      const ForYouScreen(),
      const CoinScreen(),
      const WatchlistScreen(),
      const ProfileScreen(),
    ];
    _checkUnread();
  }

  Future<void> _checkUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownIds = prefs.getStringList('shown_notification_ids') ?? [];
      final readIds = prefs.getStringList('read_notification_ids') ?? [];

      // Fetch notification count from server.
      final uri = Uri.parse('https://masterpanel.jagatfilm.com/api/notifications')
          .replace(queryParameters: {
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final response = await http.get(uri, headers: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != true) return;
      final list = decoded['data'] as List? ?? [];

      // Count notifications that haven't been "read" (opened inbox after they appeared).
      final readSet = readIds.toSet();
      int unread = 0;
      for (final item in list) {
        final id = item is Map ? item['id']?.toString() : null;
        if (id != null && !readSet.contains(id)) {
          unread++;
        }
      }

      if (mounted) {
        setState(() => _unreadCount = unread);
      }
    } catch (_) {
      // Non-critical — badge just won't update.
    }
  }

  void _openInbox() async {
    // Mark all current notifications as read.
    try {
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri.parse('https://masterpanel.jagatfilm.com/api/notifications')
          .replace(queryParameters: {
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final response = await http.get(uri, headers: const {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['success'] == true) {
          final list = decoded['data'] as List? ?? [];
          final ids = list
              .whereType<Map>()
              .map((e) => e['id']?.toString())
              .whereType<String>()
              .toList();
          await prefs.setStringList('read_notification_ids', ids);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _unreadCount = 0);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationInboxScreen()),
    ).then((_) => _checkUnread());
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Bell icon overlay — top right, safe area aware
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: _openInbox,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.divider, width: 0.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.divider,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surface,
            selectedItemColor: AppTheme.accent,
            unselectedItemColor: AppTheme.textTertiary,
            selectedLabelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: AppStrings.navBeranda,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome),
                label: AppStrings.navUntukAnda,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monetization_on_rounded),
                label: AppStrings.navKoin,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_rounded),
                label: AppStrings.navDaftarku,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: AppStrings.navProfil,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
