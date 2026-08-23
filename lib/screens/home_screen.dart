import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import '../services/preload_service.dart';
import '../widgets/drama_card.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String logoUrl;
  final String announcement;
  final PreloadResult? preloadedDramas;

  const HomeScreen({
    super.key,
    this.logoUrl = '',
    this.announcement = '',
    this.preloadedDramas,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Drama> _dramas = [];
  List<Drama> _featuredDramas = [];
  Map<String, int> _providers = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _selectedProvider = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Use preloaded data if available, otherwise fetch normally
    final preload = widget.preloadedDramas;
    if (preload != null && !preload.isEmpty) {
      _dramas = List.from(preload.dramas);
      _featuredDramas = _dramas.take(5).toList();
      _providers = Map.from(preload.providers);
      _providers.removeWhere((key, _) => !_workingProviders.contains(key));
      _hasMore = preload.hasMore;
      _isLoading = false;
    } else {
      _loadDramas();
    }
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

  // Provider yang video streaming-nya terbukti berfungsi
  static const _workingProviders = [
    'shortmax', 'cashdrama', 'netshort', 'rapidtv', 'bilitv',
    'flickreels', 'melolo', 'wetv', 'dramabite', 'reelshort',
    'microdrama', 'dotdrama', 'dramabox', 'starshort',
  ];

  Future<void> _loadDramas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_selectedProvider == 'all') {
        // Mix multiple providers in parallel and shuffle
        final shuffled = List<String>.from(_workingProviders)..shuffle();
        final selected = shuffled.take(6).toList();

        final futures = selected.map(
          (p) => _api
              .getDramas(page: 1, limit: 12, provider: p)
              .timeout(const Duration(seconds: 4))
              .catchError((_) => DramaListResponse(
                    dramas: [],
                    page: 1,
                    totalPages: 1,
                    total: 0,
                    hasMore: false,
                    providers: {},
                  )),
        );
        final results = await Future.wait(futures);

        final allDramas = <Drama>[];
        final allProviders = <String, int>{};
        bool hasMore = false;
        for (final r in results) {
          allDramas.addAll(r.dramas);
          hasMore = hasMore || r.hasMore;
          r.providers.forEach((k, v) {
            if (_workingProviders.contains(k)) allProviders[k] = v;
          });
        }

        // Deduplicate and shuffle
        final seen = <String>{};
        final unique = <Drama>[];
        for (final d in allDramas) {
          if (d.id.isNotEmpty && seen.add(d.id)) unique.add(d);
        }
        unique.shuffle();

        setState(() {
          _dramas = unique;
          _featuredDramas = unique.take(5).toList();
          _providers = allProviders;
          _hasMore = hasMore;
          _currentPage = 1;
          _isLoading = false;
        });
      } else {
        // Single provider mode
        final response = await _api.getDramas(
          page: 1,
          limit: 30,
          provider: _selectedProvider,
        );

        setState(() {
          _dramas = response.dramas;
          _featuredDramas = response.dramas.take(5).toList();
          _providers = response.providers;
          _providers.removeWhere((key, _) => !_workingProviders.contains(key));
          _hasMore = response.hasMore;
          _currentPage = 1;
          _isLoading = false;
        });
      }
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
      String providerParam = _selectedProvider;
      if (_selectedProvider == 'all') providerParam = 'shortmax';

      final response = await _api.getDramas(
        page: _currentPage + 1,
        limit: 30,
        provider: providerParam,
      );
      setState(() {
        _dramas.addAll(response.dramas);
        _hasMore = response.hasMore;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onProviderChanged(String provider) {
    setState(() {
      _selectedProvider = provider;
      _dramas = [];
      _currentPage = 1;
    });
    _loadDramas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDramas,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              title: Row(
                children: [
                  _buildBrandLogo(),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'JagatFilm',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.system_update_rounded, color: Colors.white70),
                  tooltip: 'Cek Pembaruan',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UpdateScreen()),
                    );
                  },
                ),
              ],
            ),
            if (widget.announcement.isNotEmpty)
              SliverToBoxAdapter(child: _buildAnnouncement()),
            if (_featuredDramas.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildFeaturedSlider(),
              ),

            // Provider Filter
            if (_providers.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildProviderFilter(),
              ),

            // Loading
            if (_isLoading)
              SliverToBoxAdapter(child: _buildLoadingGrid()),

            // Error
            if (_error != null && !_isLoading)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Gagal memuat data',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadDramas,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Drama Grid
            if (!_isLoading && _error == null)
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final drama = _dramas[index];
                      return DramaCard(
                        drama: drama,
                        onTap: () => _navigateToDetail(drama),
                      );
                    },
                    childCount: _dramas.length,
                  ),
                ),
              ),

            // Loading More Indicator
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandLogo() {
    if (widget.logoUrl.isEmpty) {
      return Icon(
        Icons.movie_filter_rounded,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Image.network(
          widget.logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.movie_filter_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncement() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withAlpha(28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.campaign_rounded,
            color: Color(0xFF9C94FF),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              widget.announcement,
              style: TextStyle(
                color: Colors.grey[200],
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSlider() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: _featuredDramas.length,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (context, index) {
          final drama = _featuredDramas[index];
          return GestureDetector(
            onTap: () => _navigateToDetail(drama),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: drama.proxiedCoverHorizontal,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[800],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    // Title
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drama.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${drama.totalEpisodes} Episode • ${drama.source}',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderFilter() {
    // Sort providers by count
    final sorted = _providers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topProviders = sorted.take(10).toList();

    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildFilterChip('Semua', 'all'),
          ...topProviders.map((e) => _buildFilterChip(
                '${e.key} (${e.value})',
                e.key,
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedProvider == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[300],
          ),
        ),
        selected: isSelected,
        onSelected: (_) => _onProviderChanged(value),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[700]!,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.55,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(Drama drama) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(drama: drama),
      ),
    );
  }
}
