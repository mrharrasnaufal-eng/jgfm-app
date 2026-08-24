import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/drama.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/drama_card_grid.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_grid.dart';
import '../detail_screen.dart';

class UntukmuTab extends StatefulWidget {
  const UntukmuTab({super.key});

  @override
  State<UntukmuTab> createState() => _UntukmuTabState();
}

class _UntukmuTabState extends State<UntukmuTab>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Drama> _dramas = [];
  Map<String, int> _viewCounts = {};
  Map<String, int> _providers = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
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
        _api.getDramas(page: 1, limit: 30, provider: 'shortmax'),
        _fetchPopularStats(),
      ]);

      final response = results[0] as DramaListResponse;
      final stats = results[1] as Map<String, int>;

      if (!mounted) return;
      setState(() {
        _dramas = response.dramas;
        _viewCounts = stats;
        _providers = response.providers;
        _hasMore = response.hasMore;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Map<String, int>> _fetchPopularStats() async {
    try {
      final uri = Uri.parse(
          '${ApiService.baseUrl}/api/dramas/popular?limit=50&page=1');
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'JagatFilm-Android/1.0',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List<dynamic>? ?? [];
        final stats = <String, int>{};
        for (final item in data) {
          final id = item['drama_id']?.toString() ?? '';
          final views = item['view_count'] as int? ?? 0;
          if (id.isNotEmpty) {
            stats[id] = views;
          }
        }
        return stats;
      }
    } catch (_) {
      // Non-critical — view counts are optional
    }
    return {};
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final response = await _api.getDramas(
        page: _currentPage + 1,
        limit: 30,
        provider: 'shortmax',
      );

      if (!mounted) return;
      setState(() {
        _dramas.addAll(response.dramas);
        _hasMore = response.hasMore;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitial();
  }

  void _navigateToDetail(Drama drama) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DetailScreen(drama: drama),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Dramas for the main 3-column grid (first 9).
  List<Drama> get _gridDramas =>
      _dramas.length > 9 ? _dramas.sublist(0, 9) : _dramas;

  /// Dramas for masonry section (after first 9).
  List<Drama> get _masonryDramas =>
      _dramas.length > 9 ? _dramas.sublist(9) : [];

  /// Unique genres from loaded dramas.
  List<String> get _genres {
    final genres = <String>{};
    for (final d in _dramas) {
      if (d.genre.isNotEmpty) genres.add(d.genre);
      for (final g in d.genres) {
        if (g.isNotEmpty) genres.add(g);
      }
    }
    return genres.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const ShimmerGrid(columns: 3, rows: 4);
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accent,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // === Section A: 3-column grid (popular) ===
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.52,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final drama = _gridDramas[index];
                  return DramaCardGrid(
                    drama: drama,
                    viewCount: _viewCounts[drama.id],
                    onTap: () => _navigateToDetail(drama),
                  );
                },
                childCount: _gridDramas.length,
              ),
            ),
          ),

          // === Provider Spotlight (horizontal scroll) ===
          if (_providers.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SectionHeader(
                  title: 'Jelajahi Provider',
                  onSeeAll: null,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildProviderSpotlight(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],

          // === Section B: Masonry "Rekomendasi Populer" ===
          if (_masonryDramas.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SectionHeader(
                  title: 'Rekomendasi Populer',
                  onSeeAll: null,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildMasonrySection(),
            ),
          ],

          // Loading more
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
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
              ),
            ),
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }

  /// Horizontal scroll provider cards.
  Widget _buildProviderSpotlight() {
    final entries = _providers.entries.toList();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _ProviderCard(
            name: entry.key,
            count: entry.value,
            onTap: () {
              // Could navigate to KategoriTab filtered by provider
            },
          );
        },
      ),
    );
  }

  /// Masonry 2-column staggered grid with genre blocks.
  Widget _buildMasonrySection() {
    // Insert genre block every 6 items
    final items = <_MasonryItem>[];
    int genreIndex = 0;

    for (int i = 0; i < _masonryDramas.length; i++) {
      // Insert genre block every 6 cards
      if (i > 0 && i % 6 == 0 && genreIndex < _genres.length) {
        final genreName = _genres[genreIndex];
        final genreDramas = _dramas
            .where((d) =>
                d.genre == genreName || d.genres.contains(genreName))
            .take(4)
            .toList();
        items.add(_MasonryItem.genre(genreName, genreDramas));
        genreIndex++;
      }
      items.add(_MasonryItem.drama(_masonryDramas[i]));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: MasonryGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isGenreBlock) {
            return _GenreBlock(
              genre: item.genreName!,
              dramas: item.genreDramas!,
              onTap: () {},
            );
          }
          // Staggered heights
          final heights = [220.0, 260.0, 200.0, 240.0];
          final height = heights[index % heights.length];
          return _MasonryCard(
            drama: item.drama!,
            height: height,
            viewCount: _viewCounts[item.drama!.id],
            onTap: () => _navigateToDetail(item.drama!),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              AppStrings.errorLoad,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppFontSize.h3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: AppFontSize.caption,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(AppStrings.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === Data class for masonry items ===
class _MasonryItem {
  final Drama? drama;
  final String? genreName;
  final List<Drama>? genreDramas;
  final bool isGenreBlock;

  _MasonryItem.drama(this.drama)
      : genreName = null,
        genreDramas = null,
        isGenreBlock = false;

  _MasonryItem.genre(this.genreName, this.genreDramas)
      : drama = null,
        isGenreBlock = true;
}

// === Masonry Card ===
class _MasonryCard extends StatelessWidget {
  final Drama drama;
  final double height;
  final int? viewCount;
  final VoidCallback onTap;

  const _MasonryCard({
    required this.drama,
    required this.height,
    this.viewCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster
              CachedNetworkImage(
                imageUrl: drama.proxiedCover,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.card),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.card,
                  child: const Icon(Icons.movie_rounded,
                      color: AppTheme.textTertiary),
                ),
              ),
              // Gradient overlay bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: height * 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Views badge top-right
              if (viewCount != null && viewCount! > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded,
                            size: 10, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          formatViews(viewCount!),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Title and genre bottom
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drama.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (drama.genre.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        drama.genre,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: AppFontSize.micro,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === Genre Block ===
class _GenreBlock extends StatelessWidget {
  final String genre;
  final List<Drama> dramas;
  final VoidCallback onTap;

  const _GenreBlock({
    required this.genre,
    required this.dramas,
    required this.onTap,
  });

  // Genre color map
  static final _genreColors = {
    'Romansa': const Color(0xFF8B0000),
    'Aksi': const Color(0xFF1A237E),
    'Komedi': const Color(0xFFE65100),
    'Thriller': const Color(0xFF1B5E20),
    'Horror': const Color(0xFF4A148C),
    'Drama': const Color(0xFF0D47A1),
    'Fantasi': const Color(0xFF4527A0),
    'Misteri': const Color(0xFF263238),
  };

  @override
  Widget build(BuildContext context) {
    final bgColor = _genreColors[genre] ?? const Color(0xFF2D1B3D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor, bgColor.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    genre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // 2x2 mini thumbnails
            if (dramas.isNotEmpty)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.75,
                children: dramas.take(4).map((d) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: d.proxiedCover,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.black26),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.black26),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// === Provider Card ===
class _ProviderCard extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.name,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_filled_rounded,
                color: AppTheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$count drama',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: AppFontSize.micro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
