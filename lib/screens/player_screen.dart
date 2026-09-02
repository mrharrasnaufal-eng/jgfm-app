import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/drama.dart';
import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/watchlist_service.dart';

class PlayerScreen extends StatefulWidget {
  final Drama drama;
  final EpisodeInfo episode;
  final int totalEpisodes;

  const PlayerScreen({
    super.key,
    required this.drama,
    required this.episode,
    required this.totalEpisodes,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final ApiService _api = ApiService();
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String? _error;
  String _rawHdUrl = '';
  String _rawSdUrl = '';
  // Prefetch stream URL episode berikutnya — navigasi episode terasa instan.
  final Map<int, StreamData> _prefetchCache = {};
  int _currentEpisode = 1;
  bool _isHD = true;
  bool _showOverlay = true;
  bool _isPlaying = false;

  // Gesture feedback
  bool _showPauseIcon = false;
  bool _showSeekBackward = false;
  bool _showSeekForward = false;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episode.number;
    // Immersive fullscreen portrait
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadStream();
    // Hide overlay after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Map<String, String> _getVideoHeaders(String url) {
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

  void _prefetchEpisode(int ep) {
    if (ep < 1 || ep > widget.totalEpisodes) return;
    if (_prefetchCache.containsKey(ep)) return;
    _api.getStream(widget.drama.id, ep).then((data) {
      if (mounted) _prefetchCache[ep] = data;
    }).catchError((_) {
      // Prefetch best-effort — abaikan error.
    });
  }

  Future<void> _loadStream() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showOverlay = true;
    });

    try {
      // Gunakan prefetch cache bila tersedia (navigasi episode instan).
      final StreamData streamData;
      final cached = _prefetchCache.remove(_currentEpisode);
      if (cached != null) {
        streamData = cached;
      } else {
        streamData = await _api.getStream(widget.drama.id, _currentEpisode);
      }

      _rawHdUrl = streamData.hdUrl;
      _rawSdUrl = streamData.sdUrl;

      // Pick URL - prefer HD
      String rawUrl = _isHD ? streamData.hdUrl : streamData.sdUrl;
      if (rawUrl.isEmpty) {
        rawUrl = streamData.hdUrl.isNotEmpty
            ? streamData.hdUrl
            : streamData.sdUrl;
      }

      if (rawUrl.isEmpty) {
        setState(() {
          _error = 'Video tidak tersedia untuk episode ini.';
          _isLoading = false;
        });
        return;
      }

      // Dispose old controller
      _videoController?.dispose();
      _videoController = null;

      // Create controller with headers
      final uri = Uri.parse(rawUrl);
      final headers = _getVideoHeaders(rawUrl);

      _videoController = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: headers,
      );

      _videoController!.addListener(_videoListener);

