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
  StreamData? _streamData;
  int _currentEpisode = 1;
  bool _isHD = true;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episode.number;
    // Force fullscreen landscape
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

  Future<void> _loadStream() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final streamData = await _api.getStream(widget.drama.id, _currentEpisode);
      _streamData = streamData;

      // Determine video URL (prefer HD, through HLS proxy)
      String videoUrl = _isHD ? streamData.proxiedHdUrl : streamData.proxiedSdUrl;
      if (videoUrl.isEmpty) {
        videoUrl = streamData.proxiedHdUrl.isNotEmpty
            ? streamData.proxiedHdUrl
            : streamData.proxiedSdUrl;
      }

      if (videoUrl.isEmpty) {
        setState(() {
          _error = 'URL video tidak tersedia untuk episode ini';
          _isLoading = false;
        });
        return;
      }

      // Dispose old controllers
      _chewieController?.dispose();
      _videoController?.dispose();

      // Create VideoPlayerController
      final uri = Uri.parse(videoUrl);
      _videoController = VideoPlayerController.networkUrl(uri);

      await _videoController!.initialize();

      // Create ChewieController - fullscreen by default
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false, // kita sudah fullscreen manual
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Gagal memutar video',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        },
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat video: ${e.toString()}';
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
        // Swipe down → next episode
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 300) {
              // Swipe down → next episode
              _nextEpisode();
            } else if (details.primaryVelocity! < -300) {
              // Swipe up → previous episode
              _prevEpisode();
            }
          }
        },
        child: Stack(
          children: [
            // Video player (fullscreen)
            Positioned.fill(
              child: _buildPlayer(),
            ),

            // Top overlay - info & controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopOverlay(),
            ),

            // Bottom overlay - episode info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomOverlay(),
            ),

            // Swipe hint (show briefly)
            if (!_isLoading && _error == null)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_down,
                          color: Colors.white.withAlpha(80), size: 28),
                      Text(
                        'Geser\nbawah',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withAlpha(80),
                          fontSize: 9,
                        ),
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

  Widget _buildPlayer() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadStream,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                  child: const Text('Coba Lagi'),
                ),
                const SizedBox(height: 8),
                if (_currentEpisode < widget.totalEpisodes)
                  TextButton(
                    onPressed: _nextEpisode,
                    child: const Text('Coba Episode Berikutnya →'),
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

  Widget _buildTopOverlay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
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
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            // Title & episode
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Episode $_currentEpisode / ${widget.totalEpisodes}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Quality toggle
            GestureDetector(
              onTap: _toggleQuality,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isHD ? const Color(0xFF6C63FF) : Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _isHD ? 'HD' : 'SD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
            // Prev button
            TextButton.icon(
              onPressed: _currentEpisode > 1 ? _prevEpisode : null,
              icon: const Icon(Icons.skip_previous_rounded, size: 18),
              label: const Text('Prev', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
            // Episode indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Ep $_currentEpisode',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            // Next button
            TextButton.icon(
              onPressed:
                  _currentEpisode < widget.totalEpisodes ? _nextEpisode : null,
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Next', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
