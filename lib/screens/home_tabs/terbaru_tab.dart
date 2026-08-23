import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/drama.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/badge_pill.dart';
import '../detail_screen.dart';

class TerbaruTab extends StatefulWidget {
  const TerbaruTab({super.key});

  @override
  State<TerbaruTab> createState() => _TerbaruTabState();
}

class _TerbaruTabState extends State<TerbaruTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  List<_NewestDrama> _dramas = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  static const int _limit = 30;

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

  Future<List<_NewestDrama>> _fetchNewest(int page) async {
    final uri = Uri.parse(
        '${ApiService.baseUrl}/api/dramas/newest?limit=$_limit&page=$page');
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'User-Agent': 'JagatFilm-Android/1.0',
    });

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    _hasMore = pagination['hasMore'] == true;

    return data.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value as Map<String, dynamic>;
      return _NewestDrama(
        dramaId: item['drama_id']?.toString() ?? '',
        title: item['title']?.toString() ?? '',
        source: item['source']?.toString() ?? '',
        genre: item['genre']?.toString() ?? '',
        cover: item['cover']?.toString() ?? '',
        viewCount: item['view_count'] as int? ?? 0,
        rank: i + 1 + (page - 1) * _limit,
      );
    }).toList();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dramas = await _fetchNewest(1);
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
    setState(() => _isLoadingMore = true);

    try {
      final dramas = await _fetchNewest(_currentPage + 1);
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
    await _loadInitial();
  }

  void _navigateToDetail(_NewestDrama item) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
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
          return _buildDramaItem(_dramas[index]);
        },
      ),
    );
  }

  Widget _buildDramaItem(_NewestDrama item) {
    return InkWell(
      onTap: () => _navigateToDetail(item),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.proxiedCover,
                width: 72,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 72,
                  height: 100,
                  color: AppTheme.card,
                  child: const Icon(
                    Icons.movie_outlined,
                    color: AppTheme.textTertiary,
                    size: 24,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 72,
                  height: 100,
                  color: AppTheme.card,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textTertiary,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Genre as subtitle
                    Text(
                      item.genre.isNotEmpty ? item.genre : item.source,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    // Badge + views
                    Row(
                      children: [
                        BadgePill(
                          text: 'TOP ${item.rank}',
                          color: AppTheme.accent,
                          icon: Icons.fiber_new_rounded,
                        ),
                        const Spacer(),
                        if (item.viewCount > 0) ...[
                          const Icon(
                            Icons.visibility_outlined,
                            size: 12,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            formatViews(item.viewCount),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(8),
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
                        width: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
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

/// Internal model for newest endpoint data
class _NewestDrama {
  final String dramaId;
  final String title;
  final String source;
  final String genre;
  final String cover;
  final int viewCount;
  final int rank;

  const _NewestDrama({
    required this.dramaId,
    required this.title,
    required this.source,
    required this.genre,
    required this.cover,
    required this.viewCount,
    required this.rank,
  });

  String get proxiedCover {
    if (cover.isEmpty) return '';
    return 'https://jagatfilm.com/api/img?url=${Uri.encodeComponent(cover)}';
  }
}
