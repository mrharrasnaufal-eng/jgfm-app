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
    // Keep portrait, hide status bar for immersive experience
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadStream();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    // Restore UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Determine the best playable URL
  String _getPlayableUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    final lower = rawUrl.toLowerCase();

    // Direct MP4 - play without proxy
    if (lower.contains('.mp4') && !lower.contains('.m3u8')) {
      return rawUrl;
    }

    // HLS (.m3u8) - use proxy to rewrite segments
    if (lower.contains('.m3u8')) {
      return 'https://jagatfilm.com/api/hls?url=${Uri.encodeComponent(rawUrl)}';
    }

    // Unknown format - try proxy
    return 'https://jagatfilm.com/api/hls?url=${Uri.encodeComponent(rawUrl)}';
  }

  /// Get HTTP headers for video request
  Map<String, String> _getVideoHeaders(String url) {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };
    if (url.contains('foshort.com')) {
      headers['Referer'] = 'https://bilitv.com/';
    } else if (!url.contains('jagatfilm.com')) {
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

      String rawUrl = _isHD ? streamData.hdUrl : streamData.sdUrl;
      if (rawUrl.isEmpty) {
        rawUrl = streamData.hdUrl.isNotEmpty
            ? streamData.hdUrl
            : streamData.sdUrl;
      }

      if (rawUrl.isEmpty) {
        setState(() {
          _error = 'URL video tidak tersedia untuk episode ini.';
          _isLoading = false;
        });
        return;
      }

      final videoUrl = _getPlayableUrl(rawUrl);
      _currentVideoUrl = videoUrl;

      if (videoUrl.isEmpty) {
        setState(() {
          _error = 'Tidak dapat memproses URL video.';
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

      _videoController!.addListener(() {
        if (_videoController!.value.hasError && mounted) {
          final desc = _videoController!.value.errorDescription ?? 'Unknown';
          if (_error == null) {
            setState(() {
              _error = 'Playback error: $desc';
            });
          }
        }
      });

      await _videoController!.initialize();

      // Chewie - portrait fullscreen
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: false,
        // Portrait video - use 9:16 aspect ratio
        aspectRatio: 9 / 16,
        // Keep portrait on fullscreen
        deviceOrientationsOnEnterFullScreen: [DeviceOrientation.portraitUp],
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: $errorMessage',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
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
    setState(() => _currentEpisode = episodeNumber);
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            // Video area (expands to fill available space)
            Expanded(
              flex: 3,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > 300) _nextEpisode();
                    if (details.primaryVelocity! < -300) _prevEpisode();
                  }
                },
                child: _buildVideoArea(),
              ),
            ),
            // Episode controls (bottom section)
            Expanded(
              flex: 2,
              child: _buildEpisodeSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ep $_currentEpisode / ${widget.totalEpisodes} • ${widget.drama.source}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          // Debug toggle
          GestureDetector(
            onTap: () => setState(() => _showDebug = !_showDebug),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.bug_report_outlined,
                  color: _showDebug ? Colors.orange : Colors.white38, size: 18),
            ),
          ),
          // Quality
          GestureDetector(
            onTap: _toggleQuality,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _isHD ? const Color(0xFF6C63FF) : Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_isHD ? 'HD' : 'SD',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 12),
              Text('Memuat video...', style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 36),
              const SizedBox(height: 10),
              Text('Gagal memutar video',
                  style: TextStyle(color: Colors.grey[300], fontSize: 14)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              if (_showDebug && _currentVideoUrl.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('URL: $_currentVideoUrl',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 9),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadStream,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (_rawHdUrl.isNotEmpty && _rawSdUrl.isNotEmpty)
                    OutlinedButton(
                      onPressed: _toggleQuality,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text('Coba ${_isHD ? "SD" : "HD"}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (_currentEpisode < widget.totalEpisodes)
                    OutlinedButton.icon(
                      onPressed: _nextEpisode,
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: const Text('Next Ep', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return Stack(
        children: [
          Chewie(controller: _chewieController!),
          // Debug overlay
          if (_showDebug)
            Positioned(
              left: 4,
              top: 4,
              child: _buildDebugOverlay(),
            ),
        ],
      );
    }

    return Container(color: Colors.black);
  }

  Widget _buildEpisodeSection() {
    return Container(
      color: const Color(0xFF0F0F1A),
      child: Column(
        children: [
          // Prev/Next row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentEpisode > 1 ? _prevEpisode : null,
                    icon: const Icon(Icons.skip_previous_rounded, size: 18),
                    label: const Text('Prev', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.grey[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swipe_down_rounded, color: Colors.white38, size: 16),
                      Text('Ep $_currentEpisode',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _currentEpisode < widget.totalEpisodes ? _nextEpisode : null,
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text('Next', style: TextStyle(fontSize: 11)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Episode header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                Text('Episode (${widget.totalEpisodes})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Episode grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.4,
              ),
              itemCount: widget.totalEpisodes,
              itemBuilder: (context, index) {
                final epNum = index + 1;
                final isCurrent = epNum == _currentEpisode;
                return GestureDetector(
                  onTap: () => _switchEpisode(epNum),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFF6C63FF) : Colors.grey[800]!,
                      ),
                    ),
                    child: Center(
                      child: Text('$epNum',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey[400],
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugOverlay() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(6),
      ),
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('DEBUG', style: TextStyle(color: Colors.orange[300], fontSize: 9, fontWeight: FontWeight.bold)),
          Text('ID: ${widget.drama.id}', style: const TextStyle(color: Colors.white60, fontSize: 8)),
          Text('Ep: $_currentEpisode | Q: ${_isHD ? "HD" : "SD"}',
              style: const TextStyle(color: Colors.white60, fontSize: 8)),
          Text('HD: ${_rawHdUrl.isEmpty ? "(empty)" : _truncate(_rawHdUrl, 50)}',
              style: const TextStyle(color: Colors.white60, fontSize: 8)),
          Text('SD: ${_rawSdUrl.isEmpty ? "(empty)" : _truncate(_rawSdUrl, 50)}',
              style: const TextStyle(color: Colors.white60, fontSize: 8)),
          Text('Play: ${_truncate(_currentVideoUrl, 50)}',
              style: const TextStyle(color: Colors.white60, fontSize: 8)),
        ],
      ),
    );
  }

  String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...';
  }
}
