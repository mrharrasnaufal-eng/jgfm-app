import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Adsterra ad service — ALL ads render in-app via WebView.
/// NO external browser redirect.
///
/// - Interstitial: fullscreen WebView, skip button after 5 seconds.
/// - Rewarded: fullscreen WebView, claim button after 8 seconds.
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

  /// Increment episode counter and return true if ad should show.
  static bool shouldShowInterstitial() {
    _episodeCounter++;
    return _episodeCounter % _interstitialFrequency == 0;
  }

  /// Reset counter.
  static void resetCounter() => _episodeCounter = 0;

  /// Show interstitial ad (WebView in-app, skip after 5 seconds).
  static Future<bool> showInterstitial(BuildContext context) async {
    if (!context.mounted) return false;
    try {
      final result = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => const _InAppAdScreen(
            skipDelay: 5,
            isRewarded: false,
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
          pageBuilder: (_, __, ___) => const _InAppAdScreen(
            skipDelay: 8,
            isRewarded: true,
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
}

/// Fullscreen in-app WebView ad screen.
/// Loads Adsterra Smartlink inside WebView — stays in-app.
/// Skip/Claim button appears after [skipDelay] seconds.
class _InAppAdScreen extends StatefulWidget {
  final int skipDelay;
  final bool isRewarded;

  const _InAppAdScreen({
    required this.skipDelay,
    required this.isRewarded,
  });

  @override
  State<_InAppAdScreen> createState() => _InAppAdScreenState();
}

class _InAppAdScreenState extends State<_InAppAdScreen> {
  late final WebViewController _webController;
  int _secondsRemaining = 0;
  bool _canClose = false;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.skipDelay;
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
          // Keep all navigation inside the WebView — never open external browser
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
    html, body {
      width: 100%;
      height: 100%;
      background: #0a0a0a;
      overflow: hidden;
    }
    .ad-container {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: none;
    }
  </style>
</head>
<body>
  <div class="ad-container">
    <iframe src="${AdService.smartlinkUrl}" 
            allowfullscreen 
            allow="autoplay; encrypted-media"
            sandbox="allow-scripts allow-same-origin allow-popups allow-forms allow-top-navigation">
    </iframe>
  </div>
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
          _canClose = true;
        }
      });

      return _secondsRemaining > 0;
    });
  }

  void _close({bool rewarded = false}) {
    Navigator.pop(context, rewarded || !widget.isRewarded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // WebView — fills entire screen
          Positioned.fill(
            child: WebViewWidget(controller: _webController),
          ),

          // Loading indicator while WebView loads
          if (!_webViewReady)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Memuat iklan...',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top bar — countdown / skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _canClose
                ? _buildActionButton()
                : _buildCountdown(),
          ),

          // Rewarded label at top
          if (widget.isRewarded)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: AppTheme.gold,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '+10 Koin',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildCountdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              value: (widget.skipDelay - _secondsRemaining) / widget.skipDelay,
              strokeWidth: 2,
              color: AppTheme.textSecondary,
              backgroundColor: AppTheme.divider,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_secondsRemaining}s',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (widget.isRewarded) {
      // Rewarded: show "Klaim Koin" button
      return GestureDetector(
        onTap: () => _close(rewarded: true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(20),
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
              Icon(Icons.check_rounded, color: Colors.black, size: 16),
              SizedBox(width: 4),
              Text(
                'Klaim +10 Koin',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Interstitial: show "Skip" button
      return GestureDetector(
        onTap: () => _close(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider, width: 0.5),
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
      );
    }
  }
}
