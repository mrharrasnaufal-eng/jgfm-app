import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Adsterra ad service using url_launcher + overlay screens.
///
/// - Interstitial (Social Bar): countdown overlay → opens ad in browser.
/// - Rewarded (Smartlink): opens ad URL, user returns → earns coins.
///
/// No extra native dependencies needed — uses url_launcher (already in pubspec).
class AdService {
  /// Adsterra Smartlink URL (rewarded ad — earn coins).
  static const String smartlinkUrl =
      'https://www.profitableratecpmnetwork.com/di3wty1wyn?key=c47e33c0ab9d356979cc624ac0f44579';

  /// Track episode count for interstitial frequency.
  static int _episodeCounter = 0;

  /// How often to show interstitial (every N episodes).
  static const int _interstitialFrequency = 3;

  /// Increment episode counter and return true if ad should show.
  static bool shouldShowInterstitial() {
    _episodeCounter++;
    return _episodeCounter % _interstitialFrequency == 0;
  }

  /// Reset counter (e.g., on app restart).
  static void resetCounter() => _episodeCounter = 0;

  /// Show interstitial ad overlay (5 seconds countdown then auto-close).
  /// Opens smartlink in background for monetization.
  static Future<bool> showInterstitial(BuildContext context) async {
    if (!context.mounted) return false;

    try {
      final result = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => const _InterstitialOverlay(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Show rewarded ad — opens Smartlink in external browser.
  /// Returns true (reward granted) — user tapped the button.
  static Future<bool> showRewarded(BuildContext context) async {
    if (!context.mounted) return false;

    try {
      final result = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => const _RewardedOverlay(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Open smartlink URL in external browser.
  static Future<void> _openSmartlink() async {
    try {
      final uri = Uri.parse(smartlinkUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silent fail
    }
  }
}

/// Interstitial ad overlay — shows for 5 seconds then auto-closes.
class _InterstitialOverlay extends StatefulWidget {
  const _InterstitialOverlay();

  @override
  State<_InterstitialOverlay> createState() => _InterstitialOverlayState();
}

class _InterstitialOverlayState extends State<_InterstitialOverlay> {
  int _secondsRemaining = 5;
  bool _canClose = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Open ad link in background after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      AdService._openSmartlink();
    });
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _canClose = true;
        }
      });

      if (_secondsRemaining <= 0) {
        // Auto-close after 1 second
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
        return false;
      }

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            // Ad content area
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: AppTheme.accent,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Sponsor',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppFontSize.h2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Iklan dari partner kami',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: AppFontSize.body,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Progress indicator
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: (5 - _secondsRemaining) / 5,
                        backgroundColor: AppTheme.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accent),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-right countdown / close button
            Positioned(
              top: 12,
              right: 16,
              child: _canClose
                  ? GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Tutup',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_secondsRemaining}s',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rewarded ad overlay — user taps to watch ad, waits, gets reward.
class _RewardedOverlay extends StatefulWidget {
  const _RewardedOverlay();

  @override
  State<_RewardedOverlay> createState() => _RewardedOverlayState();
}

class _RewardedOverlayState extends State<_RewardedOverlay> {
  bool _adOpened = false;
  int _secondsRemaining = 5;
  bool _rewardReady = false;

  void _openAd() {
    setState(() => _adOpened = true);
    AdService._openSmartlink();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _rewardReady = true;
        }
      });

      return _secondsRemaining > 0;
    });
  }

  void _claimReward() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Coin icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on_rounded,
                    color: AppTheme.gold,
                    size: 44,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Tonton Iklan',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppFontSize.h2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Tonton iklan singkat untuk mendapat +10 Koin',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppFontSize.body,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                if (!_adOpened) ...[
                  // Button to open ad
                  FilledButton.icon(
                    onPressed: _openAd,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Tonton Sekarang'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Nanti saja',
                      style: TextStyle(color: AppTheme.textTertiary),
                    ),
                  ),
                ] else if (!_rewardReady) ...[
                  // Waiting countdown
                  const Text(
                    'Iklan sedang ditampilkan...',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: (5 - _secondsRemaining) / 5,
                      backgroundColor: AppTheme.divider,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Koin siap dalam ${_secondsRemaining}s',
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                ] else ...[
                  // Reward ready
                  const Text(
                    '🎉 +10 Koin!',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: AppFontSize.h1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _claimReward,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Klaim Koin'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