      await _videoController!.initialize();
      _videoController!.play();

      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });

      // Record watch history & update watchlist progress
      _recordHistory();

      // Prefetch episode berikutnya di background
      _prefetchEpisode(_currentEpisode + 1);

      // Hide overlay after video starts
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showOverlay = false);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Record this episode to watch history and update watchlist progress.
  void _recordHistory() {
    try {
      final historyService = context.read<HistoryService>();
      historyService.record(
        dramaId: widget.drama.id,
        title: widget.drama.title,
        cover: widget.drama.cover,
        genre: widget.drama.genre,
        source: widget.drama.source,
        episode: _currentEpisode,
        totalEpisodes: widget.totalEpisodes,
      );

      // Also update watchlist progress if drama is in watchlist
      final watchlistService = context.read<WatchlistService>();
      if (watchlistService.isInWatchlist(widget.drama.id)) {
        watchlistService.updateProgress(widget.drama.id, _currentEpisode);
      }
    } catch (_) {
      // Non-critical — never crash the player
    }
  }

  void _videoListener() {
    if (!mounted) return;
    if (_videoController == null) return;

    final value = _videoController!.value;

    if (value.hasError && _error == null) {
      setState(() {
        _error = value.errorDescription ?? 'Playback error';
      });
    }

    // Update playing state
    if (value.isPlaying != _isPlaying) {
      setState(() => _isPlaying = value.isPlaying);
    }
  }

  // === GESTURE HANDLERS ===

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      setState(() {
        _isPlaying = false;
        _showPauseIcon = true;
      });
    } else {
      _videoController!.play();
      setState(() {
        _isPlaying = true;
        _showPauseIcon = true;
      });
    }

    // Hide icon after short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showPauseIcon = false);
    });
  }

  void _seekBackward() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final current = _videoController!.value.position;
    final target = current - const Duration(seconds: 10);
    _videoController!.seekTo(target < Duration.zero ? Duration.zero : target);

    setState(() => _showSeekBackward = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showSeekBackward = false);
    });
  }

  void _seekForward() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final current = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    final target = current + const Duration(seconds: 10);
    _videoController!.seekTo(target > duration ? duration : target);

    setState(() => _showSeekForward = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showSeekForward = false);
    });
  }

  Future<void> _nextEpisode() async {
    if (_currentEpisode < widget.totalEpisodes) {
      _videoController?.pause();

      // Show interstitial: variant A (ep 3) or B (ep 6)
      final variant = AdService.shouldShowAd();
      if (variant != null) {
        await AdService.showInterstitialVariant(context, variant);
      }

      setState(() => _currentEpisode++);
      _loadStream();
    }
  }

  void _prevEpisode() {
    if (_currentEpisode > 1) {
      _videoController?.pause();
      setState(() => _currentEpisode--);
      _loadStream();
    }
  }

  void _toggleQuality() {
    setState(() => _isHD = !_isHD);
    _loadStream();
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video layer - BoxFit.contain (no zoom, no crop)
          _buildVideoLayer(),

          // Gesture detection zones
          _buildGestureZones(),

          // Seek/Pause feedback icons
          _buildGestureFeedback(),

          // Top overlay (back, title, quality)
          if (_showOverlay) _buildTopOverlay(),

          // Bottom overlay (progress bar, episode nav)
          if (_showOverlay) _buildBottomOverlay(),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),

          // Error overlay
          if (_error != null && !_isLoading) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        _error == null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    return Container(color: Colors.black);
  }

  Widget _buildGestureZones() {
    return Row(
      children: [
        // Left zone - double tap = seek backward
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleOverlay,
            onDoubleTap: _seekBackward,
            onVerticalDragEnd: _handleVerticalSwipe,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Center zone - double tap = pause/play
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleOverlay,
            onDoubleTap: _togglePlayPause,
            onVerticalDragEnd: _handleVerticalSwipe,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Right zone - double tap = seek forward
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleOverlay,
            onDoubleTap: _seekForward,
            onVerticalDragEnd: _handleVerticalSwipe,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  void _handleVerticalSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    // Swipe ke atas (jari naik) = next episode (seperti TikTok)
    if (details.primaryVelocity! < -200) {
      _nextEpisode();
    // Swipe ke bawah (jari turun) = prev episode
    } else if (details.primaryVelocity! > 200) {
      _prevEpisode();
    }
  }

  Widget _buildGestureFeedback() {
    return Stack(
      children: [
        // Pause/Play icon - center
        if (_showPauseIcon)
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),

        // Seek backward icon - left
        if (_showSeekBackward)
          Positioned(
            left: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.replay_10_rounded,
                        color: Colors.white, size: 36),
                  ],
                ),
              ),
            ),
          ),

        // Seek forward icon - right
        if (_showSeekForward)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forward_10_rounded,
                        color: Colors.white, size: 36),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 40, 8, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withAlpha(200), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.drama.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Ep $_currentEpisode/${widget.totalEpisodes} • ${widget.drama.source}',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Quality badge
            GestureDetector(
              onTap: _toggleQuality,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _isHD ? const Color(0xFF6C63FF) : Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_isHD ? 'HD' : 'SD',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withAlpha(200), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              _buildProgressBar(),

            const SizedBox(height: 12),

            // Episode navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentEpisode > 1)
                  IconButton(
                    onPressed: _prevEpisode,
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white, size: 32),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Episode $_currentEpisode',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (_currentEpisode < widget.totalEpisodes)
                  IconButton(
                    onPressed: _nextEpisode,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Colors.white, size: 32),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Gesture hints
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded,
                    color: Colors.grey[600], size: 14),
                const SizedBox(width: 4),
                Text(
                  '2x tap: kiri=mundur • tengah=pause • kanan=maju',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    return Column(
      children: [
        // Time labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
            Text(
              _formatDuration(duration),
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Seekable progress bar
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFF6C63FF),
            inactiveTrackColor: Colors.white24,
            thumbColor: const Color(0xFF6C63FF),
            overlayColor: const Color(0xFF6C63FF).withAlpha(40),
          ),
          child: Slider(
            min: 0,
            max: duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0,
            value: position.inMilliseconds
                .toDouble()
                .clamp(0, duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              _videoController!
                  .seekTo(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF6C63FF)),
            const SizedBox(height: 16),
            Text(
              'Episode $_currentEpisode',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              widget.drama.title,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              const Text('Gagal memutar video',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadStream,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                  if (_rawHdUrl.isNotEmpty && _rawSdUrl.isNotEmpty)
                    OutlinedButton(
                      onPressed: _toggleQuality,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70),
                      child: Text('Coba ${_isHD ? "SD" : "HD"}'),
                    ),
                  if (_currentEpisode < widget.totalEpisodes)
                    OutlinedButton(
                      onPressed: _nextEpisode,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70),
                      child: const Text('Next Ep →'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
