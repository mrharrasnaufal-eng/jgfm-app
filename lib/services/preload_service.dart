import 'dart:math';

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

  /// How many providers to fetch from in parallel each session.
  static const _providerSampleSize = 6;

  /// How many dramas to request per provider.
  static const _perProviderLimit = 12;

  /// Max thumbnails to precache.
  static const _maxPrecacheThumbnails = 12;

  final ApiService _api = ApiService();
  final Random _random = Random();

  /// Fetch dramas from multiple random providers, shuffle results,
  /// and precache popup + thumbnail images. Designed to run within
  /// the 5-second splash window.
  Future<PreloadResult> preload({
    required AppRemoteConfig config,
    BuildContext? context,
  }) async {
    try {
      // 1. Pick a random subset of working providers
      final shuffledProviders = List<String>.from(_workingProviders)
        ..shuffle(_random);
      final selectedProviders =
          shuffledProviders.take(_providerSampleSize).toList();

      // 2. Fetch from all selected providers in parallel
      final futures = selectedProviders.map(
        (provider) => _fetchProvider(provider),
      );
      final results = await Future.wait(futures);

      // 3. Collect all dramas and provider counts
      final allDramas = <Drama>[];
      final providerCounts = <String, int>{};
      bool hasMore = false;

      for (final result in results) {
        if (result != null) {
          allDramas.addAll(result.dramas);
          hasMore = hasMore || result.hasMore;
          result.providers.forEach((key, value) {
            if (_workingProviders.contains(key)) {
              providerCounts[key] = value;
            }
          });
        }
      }

      // 4. Deduplicate by drama ID, then shuffle for variety
      final seen = <String>{};
      final uniqueDramas = <Drama>[];
      for (final drama in allDramas) {
        if (drama.id.isNotEmpty && seen.add(drama.id)) {
          uniqueDramas.add(drama);
        }
      }
      uniqueDramas.shuffle(_random);

      // 5. Precache images in parallel (non-blocking, best-effort)
      if (context != null) {
        _precacheImages(context, config, uniqueDramas);
      }

      return PreloadResult(
        dramas: uniqueDramas,
        providers: providerCounts,
        hasMore: hasMore,
      );
    } catch (_) {
      return const PreloadResult.empty();
    }
  }

  Future<DramaListResponse?> _fetchProvider(String provider) async {
    try {
      return await _api
          .getDramas(page: 1, limit: _perProviderLimit, provider: provider)
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      return null;
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
