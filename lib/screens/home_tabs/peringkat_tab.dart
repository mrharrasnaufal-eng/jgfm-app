import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/drama.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/badge_pill.dart';
import '../../widgets/filter_pills.dart';
import '../detail_screen.dart';

class PeringkatTab extends StatefulWidget {
  const PeringkatTab({super.key});

  @override
  State<PeringkatTab> createState() => _PeringkatTabState();
}

class _PeringkatTabState extends State<PeringkatTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  static const List<String> _filters = ['Sedang Tren', 'Terpopuler', 'Terbaru'];
  int _selectedFilter = 0;

  List<_RankedDrama> _dramas = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  static const int _limit = 30;

  // Colors for top 3 ranks
  static const Color _goldColor = Color(0xFFFFD700);
  static const Color _silverColor = Color(0xFFC0C0C0);
  static const Color _bronzeColor = Color(0xFFCD7F32);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
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

  void _onFilterChanged(int index) {
    if (index == _selectedFilter) return;
    setState(() {
      _selectedFilter = index;
      _dramas = [];
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    });
    _loadData();
  }

  String _buildUrl(int page) {
    switch (_selectedFilter) {
      case 0: // Sedang Tren
        return '${ApiService.baseUrl}/api/dramas/trending?days=7&limit=$_limit';
      case 1: // Terpopuler
        return '${ApiService.baseUrl}/api/dramas/popular?limit=$_limit&page=$page';
      case 2: // Terbaru
        return '${ApiService.baseUrl}/api/dramas/newest?limit=$_limit&page=$page';
      default:
        return '${ApiService.baseUrl}/api/dramas/trending?days=7&limit=$_limit';
    }
  }

  Future<Map<String, dynamic>> _fetchUrl(String url) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'User-Agent': 'JagatFilm-Android/1.0',
    });

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<_RankedDrama> _parseResponse(Map<String, dynamic> json, int page) {
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    _hasMore = pagination['hasMore'] == true;

    return data.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value as Map<String, dynamic>;

      // Determine views based on endpoint
      int views;
      if (_selectedFilter == 0) {
        views = item['trending_views'] as int? ?? item['total_views'] as int? ?? 0;
      } else {
        views = item['view_count'] as int? ?? 0;
      }

      // Use rank from API if available, otherwise calculate
      final apiRank = item['rank'] as int?;
      final rank = apiRank ?? (i + 1 + (page - 1) * _limit);

      return _RankedDrama(
        dramaId: item['drama_id']?.toString() ?? '',
        title: item['title']?.toString() ?? '',
        source: item['source']?.toString() ?? '',
        genre: item['genre']?.toString() ?? '',
        cover: item['cover']?.toString() ?? '',
        views: views,
        rank: rank,
      );
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = _buildUrl(1);
      final json = await _fetchUrl(url);
      final dramas = _parseResponse(json, 1);

      if (!mounted) return;
      setState(() {
        _dramas = dramas;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    // Trending endpoint doesn't support pagination
    if (_selectedFilter == 0) return;

    setState(() => _isLoadingMore = true);

    try {
      final url = _buildUrl(_currentPage + 1);
      final json = await _fetchUrl(url);
      final dramas = _parseResponse(json, _currentPage + 1);

      if (!mounted) return;
      setState(() {
        _dramas.addAll(dramas);
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _navigateToDetail(_RankedDrama item) {
    final drama = Drama(
      id: item.dramaId,
      title: item.title,
      cover: item.cover,
      description: '',
      genre: item.genre,
      genres: item.genre.isNotEmpty ? [item.genre] : [],
      tags: [],
      totalEpisodes: 0,
      source: item.source,
      sourceId: item.dramaId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(drama: drama)),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return _goldColor;
      case 2:
        return _silverColor;
      case 3:
        return _bronzeColor;
      default:
        return AppTheme.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        // Filter pills
        FilterPills(
          items: _filters,
          selectedIndex: _selectedFilter,
          onSelected: _onFilterChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmer();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accent,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _dramas.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _dramas.length) {
            return const Padding(
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
            );
          }
          return _buildRankItem(_dramas[index]);
        },
      ),
    );
  }

  Widget _buildRankItem(_RankedDrama item) {
    final isTop1 = item.rank == 1;

    return InkWell(
      onTap: () => _navigateToDetail(item),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isTop1 ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: isTop1
              ? Border.all(color: AppTheme.accent.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 36,
              child: Text(
                '${item.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.h1,
                  fontWeight: FontWeight.bold,
                  color: _rankColor(item.rank),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: item.proxiedCover,
                width: 50,
                height: 65,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 50,
                  height: 65,
                  color: AppTheme.card,
                  child: const Icon(
                    Icons.movie_outlined,
                    color: AppTheme.textTertiary,
                    size: 18,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 50,
                  height: 65,
                  color: AppTheme.card,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textTertiary,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + genre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.genre.isNotEmpty ? item.genre : item.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Views
            if (item.views > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: AppTheme.trending,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatViews(item.views),
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(8, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 50,
                  height: 65,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
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
              onPressed: _loadData,
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

/// Internal model for ranked drama data
class _RankedDrama {
  final String dramaId;
  final String title;
  final String source;
  final String genre;
  final String cover;
  final int views;
  final int rank;

  const _RankedDrama({
    required this.dramaId,
    required this.title,
    required this.source,
    required this.genre,
    required this.cover,
    required this.views,
    required this.rank,
  });

  String get proxiedCover {
    if (cover.isEmpty) return '';
    return 'https://jagatfilm.com/api/img?url=${Uri.encodeComponent(cover)}';
  }
}
