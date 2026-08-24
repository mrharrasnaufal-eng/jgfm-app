import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Adsterra ad service — ALL ads render in-app via WebView.
///
/// Interstitial flow:
/// 1. WebView fullscreen loads Smartlink
/// 2. Random countdown 10-15 seconds
/// 3. After countdown: fake "skip" icon (⏭) appears TOP-LEFT — this opens ad link
/// 4. User clicks fake skip → opens ad URL in browser → leaves app
/// 5. User returns to app → REAL skip button (✕) appears TOP-RIGHT
///
/// Rewarded flow:
/// 1. WebView fullscreen loads Smartlink
/// 2. 8 second countdown
/// 3. After countdown: "Klaim +1 Koin" button appears
class AdService {
  /// Adsterra Smartlink URL (monetization).
  static const String smartlinkUrl =
      'https://www.profitableratecpmnetwork.com/di3wty1wyn?key=c47e33c0ab9d356979cc624ac0f44579';

  /// Adsterra Social Bar script URL.
  static const String socialBarScript =
      'https://pl31014943.profitableratecpmnetwork.com/66/6c/7c/666c7ce659a3b0bde35db22bfcdca692.js';

  /// Track episode count for interstitial frequency.
  static int _episodeCounter = 0;

  /// How often to show interstitial (every N episodes).
  static const int _interstitialFrequency = 3;

  /// Random duration range for interstitial (seconds).
  static const int _minDuration = 10;
  static const int _maxDuration = 15;

  /// Generate random duration between min and max.
  static int _randomDuration() {
    return _minDuration + Random().nextInt(_maxDuration - _minDuration + 1);
  }

  /// Increment episode counter and return true if ad should show.
  static bool shouldShowInterstitial() {
    _episodeCounter++;
    return _episodeCounter % _interstitialFrequency == 0;
  }

  /// Reset counter.
  static void resetCounter() => _episodeCounter = 0;

  /// Show interstitial ad with fake skip mechanism.
  static Future<bool> showInterstitial(BuildContext context) async {
    if (!context.mounted) return false;
    try {
      final result = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => _InterstitialAdScreen(
            duration: _randomDuration(),
          ),
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

  /// Show rewarded ad (WebView in-app, claim after 8 seconds).
  static Future<bool> showRewarded(BuildContext context) async {
    if (!context.mounted) return false;
    try {
      final result = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => const _RewardedAdScreen(),
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

  /// Open smartlink URL in external browser (for fake skip click).
  static Future<void> openAdLink() async {
    try {
      final uri = Uri.parse(smartlinkUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

/// Interstitial ad screen with fake skip mechanism.
///
/// Phase 1: Countdown (10-15s random) — no buttons visible
/// Phase 2: Fake skip icon appears (top-left, small ⏭) — opens ad link
/// Phase 3: After user returns from ad click — real skip (top-right, ✕)
class _InterstitialAdScreen extends StatefulWidget {
  final int duration;

  const _InterstitialAdScreen({required this.duration});

  @override
  State<_InterstitialAdScreen> createState() => _InterstitialAdScreenState();
}

class _InterstitialAdScreenState extends State<_InterstitialAdScreen>
    with WidgetsBindingObserver {
  late final WebViewController _webController;
  int _secondsRemaining = 0;
  bool _countdownDone = false;
  bool _fakeSkipClicked = false;
  bool _returnedFromAd = false;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = widget.duration;
    _initWebView();
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Detect when user returns to app after clicking fake skip.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _fakeSkipClicked) {
      // User returned from browser — show real skip
      setState(() => _returnedFromAd = true);
    }
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _webViewReady = true);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_buildAdHtml());
  }

  String _buildAdHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #0a0a0a; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <iframe src="${AdService.smartlinkUrl}" allowfullscreen sandbox="allow-scripts allow-same-origin allow-popups allow-forms allow-top-navigation"></iframe>
  <script src="${AdService.socialBarScript}" async></script>
</body>
</html>
''';
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _countdownDone = true;
        }
      });

      return _secondsRemaining > 0;
    });
  }

  /// Fake skip: opens ad link in browser.
  void _onFakeSkipTap() {
    setState(() => _fakeSkipClicked = true);
    AdService.openAdLink();
  }

  /// Real skip: close and return to player.
  void _onRealSkip() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // WebView fullscreen
          Positioned.fill(
            child: WebViewWidget(controller: _webController),
          ),

          // Loading overlay
          if (!_webViewReady)
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

          // Phase 1: Countdown (top-right)
          if (!_countdownDone)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_secondsRemaining}s',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Phase 2: Fake skip button (top-left, small, looks like skip/fast-forward)
          if (_countdownDone && !_returnedFromAd)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: GestureDetector(
                onTap: _onFakeSkipTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white60,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Phase 3: Real skip button (top-right) — only after returning from ad click
          if (_returnedFromAd)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: _onRealSkip,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 0.5),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rewarded ad screen — clean, no manipulation (user chose to watch).
class _RewardedAdScreen extends StatefulWidget {
  const _RewardedAdScreen();

  @override
  State<_RewardedAdScreen> createState() => _RewardedAdScreenState();
}

class _RewardedAdScreenState extends State<_RewardedAdScreen> {
  late final WebViewController _webController;
  int _secondsRemaining = 8;
  bool _canClaim = false;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startCountdown();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _webViewReady = true);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_buildAdHtml());
  }

  String _buildAdHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #0a0a0a; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <iframe src="${AdService.smartlinkUrl}" allowfullscreen sandbox="allow-scripts allow-same-origin allow-popups allow-forms allow-top-navigation"></iframe>
  <script src="${AdService.socialBarScript}" async></script>
</body>
</html>
''';
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _canClaim = true;
        }
      });

      return _secondsRemaining > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _webController),
          ),

          if (!_webViewReady)
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

          // Countdown or Claim button (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _canClaim
                ? GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
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
                          Icon(Icons.check_rounded,
                              color: Colors.black, size: 14),
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
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            backgroundColor: Colors.white24,
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
                  ),
          ),
        ],
      ),
    );
  }
}
