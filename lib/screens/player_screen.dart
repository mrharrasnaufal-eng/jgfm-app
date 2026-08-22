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
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episode.number;
    _enterFullscreen();
    _loadStream();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _exitFullscreen();
    super.dispose();
  }

  void _enterFullscreen() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Determine the best playable URL and format
  /// - MP4 direct URLs: play directly with headers
  /// - HLS (.m3u8): use proxy to bypass CORS
  /// - Other URLs: try proxy
  String _getPlayableUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';

    final lower = rawUrl.toLowerCase();

    // If it's already a direct MP4 URL, use it directly
    // ExoPlayer can handle MP4 with just headers
    if (lower.contains('.mp4') && !lower.contains('.m3u8')) {
      return rawUrl;
    }

    // For HLS (.m3u8), use the proxy to rewrite segment URLs
    if (lower.contains('.m3u8') || lower.contains('m3u8')) {
      return 'https://jagatfilm.com/api/hls?url=${Uri.encodeComponent(rawUrl)}';
    }

    // For other URLs (could be CDN with no extension), try proxy
    return 'https://jagatfilm.com/api/hls?url=${Uri.encodeComponent(rawUrl)}';
  }

  /// Get HTTP headers for video request
  Map<String, String> _getVideoHeaders(String url) {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };

    // Add Referer based on provider
    if (url.contains('foshort.com')) {
      headers['Referer'] = 'https://bilitv.com/';
    } else if (url.contains('jagatfilm.com')) {
      // Proxy URL - no extra headers needed
    } else {
      headers['Referer'] = 'https://jagatfilm.com/';
    }

    return headers;
  }

  Future<void> _loadStream() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentVideoUrl = '';
    });

    try {
      final streamData =
          await _api.getStream(widget.drama.id, _currentEpisode);

      _rawHdUrl = streamData.hdUrl;
      _rawSdUrl = streamData.sdUrl;

      // Pick raw URL based on quality preference
      String rawUrl = _isHD ? streamData.hdUrl : streamData.sdUrl;
      if (rawUrl.isEmpty) {
        rawUrl = streamData.hdUrl.isNotEmpty
            ? streamData.hdUrl
            : streamData.sdUrl;
      }

      if (rawUrl.isEmpty) {
        setState(() {
          _error = 'URL video tidak tersedia untuk episode ini';
          _isLoading = false;
        });
        return;
      }

      // Get playable URL
      final videoUrl = _getPlayableUrl(rawUrl);
      _currentVideoUrl = videoUrl;

      if (videoUrl.isEmpty) {
        setState(() {
          _error = 'Tidak dapat memproses URL video';
          _isLoading = false;
        });
        return;
      }

      // Dispose old controllers
      _chewieController?.dispose();
      _videoController?.dispose();
      _chewieController = null;
      _videoController = null;

      // Create VideoPlayerController with headers
      final uri = Uri.parse(videoUrl);
      final headers = _getVideoHeaders(videoUrl);

      _videoController = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: headers,
      );

      // Listen for errors
      _videoController!.addListener(() {
        if (_videoController!.value.hasError && mounted) {
          setState(() {
            _error =
                'Playback error: ${_videoController!.value.errorDescription ?? "Unknown"}';
          });
        }
      });

      await _videoController!.initialize();

      // Create ChewieController
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF6C63FF),
          handleColor: const Color(0xFF6C63FF),
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white12,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _switchEpisode(int episodeNumber) {
    if (episodeNumber == _currentEpisode) return;
    if (episodeNumber < 1 || episodeNumber > widget.totalEpisodes) return;

    _videoController?.pause();
    setState(() {
      _currentEpisode = episodeNumber;
    });
    _loadStream();
  }

  void _nextEpisode() {
    if (_currentEpisode < widget.totalEpisodes) {
      _switchEpisode(_currentEpisode + 1);
    }
  }

  void _prevEpisode() {
    if (_currentEpisode > 1) {
      _switchEpisode(_currentEpisode - 1);
    }
  }

  void _toggleQuality() {
    setState(() => _isHD = !_isHD);
    _loadStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 300) {
              _nextEpisode();
            } else if (details.primaryVelocity! < -300) {
              _prevEpisode();
            }
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player (fullscreen)
            _buildPlayer(),

            // Top overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopOverlay(),
            ),

            // Bottom overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomOverlay(),
            ),

            // Debug info overlay
            if (_showDebug)
              Positioned(
                left: 8,
                right: 8,
                bottom: 60,
                child: _buildDebugInfo(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6C63FF)),
              const SizedBox(height: 16),
              Text(
                'Memuat Episode $_currentEpisode...',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  'Gagal memutar video',
                  style: TextStyle(color: Colors.grey[300], fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_currentVideoUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'URL: ${_currentVideoUrl.length > 80 ? '${_currentVideoUrl.substring(0, 80)}...' : _currentVideoUrl}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 9),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadStream,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                    if (_currentEpisode < widget.totalEpisodes) ...[
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _nextEpisode,
                        icon: const Icon(Icons.skip_next, size: 16),
                        label: const Text('Next Ep',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
                // Try other quality
                if (_rawHdUrl.isNotEmpty && _rawSdUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: _toggleQuality,
                      child: Text(
                        'Coba kualitas ${_isHD ? "SD" : "HD"}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Container(color: Colors.black);
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadStream,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(180),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white,
                  size: 22),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ep $_currentEpisode / ${widget.totalEpisodes}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Debug toggle
            GestureDetector(
              onTap: () => setState(() => _showDebug = !_showDebug),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _showDebug ? Colors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.bug_report_outlined,
                    color: _showDebug ? Colors.black : Colors.white54,
                    size: 18),
              ),
            ),
            // Quality toggle
            GestureDetector(
              onTap: _toggleQuality,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isHD ? const Color(0xFF6C63FF) : Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _isHD ? 'HD' : 'SD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(180),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _currentEpisode > 1 ? _prevEpisode : null,
              icon: const Icon(Icons.skip_previous_rounded, size: 18),
              label: const Text('Prev', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swipe_down_rounded,
                      color: Colors.white60, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Ep $_currentEpisode',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed:
                  _currentEpisode < widget.totalEpisodes ? _nextEpisode : null,
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Next', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('DEBUG INFO',
              style: TextStyle(
                  color: Colors.orange[300],
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _debugRow('Drama ID', widget.drama.id),
          _debugRow('Episode', '$_currentEpisode'),
          _debugRow('Quality', _isHD ? 'HD' : 'SD'),
          _debugRow('Raw HD', _rawHdUrl.isEmpty
              ? '(empty)'
              : (_rawHdUrl.length > 60
                  ? '${_rawHdUrl.substring(0, 60)}...'
                  : _rawHdUrl)),
          _debugRow('Raw SD', _rawSdUrl.isEmpty
              ? '(empty)'
              : (_rawSdUrl.length > 60
                  ? '${_rawSdUrl.substring(0, 60)}...'
                  : _rawSdUrl)),
          _debugRow('Play URL', _currentVideoUrl.isEmpty
              ? '(empty)'
              : (_currentVideoUrl.length > 60
                  ? '${_currentVideoUrl.substring(0, 60)}...'
                  : _currentVideoUrl)),
          _debugRow('Status', _isLoading
              ? 'Loading...'
              : (_error != null ? 'ERROR' : 'Playing')),
        ],
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 9)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
