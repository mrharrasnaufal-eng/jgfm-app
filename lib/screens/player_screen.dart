import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/drama.dart';
import '../services/api_service.dart';

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
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  String _currentVideoUrl = '';
  String _rawHdUrl = '';
  String _rawSdUrl = '';
  int _currentEpisode = 1;
  bool _isHD = true;
  bool _showOverlay = true;

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
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Use direct URL - ExoPlayer on Android can handle HLS and MP4 natively
  /// The proxy approach doesn't work well on mobile because ExoPlayer
  /// needs to directly access video segments
  String _getPlayableUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    // Use raw URL directly - ExoPlayer supports HLS/MP4 natively
    // Only use proxy if absolutely needed (CORS is browser-only issue)
    return rawUrl;
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

  Future<void> _loadStream() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentVideoUrl = '';
      _showOverlay = true;
    });

    try {
      final streamData =
          await _api.getStream(widget.drama.id, _currentEpisode);

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

      // Use direct URL (no proxy needed for native Android)
      final videoUrl = _getPlayableUrl(rawUrl);
      _currentVideoUrl = videoUrl;

      // Dispose old
      _chewieController?.dispose();
      _videoController?.dispose();
      _chewieController = null;
      _videoController = null;

      // Create controller with headers
      final uri = Uri.parse(videoUrl);
      final headers = _getVideoHeaders(videoUrl);

      _videoController = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: headers,
      );

      _videoController!.addListener(() {
        if (_videoController!.value.hasError && mounted && _error == null) {
          setState(() {
            _error = _videoController!.value.errorDescription ?? 'Playback error';
          });
        }
      });

      await _videoController!.initialize();

      // Chewie - no controls visible, fullscreen feel
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        showOptions: false,
        allowFullScreen: false,
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF6C63FF),
          handleColor: const Color(0xFF6C63FF),
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white12,
        ),
      );

      setState(() => _isLoading = false);

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

  void _nextEpisode() {
    if (_currentEpisode < widget.totalEpisodes) {
      _videoController?.pause();
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
      body: GestureDetector(
        // Tap to show/hide overlay
        onTap: _toggleOverlay,
        // Swipe down = next, swipe up = prev
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 200) {
            _nextEpisode();
          } else if (details.primaryVelocity! < -200) {
            _prevEpisode();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video fills entire screen
            _buildVideoFullscreen(),

            // Top overlay (back, title, quality)
            if (_showOverlay) _buildTopOverlay(),

            // Bottom overlay (episode info, swipe hint)
            if (_showOverlay) _buildBottomOverlay(),

            // Loading overlay
            if (_isLoading) _buildLoadingOverlay(),

            // Error overlay
            if (_error != null && !_isLoading) _buildErrorOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFullscreen() {
    if (_chewieController != null && !_isLoading && _error == null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: Chewie(controller: _chewieController!),
          ),
        ),
      );
    }
    return Container(color: Colors.black);
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
              const SizedBox(height: 12),
              Text(
                'Geser bawah untuk episode berikutnya',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
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
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
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
                  color: _isHD ? const Color(0xFF6C63FF) : Colors.grey[700],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            // Swipe hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swipe_down_rounded,
                    color: Colors.white38, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Geser bawah = episode berikutnya',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
