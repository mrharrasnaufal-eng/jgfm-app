import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import '../services/coin_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Koin / Reward Center screen.
/// Full UI ready — all actions show "Segera Hadir" snackbar until backend is live.
class CoinScreen extends StatelessWidget {
  const CoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.lg),
              _buildEarnSection(context),
              const SizedBox(height: AppSpacing.xl),
              _buildUseSection(context),
              const SizedBox(height: AppSpacing.xl),
              _buildCtaBanner(context),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<CoinService>(
      builder: (context, coinService, _) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF0D0D0D)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            border: Border.all(
              color: AppTheme.gold.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: AppTheme.gold,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Koin Saya',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppFontSize.body,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${coinService.balance} Koin',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HeaderButton(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Isi Ulang',
                    onTap: () => _showComingSoon(context),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _HeaderButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Riwayat',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarnSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dapatkan Koin Gratis',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppFontSize.h3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MissionTile(
            icon: Icons.play_circle_outline_rounded,
            iconColor: AppTheme.accent,
            title: 'Tonton Iklan',
            reward: '+10',
            trailing: _MissionAction(
              label: '▶',
              onTap: () => _watchAd(context),
            ),
          ),
          _MissionTile(
            icon: Icons.calendar_today_rounded,
            iconColor: AppTheme.success,
            title: 'Login Harian',
            reward: '+5',
            trailing: _MissionAction(
              label: '✓',
              onTap: () => _showComingSoon(context),
              completed: true,
            ),
          ),
          _MissionTile(
            icon: Icons.movie_filter_rounded,
            iconColor: AppTheme.secondary,
            title: 'Tonton 3 Episode',
            reward: '+15',
            trailing: _MissionAction(
              label: '0/3',
              onTap: () => _showComingSoon(context),
            ),
          ),
          _MissionTile(
            icon: Icons.star_rounded,
            iconColor: AppTheme.gold,
            title: 'Review di Play Store',
            reward: '+50',
            trailing: _MissionAction(
              label: '→',
              onTap: () => _showComingSoon(context),
            ),
          ),
          _MissionTile(
            icon: Icons.people_rounded,
            iconColor: AppTheme.trending,
            title: 'Undang Teman',
            reward: '+100',
            trailing: _MissionAction(
              label: '→',
              onTap: () => _showComingSoon(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cara Pakai Koin',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppFontSize.h3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _UsageCard(
            icon: Icons.lock_open_rounded,
            title: 'Buka Episode Terkunci',
            subtitle: '5 Koin/episode',
          ),
          const SizedBox(height: AppSpacing.sm),
          _UsageCard(
            icon: Icons.download_rounded,
            title: 'Download Episode',
            subtitle: '10 Koin/episode',
          ),
          const SizedBox(height: AppSpacing.sm),
          _UsageCard(
            icon: Icons.block_rounded,
            title: 'Hilangkan Iklan 1 Jam',
            subtitle: '20 Koin',
          ),
        ],
      ),
    );
  }

  Widget _buildCtaBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InkWell(
        onTap: () => _watchAd(context),
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accent, AppTheme.secondary],
            ),
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
          ),
          child: Column(
            children: [
              const Text(
                '🎬 Tonton Iklan Sekarang — Dapat 10 Koin',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'Tonton Iklan - Gratis',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🪙 Fitur koin segera hadir!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Future<void> _watchAd(BuildContext context) async {
    final rewarded = await AdService.showRewarded(context);
    if (rewarded && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 +10 Koin berhasil diklaim!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Small outlined button in header.
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.gold.withOpacity(0.4), width: 1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.gold),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mission list tile.
class _MissionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String reward;
  final Widget trailing;

  const _MissionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.reward,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$reward 🪙',
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: AppFontSize.body,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          trailing,
        ],
      ),
    );
  }
}

/// Action button for mission.
class _MissionAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool completed;

  const _MissionAction({
    required this.label,
    required this.onTap,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: completed
              ? AppTheme.success.withOpacity(0.2)
              : AppTheme.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: completed ? AppTheme.success : AppTheme.accent,
            fontSize: AppFontSize.caption,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Usage info card.
class _UsageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _UsageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: AppFontSize.caption,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: const Text(
              'Segera Hadir',
              style: TextStyle(
                color: AppTheme.secondary,
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
