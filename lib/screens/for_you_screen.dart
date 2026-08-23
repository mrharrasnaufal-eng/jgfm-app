import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import '../widgets/badge_pill.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Drama> _dramas = [];
  Map<String, int> _viewCounts = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getDramas(page: 1, limit: 20),
        _fetchPopularViewCounts(),
      ]);

      final response = results[0] as DramaListResponse;
      final viewCounts = results[1] as Map<String, int>;

      // Exclude broken providers
      const brokenProviders = {'flickshort', 'fundrama', 'vigloo', 'dramanova'};
      final dramas = response.dramas
          .where((d) => !brokenProviders.contains(d.source))
          .toList();
      dramas.shuffle(Random());

      setState(() {
        _dramas = dramas;
        _viewCounts = viewCounts;
        _hasMore = response.hasMore;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await _api.getDramas(page: _currentPage + 1, limit: 20);
      final dramas = response.dramas
          .where((d) => !const {'flickshort', 'fundrama', 'vigloo', 'dramanova'}.contains(d.source))
          .toList();
      dramas.shuffle(Random());

      setState(() {
        _dramas.addAll(dramas);
        _currentPage++;
        _hasMore = response.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<Map<String, int>> _fetchPopularViewCounts() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/dramas/popular?limit=30');
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'JagatFilm-Android/1.0',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null) {
          final Map<String, int> counts = {};
          for (final item in json['data'] as List) {
            final dramaId = item['drama_id']?.toString() ?? '';
            final viewCount = item['view_count'] is int
                ? item['view_count'] as int
                : int.tryParse(item['view_count']?.toString() ?? '0') ?? 0;
            if (dramaId.isNotEmpty) {
              counts[dramaId] = viewCount;
            }
          }
          return counts;
        }
      }
    } catch (_) {}
    return {};
  }

  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Untuk Anda',
          style: TextStyle(
            fontSize: AppFontSize.h2,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmer();
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        itemCount: _dramas.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _dramas.length) {
            return _buildLoadingIndicator();
          }
          return _buildDramaCard(_dramas[index]);
        },
      ),
    );
  }

  Widget _buildDramaCard(Drama drama) {
    final viewCount = _viewCounts[drama.id];
    final genreText = drama.genres.isNotEmpty
        ? drama.genres.first
        : drama.genre.isNotEmpty
            ? drama.genre
            : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(drama: drama)),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                CachedNetworkImage(
                  imageUrl: drama.proxiedCover,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.card,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.card,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppTheme.textTertiary,
                      size: 40,
                    ),
                  ),
                ),

                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xB3000000), // black 70%
                        ],
                      ),
                    ),
                  ),
                ),

                // Source badge — top right
                if (drama.source.isNotEmpty)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: BadgePill(
                      text: drama.source,
                      color: AppTheme.secondary.withOpacity(0.85),
                    ),
                  ),

                // Bottom overlay text
                Positioned(
                  bottom: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        drama.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppFontSize.h3,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Genre pill + view count row
                      Row(
                        children: [
                          if (genreText.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                genreText,
                                style: const TextStyle(
                                  fontSize: AppFontSize.micro,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          if (genreText.isNotEmpty)
                            const SizedBox(width: AppSpacing.sm),
                          if (viewCount != null && viewCount > 0) ...[
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatViews(viewCount),
                              style: const TextStyle(
                                fontSize: AppFontSize.caption,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Shimmer.fromColors(
        baseColor: AppTheme.card,
        highlightColor: AppTheme.surface,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              AppStrings.errorLoad,
              style: TextStyle(
                fontSize: AppFontSize.h3,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.body,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppStrings.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }
}
