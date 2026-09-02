import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../models/drama.dart';
import '../models/feed_item.dart';
import '../models/watchlist_item.dart';
import '../services/api_service.dart';
import '../services/coin_service.dart';
import '../services/watchlist_service.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

/// Feed "Untuk Anda" — Reels-style: satu layar satu video (episode 1),
/// swipe atas/bawah pindah drama, 3 tombol aksi: Like / Bagikan / Daftarku.
/// Tanpa iklan (aturan: interstitial hanya di PlayerScreen).
class ForYouScreen extends StatefulWidget {
  /// Provider pilihan admin (dari remote config). Kosong = semua provider.
  final List<String> providers;

  const ForYouScreen({super.key, this.providers = const []});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  static const int _batchSize = 10;

  final ApiService _api = ApiService();
  final PageController _pageController = PageController();

  final List<FeedItem> _items = [];
  final Set<String> _seenIds = {}; // dedupe antar batch
  final Map<String, String> _streamUrls = {}; // dramaId → stream episode 1
  final Set<String> _failedIds = {}; // episode 1 tidak tersedia

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentIndex = 0;
  int _batchSeq = 0; // cegah respons lambat menimpa batch baru

  @override
  void initState() {
    super.initState();
    // Post-frame: context.read (CoinService) belum boleh dipakai saat initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final seq = ++_batchSeq;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final batch = await _fetchBatch();
      if (!mounted || seq != _batchSeq) return;
      setState(() {
        _items.clear();
        _items.addAll(batch);
        _isLoading = false;
      });
      if (_items.isNotEmpty) _ensureStream(0);
      if (_items.isEmpty) {
        setState(() => _error = 'Belum ada drama tersedia');
      }
    } catch (_) {
      if (!mounted || seq != _batchSeq) return;
      setState(() {
        _error = AppStrings.errorLoad;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    final seq = _batchSeq;
    setState(() => _isLoadingMore = true);
    try {
      final batch = await _fetchBatch();
      if (!mounted || seq != _batchSeq) return;
      setState(() {
        _items.addAll(batch);
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      // Gagal load lebih — coba lagi saat swipe berikutnya.
    }
  }

  /// Ambil batch acak dari server, buang yang sudah pernah tampil.
  Future<List<FeedItem>> _fetchBatch() async {
    final deviceId = context.read<CoinService>().deviceId;
    final batch = await _api.getRandomDramas(
      providers: widget.providers,
      limit: _batchSize,
      deviceId: deviceId,
    );
    final fresh = batch.where((f) {
      if (_seenIds.contains(f.drama.id)) return false;
      _seenIds.add(f.drama.id);
      return true;
    }).toList();
    return fresh;
  }

  // ==== Stream episode 1 ====

  Future<void> _ensureStream(int index) async {
    if (index < 0 || index >= _items.length) return;
    final id = _items[index].drama.id;
    if (_streamUrls.containsKey(id) || _failedIds.contains(id)) return;

    try {
      final stream = await _api.getStream(id, 1);
      final url = stream.bestUrl;
      if (url.isEmpty) throw ApiException('Stream kosong', 0);
      if (!mounted) return;
      setState(() => _streamUrls[id] = url);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failedIds.add(id));
      // Auto-skip: kalau halaman ini yang sedang dilihat, lanjut ke drama berikutnya.
      if (_currentIndex == index) {
        _scheduleAutoSkip(index);
      }
    }
  }

  void _scheduleAutoSkip(int index) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _currentIndex != index) return;
      _goToNext();
    });
  }

  void _goToNext() {
    if (!mounted) return;
    if (_currentIndex < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (!_isLoadingMore) {
      // Sudah di ujung — coba ambil batch lagi.
      _loadMore();
    }
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
    // Halaman loading-spinner (indeks terakhir saat load-more).
    if (index >= _items.length) {
      _loadMore();
      return;
    }
    final id = _items[index].drama.id;

    if (_failedIds.contains(id)) {
      _scheduleAutoSkip(index);
      return;
    }
    _ensureStream(index);
    _ensureStream(index + 1); // prefetch berikutnya
    if (index >= _items.length - 3) {
      _loadMore();
    }
  }

  // ==== Aksi tombol ====

  Future<void> _handleLike(int index) async {
    final item = _items[index];
    final deviceId = context.read<CoinService>().deviceId;
    if (deviceId == null || deviceId.isEmpty) return;

    final prevLiked = item.liked;
    // Optimistic update — server jawaban jadi sumber kebenaran.
    setState(() {
      item.liked = !prevLiked;
      item.likeCount += prevLiked ? -1 : 1;
    });

    try {
      final (liked, count) = await _api.toggleLike(item.drama.id, deviceId);
      if (!mounted) return;
      setState(() {
        item.liked = liked;
        item.likeCount = count;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        item.liked = prevLiked;
        item.likeCount += prevLiked ? 1 : -1;
      });
    }
  }

  Future<void> _handleShare(FeedItem item) async {
    try {
      await SharePlus.instance.share(ShareParams(
        text:
            'Nonton "${item.drama.title}" gratis di JagatFilm! 🎬\n'
            'https://jagatfilm.com/drama/${item.drama.id}',
      ));
    } catch (_) {
      // Share gagal — abaikan (opsional).
    }
  }

  void _handleWatchlist(FeedItem item) {
    final ws = context.read<WatchlistService>();
    final drama = item.drama;
    if (ws.isInWatchlist(drama.id)) {
      ws.remove(drama.id);
    } else {
      ws.add(WatchlistItem(
        dramaId: drama.id,
        title: drama.title,
        cover: drama.cover,
        genre: drama.genre,
        source: drama.source,
        totalEpisodes: drama.totalEpisodes,
      ));
    }
    setState(() {});
  }

  void _openDetail(FeedItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(drama: item.drama)),
    );
  }

  // ==== Build ====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBody(),

          // Search — kanan atas
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: AppTheme.error),
              const SizedBox(height: AppSpacing.lg),
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          AppStrings.emptyState,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2),
          );
        }
        final item = _items[index];
        return _FeedPage(
          item: item,
          isActive: index == _currentIndex,
          streamUrl: _streamUrls[item.drama.id],
          failed: _failedIds.contains(item.drama.id),
          onTapLike: () => _handleLike(index),
          onTapShare: () => _handleShare(item),
          onTapWatchlist: () => _handleWatchlist(item),
          onOpenDetail: () => _openDetail(item),
        );
      },
    );
  }
}

