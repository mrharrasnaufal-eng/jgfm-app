import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/app_remote_config.dart';
import '../models/drama.dart';
import '../services/api_service.dart';

/// Result of the preload operation performed during splash.
class PreloadResult {
  final List<Drama> dramas;
  final Map<String, int> providers;
  final bool hasMore;

  const PreloadResult({
    required this.dramas,
    required this.providers,
    required this.hasMore,
  });

  const PreloadResult.empty()
      : dramas = const [],
        providers = const {},
        hasMore = true;

  bool get isEmpty => dramas.isEmpty;
}

/// Preloads drama data and images during the splash screen window.
/// All operations are fail-safe: errors are caught silently so the app
/// always starts even if preloading partially or fully fails.
class PreloadService {
  static const _workingProviders = [
    'shortmax', 'cashdrama', 'netshort', 'rapidtv', 'bilitv',
    'flickreels', 'melolo', 'wetv', 'dramabite', 'reelshort',
    'microdrama', 'dotdrama', 'dramabox', 'starshort',
  ];

  /// Max thumbnails to precache.
  static const _maxPrecacheThumbnails = 12;

  final ApiService _api = ApiService();

  /// Fetch dramas from the configured home provider, and precache
  /// popup + thumbnail images. Designed to run within the 5-second splash window.
  Future<PreloadResult> preload({
    required AppRemoteConfig config,
    BuildContext? context,
    String homeProvider = 'shortmax',
  }) async {
    try {
      // Fetch from admin-configured home provider
      final response = await _api
          .getDramas(page: 1, limit: 30, provider: homeProvider)
          .timeout(const Duration(seconds: 4));

      final dramas = response.dramas;
      final providers = Map<String, int>.from(response.providers);
      providers.removeWhere((key, _) => !_workingProviders.contains(key));

      // Precache images in parallel (non-blocking, best-effort)
      if (context != null) {
        _precacheImages(context, config, dramas);
      }

      return PreloadResult(
        dramas: dramas,
        providers: providers,
        hasMore: response.hasMore,
      );
    } catch (_) {
      return const PreloadResult.empty();
    }
  }

  /// Best-effort image precaching. Failures are silently ignored.
  void _precacheImages(
    BuildContext context,
    AppRemoteConfig config,
    List<Drama> dramas,
  ) {
    try {
      // Precache popup image
      if (config.popupEnabled && config.popupImageUrl.isNotEmpty) {
        _precacheSingle(context, config.popupImageUrl);
      }

      // Precache first N drama thumbnails
      final covers = dramas
          .take(_maxPrecacheThumbnails)
          .map((d) => d.proxiedCover)
          .where((url) => url.isNotEmpty)
          .toList();
      for (final url in covers) {
        _precacheSingle(context, url);
      }
    } catch (_) {
      // Never crash
    }
  }

  void _precacheSingle(BuildContext context, String url) {
    try {
      precacheImage(
        CachedNetworkImageProvider(url),
        context,
      );
    } catch (_) {
      // Ignore individual image failure
    }
  }
}
