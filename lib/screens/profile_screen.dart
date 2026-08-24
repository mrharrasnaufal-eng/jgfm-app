import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/coin_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

/// Redesigned Profile screen — avatar, stats, coin banner, menu, settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = 'v${info.version}');
      }
    } catch (_) {
      // Non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildTopBar(context),
              _buildProfileHeader(context),
              const SizedBox(height: AppSpacing.lg),
              _buildCoinBanner(context),
              const SizedBox(height: AppSpacing.lg),
              _buildBenefitGrid(),
              const SizedBox(height: AppSpacing.lg),
              _buildMenuList(context),
              const SizedBox(height: AppSpacing.lg),
              _buildLogoutButton(context),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => _showComingSoon(context, 'Notifikasi'),
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textPrimary,
              size: 24,
            ),
            tooltip: 'Notifikasi',
          ),
          IconButton(
            onPressed: () => _showComingSoon(context, 'Pengaturan'),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textPrimary,
              size: 24,
            ),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isLoggedIn) {
          return _buildGuestHeader(context);
        }
        return _buildUserHeader(authService);
      },
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InkWell(
        onTap: () => _navigateToLogin(context),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              // Avatar placeholder
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Login',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppFontSize.h3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textTertiary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Masuk untuk sinkronisasi data',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(AuthService authService) {
    final user = authService.user!;
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            // Avatar with initial
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: AppFontSize.caption,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: user.isVip
                          ? AppTheme.gold.withOpacity(0.15)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      user.isVip ? '⭐ VIP' : 'Free Plan',
                      style: TextStyle(
                        color: user.isVip ? AppTheme.gold : AppTheme.textTertiary,
                        fontSize: AppFontSize.micro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinBanner(BuildContext context) {
    return Consumer<CoinService>(
      builder: (context, coinService, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D1B3D),
                  AppTheme.card,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: AppTheme.gold,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Koin Saya',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppFontSize.caption,
                        ),
                      ),
                      Text(
                        '${coinService.balance} Koin',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: AppFontSize.h3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showComingSoon(context, 'Dapatkan Koin'),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      'Dapatkan Koin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _BenefitCard(
              icon: Icons.movie_filter_rounded,
              label: '25\nProvider',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _BenefitCard(
              icon: Icons.monetization_on_rounded,
              label: 'Koin\nGratis',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _BenefitCard(
              icon: Icons.download_rounded,
              label: 'Unduh\nEpisode',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _BenefitCard(
              icon: Icons.hd_rounded,
              label: 'HD\n1080p',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            _MenuItem(
              icon: Icons.monetization_on_rounded,
              iconColor: AppTheme.gold,
              title: 'Dompet Saya',
              trailing: '0 Koin',
              onTap: () => _showComingSoon(context, 'Dompet'),
            ),
            const Divider(color: AppTheme.divider, height: 0.5, indent: 52),
            _MenuItem(
              icon: Icons.card_giftcard_rounded,
              iconColor: AppTheme.accent,
              title: 'Dapatkan Hadiah',
              trailing: '+10',
              onTap: () => _showComingSoon(context, 'Hadiah'),
            ),
            const Divider(color: AppTheme.divider, height: 0.5, indent: 52),
            _MenuItem(
              icon: Icons.history_rounded,
              iconColor: AppTheme.secondary,
              title: 'Riwayat Tontonan',
              onTap: () {
                // Navigate to watchlist tab via parent
                _showComingSoon(context, 'Riwayat — buka tab Daftarku');
              },
            ),
            const Divider(color: AppTheme.divider, height: 0.5, indent: 52),
            _MenuItem(
              icon: Icons.download_rounded,
              iconColor: AppTheme.success,
              title: 'Unduhan',
              onTap: () => _showComingSoon(context, 'Unduhan'),
            ),
            const Divider(color: AppTheme.divider, height: 0.5, indent: 52),
            _MenuItem(
              icon: Icons.language_rounded,
              iconColor: AppTheme.textSecondary,
              title: 'Bahasa',
              trailing: 'Indonesia',
              onTap: () => _showComingSoon(context, 'Bahasa'),
            ),
            const Divider(color: AppTheme.divider, height: 0.5, indent: 52),
            _MenuItem(
              icon: Icons.info_outline_rounded,
              iconColor: AppTheme.textSecondary,
              title: 'Tentang Aplikasi',
              trailing: _appVersion,
              onTap: () => _showAboutDialog(context),
            ),
            const Divider(color: AppTheme.divider, height: 0.5, indent: 52),
            _MenuItem(
              icon: Icons.system_update_rounded,
              iconColor: AppTheme.trending,
              title: 'Cek Pembaruan',
              onTap: () => _checkUpdate(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isLoggedIn) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error, width: 0.5),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Segera Hadir'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'JagatFilm',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi: $_appVersion',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Streaming drama pendek gratis dari 25+ provider.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '© 2026 JagatFilm',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate(BuildContext context) async {
    try {
      await UpdateService.checkForUpdate(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memeriksa pembaruan')),
        );
      }
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Keluar?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Kamu akan keluar dari akun ini.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthService>().logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Berhasil keluar')),
              );
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2x2 benefit card.
class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppFontSize.micro + 1,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu list item.
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppFontSize.body,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: AppFontSize.caption,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
