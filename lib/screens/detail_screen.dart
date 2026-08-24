import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/drama.dart';
import '../models/watchlist_item.dart';
import '../services/api_service.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class DetailScreen extends StatefulWidget {
  final Drama drama;

  const DetailScreen({super.key, required this.drama});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ApiService _api = ApiService();
  List<EpisodeInfo> _episodes = [];
  bool _isLoading = true;
  bool _descExpanded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch real episode list from API
      final uri = Uri.parse(
          '${ApiService.baseUrl}/api/drama/detail?id=${widget.drama.id}');
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'JagatFilm-Android/2.0',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final episodeList = data['episodes'] as List<dynamic>? ?? [];

          if (episodeList.isNotEmpty) {
            final episodes = episodeList.map((ep) => EpisodeInfo(
              id: ep['id']?.toString() ?? '',
              number: ep['number'] as int? ?? 0,
              title: ep['title']?.toString() ?? 'Episode ${ep['number']}',
            )).toList();

            setState(() {
              _episodes = episodes;
              _isLoading = false;
            });
            return;
          }
        }
      }

      // Fallback: generate episodes from totalEpisodes
      _fallbackEpisodes();
    } catch (e) {
      // On network error, fallback to generated list
      _fallbackEpisodes();
    }
  }

  void _fallbackEpisodes() {
    int total = widget.drama.totalEpisodes;
    if (total <= 0) {
      total = 300; // Conservative high default — player will handle if episode doesn't exist
    }

    final episodes = <EpisodeInfo>[];
    for (int i = 1; i <= total; i++) {
      episodes.add(EpisodeInfo(
        id: i.toString(),
        number: i,
        title: 'Episode $i',
      ));
    }

    setState(() {
      _episodes = episodes;
      _isLoading = false;
    });
  }

  void _playEpisode(EpisodeInfo episode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          drama: widget.drama,
          episode: episode,
          totalEpisodes: _episodes.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drama = widget.drama;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: drama.proxiedCoverHorizontal,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[900]),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: CachedNetworkImage(
                        imageUrl: drama.proxiedCover,
                        fit: BoxFit.cover,
                      ),
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
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Play button overlay
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: _episodes.isNotEmpty
                            ? () => _playEpisode(_episodes.first)
                            : null,
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: const Text('Tonton Sekarang',
                            style: TextStyle(fontSize: 16)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    drama.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Meta info
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildMetaChip(Icons.movie_outlined,
                          '${drama.totalEpisodes} Ep'),
                      _buildMetaChip(Icons.source_outlined, drama.source),
                      if (drama.genres.isNotEmpty)
                        _buildMetaChip(
                            Icons.category_outlined, drama.genres.first),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Watchlist button
                  _buildWatchlistButton(context),
                  const SizedBox(height: 16),

                  // Genres
                  if (drama.genres.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: drama.genres
                          .map((g) => Chip(
                                label: Text(g,
                                    style: const TextStyle(fontSize: 11)),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: const Color(0xFF2A2A3E),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 16),

                  // Description
                  if (drama.description.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Text(
                        drama.description,
                        maxLines: _descExpanded ? null : 3,
                        overflow: _descExpanded ? null : TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (drama.description.length > 100)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _descExpanded = !_descExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _descExpanded ? 'Sembunyikan' : 'Selengkapnya...',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // Episode header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daftar Episode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_episodes.length} episode',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Episode List
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          if (_error != null)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error: $_error',
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),

          if (!_isLoading && _error == null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = _episodes[index];
                  return _buildEpisodeItem(episode);
                },
                childCount: _episodes.length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildWatchlistButton(BuildContext context) {
    return Consumer<WatchlistService>(
      builder: (context, watchlistService, _) {
        final isInWatchlist = watchlistService.isInWatchlist(widget.drama.id);

        return Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                if (isInWatchlist) {
                  watchlistService.remove(widget.drama.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dihapus dari Daftarku'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  watchlistService.add(WatchlistItem(
                    dramaId: widget.drama.id,
                    title: widget.drama.title,
                    cover: widget.drama.cover,
                    genre: widget.drama.genre,
                    source: widget.drama.source,
                    totalEpisodes: widget.drama.totalEpisodes,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ditambahkan ke Daftarku'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: Icon(
                isInWatchlist
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 18,
              ),
              label: Text(isInWatchlist ? 'Di Daftarku' : 'Simpan'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isInWatchlist ? AppTheme.accent : AppTheme.textSecondary,
                side: BorderSide(
                  color: isInWatchlist
                      ? AppTheme.accent.withOpacity(0.5)
                      : AppTheme.divider,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildEpisodeItem(EpisodeInfo episode) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${episode.number}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      title: Text(
        episode.title,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: episode.duration != null
          ? Text('${episode.duration} menit',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: Icon(
        Icons.play_circle_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => _playEpisode(episode),
    );
  }
}
