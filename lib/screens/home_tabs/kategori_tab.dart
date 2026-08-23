import 'package:flutter/material.dart';
import '../../models/drama.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/drama_card_grid.dart';
import '../../widgets/filter_pills.dart';
import '../../widgets/shimmer_grid.dart';
import '../detail_screen.dart';

class KategoriTab extends StatefulWidget {
  const KategoriTab({super.key});

  @override
  State<KategoriTab> createState() => _KategoriTabState();
}

class _KategoriTabState extends State<KategoriTab>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  // Filter state
  List<String> _providerItems = [AppStrings.allProvider];
  int _selectedProviderIndex = 0;
  int _selectedGenreIndex = 0;
  int _selectedSortIndex = 0;

  // Data state
  List<Drama> _allDramas = [];
  List<Drama> _filteredDramas = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  static const List<String> _genres = [
    'Semua',
    'Romance',
    'Drama',
    'Action',
    'Fantasy',
    'Comedy',
    'Thriller',
    'Horror',
  ];

  static const List<String> _sortOptions = [
    AppStrings.sortPopular,
    AppStrings.sortNewest,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDramas();
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

  String get _selectedProvider {
    if (_selectedProviderIndex == 0) return 'all';
    // Remove count suffix from provider name if present
    final raw = _providerItems[_selectedProviderIndex];
    final parenIdx = raw.lastIndexOf(' (');
    return parenIdx > 0 ? raw.substring(0, parenIdx) : raw;
  }

  Future<void> _loadDramas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.getDramas(
        page: 1,
        limit: 30,
        provider: _selectedProvider,
      );

      if (!mounted) return;

      // Build provider list from response
      final providers = response.providers.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final providerNames = providers
          .take(12)
          .map((e) => '${e.key} (${e.value})')
          .toList();

      setState(() {
        _providerItems = [AppStrings.allProvider, ...providerNames];
        _allDramas = response.dramas;
        _hasMore = response.hasMore;
        _currentPage = 1;
        _isLoading = false;
        _applyFilters();
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
      final response = await _api.getDramas(
        page: _currentPage + 1,
        limit: 30,
        provider: _selectedProvider,
      );

      if (!mounted) return;
      setState(() {
        _allDramas.addAll(response.dramas);
        _hasMore = response.hasMore;
        _currentPage++;
        _isLoadingMore = false;
        _applyFilters();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _applyFilters() {
    List<Drama> result = List.from(_allDramas);

    // Genre filter (client-side)
    if (_selectedGenreIndex > 0) {
      final genre = _genres[_selectedGenreIndex].toLowerCase();
      result = result.where((d) {
        // Check genres list
        if (d.genres.any((g) => g.toLowerCase().contains(genre))) return true;
        // Check single genre field
        if (d.genre.toLowerCase().contains(genre)) return true;
        return false;
      }).toList();
    }

    // Sort
    if (_selectedSortIndex == 1) {
      // 'Terbaru' — fewer episodes likely newer
      result.sort((a, b) => a.totalEpisodes.compareTo(b.totalEpisodes));
    }
    // 'Terpopuler' keeps default order from API

    _filteredDramas = result;
  }

  void _onProviderChanged(int index) {
    if (index == _selectedProviderIndex) return;
    setState(() {
      _selectedProviderIndex = index;
      _allDramas = [];
      _filteredDramas = [];
      _currentPage = 1;
    });
    _loadDramas();
  }

  void _onGenreChanged(int index) {
    if (index == _selectedGenreIndex) return;
    setState(() {
      _selectedGenreIndex = index;
      _applyFilters();
    });
  }

  void _onSortChanged(int index) {
    if (index == _selectedSortIndex) return;
    setState(() {
      _selectedSortIndex = index;
      _applyFilters();
    });
  }

  Future<void> _onRefresh() async {
    await _loadDramas();
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

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accent,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                // Provider filter
                FilterPills(
                  items: _providerItems,
                  selectedIndex: _selectedProviderIndex,
                  onSelected: _onProviderChanged,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Genre filter
                FilterPills(
                  items: _genres,
                  selectedIndex: _selectedGenreIndex,
                  onSelected: _onGenreChanged,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Sort filter
                FilterPills(
                  items: _sortOptions,
                  selectedIndex: _selectedSortIndex,
                  onSelected: _onSortChanged,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),

          // Loading
          if (_isLoading)
            const SliverToBoxAdapter(
              child: ShimmerGrid(columns: 3, rows: 4),
            ),

          // Error
          if (_error != null && !_isLoading)
            SliverFillRemaining(child: _buildErrorState()),

          // Grid
          if (!_isLoading && _error == null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: _filteredDramas.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.52,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final drama = _filteredDramas[index];
                          return DramaCardGrid(
                            drama: drama,
                            onTap: () => _navigateToDetail(drama),
                          );
                        },
                        childCount: _filteredDramas.length,
                      ),
                    ),
            ),

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
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _loadDramas,
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl * 2),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.movie_filter_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Tidak ada drama untuk filter ini',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppFontSize.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
