import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Placeholder screens for tabs not yet implemented.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text(
            title,
            style: const TextStyle(color: AppTheme.textTertiary),
          ),
        ),
      );
}

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
      const _PlaceholderScreen(title: 'Untuk Anda — Segera Hadir'),
      const _PlaceholderScreen(title: 'Koin — Segera Hadir'),
      const _PlaceholderScreen(title: 'Daftarku — Segera Hadir'),
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
