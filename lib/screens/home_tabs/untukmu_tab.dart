import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/drama.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/drama_card_grid.dart';
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
      MaterialPageRoute(
        builder: (_) => DetailScreen(drama: drama),
      ),
    );
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
                  final drama = _dramas[index];
                  return DramaCardGrid(
                    drama: drama,
                    viewCount: _viewCounts[drama.id],
                    onTap: () => _navigateToDetail(drama),
                  );
                },
                childCount: _dramas.length,
              ),
            ),
          ),
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