// ============================================================
// SATU HALAMAN FEED — video episode 1 + tombol aksi
// ============================================================
class _FeedPage extends StatefulWidget {
  final FeedItem item;
  final bool isActive;
  final String? streamUrl;
  final bool failed;
  final VoidCallback onTapLike;
  final VoidCallback onTapShare;
  final VoidCallback onTapWatchlist;
  final VoidCallback onOpenDetail;

  const _FeedPage({
    required this.item,
    required this.isActive,
    required this.streamUrl,
    required this.failed,
    required this.onTapLike,
    required this.onTapShare,
    required this.onTapWatchlist,
    required this.onOpenDetail,
  });

  @override
  State<_FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<_FeedPage> {
  VideoPlayerController? _controller;
  bool _userPaused = false;
  bool _muted = true; // auto-play tanpa suara (TikTok-style)

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant _FeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.streamUrl != widget.streamUrl) {
      _syncController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Map<String, String> _videoHeaders(String url) {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };
    if (url.contains('foshort.com')) {
      headers['Referer'] = 'https://bilitv.com/';
    } else if (url.contains('shortmax') || url.contains('reelshort')) {
      headers['Referer'] = 'https://jagatfilm.com/';
    }
    return headers;
  }

  void _syncController() {
    final url = widget.streamUrl;

    if (!widget.isActive) {
      _controller?.pause();
      return;
    }

    if (widget.failed || url == null) return;

    // Controller sudah benar untuk URL ini.
    if (_controller != null && _controller!.dataSource == url) {
      if (_controller!.value.isInitialized) {
        _controller!.play();
        setState(() => _userPaused = false);
      }
      return;
    }

    // Buat controller baru.
    _controller?.dispose();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: _videoHeaders(url),
    )
      ..setLooping(true)
      ..setVolume(_muted ? 0.0 : 1.0);
    _controller = controller;

    controller.initialize().then((_) {
      if (!mounted || !widget.isActive || _controller != controller) return;
      controller.play();
      setState(() {});
    }).catchError((_) {
      // Gagal init (video rusak) — dispose dan biarkan parent skip.
      if (!mounted) return;
      _controller?.dispose();
      _controller = null;
      setState(() {});
    });
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      _userPaused = !_userPaused;
    });
    _userPaused ? c.pause() : c.play();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final drama = widget.item.drama;
    final ws = context.watch<WatchlistService>();
    final saved = ws.isInWatchlist(drama.id);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideo(),

          // Tap area: pause/resume
          GestureDetector(
            onTap: _togglePlay,
            behavior: HitTestBehavior.translucent,
          ),

          // Overlay pause icon
          if (_userPaused)
            const Center(
              child: Icon(
                Icons.pause_circle_filled_rounded,
                color: Colors.white70,
                size: 64,
              ),
            ),

          // Info kiri bawah (judul → detail)
          Positioned(
            left: 12,
            right: 84,
            bottom: 28,
            child: _buildInfo(drama),
          ),

          // Tombol aksi kanan bawah
          Positioned(
            right: 8,
            bottom: 110,
            child: _buildActions(saved),
          ),

          // Tombol mute/unmute (kanan atas)
          Positioned(
            top: 16,
            right: 12,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Gagal: pesan + auto skip
          if (widget.failed)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off_rounded,
                        color: Colors.white70, size: 36),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Video tidak tersedia\nMelanjutkan...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: VideoPlayer(c),
        ),
      );
    }
    if (widget.failed) return const SizedBox.shrink();
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
    );
  }

  Widget _buildInfo(Drama drama) {
    final genreText = drama.genres.isNotEmpty
        ? drama.genres.first
        : drama.genre.isNotEmpty
            ? drama.genre
            : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gradient latar teks
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC000000)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onOpenDetail,
                child: Text(
                  drama.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSize.h3,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (genreText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        genreText,
                        style: const TextStyle(
                          fontSize: AppFontSize.micro,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (genreText.isNotEmpty) const SizedBox(width: 6),
                  Text(
                    'Episode 1/${drama.totalEpisodes > 0 ? drama.totalEpisodes : '?'}',
                    style: const TextStyle(
                      fontSize: AppFontSize.micro,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool saved) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _ActionButton(
          icon: widget.item.liked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: widget.item.liked ? AppTheme.accent : Colors.white,
          label: widget.item.likeCount > 0
              ? formatViews(widget.item.likeCount)
              : '',
          onTap: widget.onTapLike,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Bagikan
        _ActionButton(
          icon: Icons.share_rounded,
          color: Colors.white,
          label: '',
          onTap: widget.onTapShare,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Daftarku
        _ActionButton(
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: saved ? AppTheme.gold : Colors.white,
          label: saved ? 'Tersimpan' : 'Daftarku',
          onTap: widget.onTapWatchlist,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
