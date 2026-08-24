import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'coin_screen.dart';
import 'for_you_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'watchlist_screen.dart';

/// MainShell — wrapper bottom navigation dengan IndexedStack.
/// Preserve state setiap tab menggunakan IndexedStack.
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
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
