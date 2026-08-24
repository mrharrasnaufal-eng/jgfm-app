import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

/// Adsterra ad service with 2 variants:
/// - Variant A (normal): every 3 episodes, countdown → real skip
/// - Variant B (aggressive): every 6 episodes, countdown → fake skip → real skip
///
/// All buttons positioned TOP-RIGHT.
/// Countdown starts AFTER WebView finishes loading.
class AdService {
  static const String smartlinkUrl =
      'https://www.profitableratecpmnetwork.com/di3wty1wyn?key=c47e33c0ab9d356979cc624ac0f44579';

  static const String socialBarScript =
      'https://pl31014943.profitableratecpmnetwork.com/66/6c/7c/666c7ce659a3b0bde35db22bfcdca692.js';

  static int _episodeCounter = 0;

  static const int _minDuration = 10;
  static const int _maxDuration = 15;

  static int _randomDuration() {
    return _minDuration + Random().nextInt(_maxDuration - _minDuration + 1);
  }

  /// Increment and check if ad should show. Returns variant or null.
  /// Episode 3: Variant A (normal skip)
  /// Episode 6: Variant B (fake skip)
  static String? shouldShowAd() {
    _episodeCounter++;
    if (_episodeCounter % 6 == 0) return 'B'; // Aggressive
    if (_episodeCounter % 3 == 0) return 'A'; // Normal
    return null;
  }

  /// Reset counter.
  static void resetCounter() => _episodeCounter = 0;

  /// Show interstitial ad — picks variant automatically.
  static Future<bool> showInterstitial(BuildContext context) async {
    final variant = shouldShowAd();
    if (variant == null || !context.mounted) return false;

    // Reset counter was already incremented by shouldShowAd, so we call directly
    try {
      final result = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => _InterstitialScreen(
            variant: variant,
            duration: _randomDuration(),
          ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Alternative: manually show with specific variant (for PlayerScreen).
  static Future<bool> showInterstitialVariant(
      BuildContext context, String variant) async {
    if (!context.mounted) return false;
    try {
      final result = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => _InterstitialScreen(
            variant: variant,
            duration: _randomDuration(),
          ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Show rewarded ad (8s countdown + klaim, always clean).
  static Future<bool> showRewarded(BuildContext context) async {
    if (!context.mounted) return false;
    try {
      final result = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => const _RewardedAdScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Open smartlink in external browser.
  static Future<void> openAdLink() async {
    try {
      await launchUrl(Uri.parse(smartlinkUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

// ============================================================
// INTERSTITIAL SCREEN — supports Variant A (normal) and B (fake skip)
// ============================================================
class _InterstitialScreen extends StatefulWidget {
  final String variant; // 'A' = normal, 'B' = fake skip
  final int duration;

  const _InterstitialScreen({required this.variant, required this.duration});

  @override
  State<_InterstitialScreen> createState() => _InterstitialScreenState();
}

class _InterstitialScreenState extends State<_InterstitialScreen>
    with WidgetsBindingObserver {
  late final WebViewController _webController;

  // States
  bool _adLoaded = false; // WebView finished loading
  int _secondsRemaining = 0;
  bool _countdownStarted = false;
  bool _countdownDone = false;
  bool _fakeSkipClicked = false;
  bool _returnedFromAd = false;

  @override
  void initState() {
    super.initState();
    if (widget.variant == 'B') {
      WidgetsBinding.instance.addObserver(this);
    }
    _secondsRemaining = widget.duration;
    _initWebView();
  }

  @override
  void dispose() {
    if (widget.variant == 'B') {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  /// Detect user returning from browser (Variant B only).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _fakeSkipClicked && mounted) {
      setState(() => _returnedFromAd = true);
    }
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted && !_adLoaded) {
              setState(() => _adLoaded = true);
              _startCountdown();
            }
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(AdService.smartlinkUrl));
  }

  void _startCountdown() {
    if (_countdownStarted) return;
    _countdownStarted = true;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) _countdownDone = true;
      });
      return _secondsRemaining > 0;
    });
  }

  void _onFakeSkipTap() {
    setState(() => _fakeSkipClicked = true);
    AdService.openAdLink();
  }

  void _onRealSkip() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 10;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // WebView fullscreen
          Positioned.fill(
            child: WebViewWidget(controller: _webController),
          ),

          // Loading spinner (before ad loads)
          if (!_adLoaded)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          // === TOP-RIGHT BUTTON AREA (all states) ===
          Positioned(
            top: topPad,
            right: 14,
            child: _buildTopRightButton(),
          ),
        ],
      ),
    );
  }

  /// Single top-right button that changes based on state.
  Widget _buildTopRightButton() {
    // Not loaded yet → nothing
    if (!_adLoaded) return const SizedBox.shrink();

    // Countdown still running → show timer
    if (!_countdownDone) {
      return _buildCountdownBadge();
    }

    // === Variant A (normal): countdown done → show real skip ===
    if (widget.variant == 'A') {
      return _buildRealSkipButton();
    }

    // === Variant B (aggressive): countdown done → fake skip or real skip ===
    if (_returnedFromAd) {
      // User returned from browser → show real skip
      return _buildRealSkipButton();
    } else {
      // Show fake skip (looks like skip button but opens ad link)
      return _buildFakeSkipButton();
    }
  }

  Widget _buildCountdownBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              value: (widget.duration - _secondsRemaining) / widget.duration,
              strokeWidth: 2,
              color: Colors.white54,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_secondsRemaining}s',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFakeSkipButton() {
    // Looks like a skip button but opens ad link
    return GestureDetector(
      onTap: _onFakeSkipTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.skip_next_rounded, color: Colors.white60, size: 16),
            SizedBox(width: 3),
            Text(
              'Lewati',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealSkipButton() {
    return GestureDetector(
      onTap: _onRealSkip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white30, width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Lewati',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// REWARDED AD SCREEN — always clean (user voluntarily watches)
// ============================================================
class _RewardedAdScreen extends StatefulWidget {
  const _RewardedAdScreen();

  @override
  State<_RewardedAdScreen> createState() => _RewardedAdScreenState();
}

class _RewardedAdScreenState extends State<_RewardedAdScreen> {
  late final WebViewController _webController;
  bool _adLoaded = false;
  int _secondsRemaining = 8;
  bool _countdownStarted = false;
  bool _canClaim = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted && !_adLoaded) {
              setState(() => _adLoaded = true);
              _startCountdown();
            }
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(AdService.smartlinkUrl));
  }

  void _startCountdown() {
    if (_countdownStarted) return;
    _countdownStarted = true;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) _canClaim = true;
      });
      return _secondsRemaining > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 10;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _webController),
          ),

          if (!_adLoaded)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          // Coin label top-left
          if (_adLoaded)
            Positioned(
              top: topPad,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on_rounded,
                        color: AppTheme.gold, size: 14),
                    SizedBox(width: 4),
                    Text('+1 Koin',
                        style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

          // Top-right: countdown or claim
          if (_adLoaded)
            Positioned(
              top: topPad,
              right: 14,
              child: _canClaim ? _buildClaimButton() : _buildCountdown(),
            ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              value: (8 - _secondsRemaining) / 8,
              strokeWidth: 2,
              color: AppTheme.gold,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_secondsRemaining}s',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context, true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.gold.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: Colors.black, size: 14),
            SizedBox(width: 4),
            Text(
              'Klaim +1 Koin',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
