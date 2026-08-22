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
    _loadStream();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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

      // Create ChewieController
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: true,
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
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  textAlign: TextAlign.center,
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

  void _toggleQuality() {
    setState(() => _isHD = !_isHD);
    _loadStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.drama.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Episode $_currentEpisode',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          // Quality toggle
          TextButton(
            onPressed: _toggleQuality,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isHD ? const Color(0xFF6C63FF) : Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isHD ? 'HD' : 'SD',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayer(),
          ),

          // Episode navigation and info
          Expanded(
            child: _buildEpisodeControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 12),
              Text('Memuat video...',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadStream,
                  child: const Text('Coba Lagi'),
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

  Widget _buildEpisodeControls() {
    return Container(
      color: const Color(0xFF0F0F1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prev/Next controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Previous
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentEpisode > 1
                        ? () => _switchEpisode(_currentEpisode - 1)
                        : null,
                    icon: const Icon(Icons.skip_previous_rounded, size: 20),
                    label: const Text('Sebelumnya', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Next
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _currentEpisode < widget.totalEpisodes
                        ? () => _switchEpisode(_currentEpisode + 1)
                        : null,
                    icon: const Icon(Icons.skip_next_rounded, size: 20),
                    label: const Text('Selanjutnya', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Episode list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Episode (${widget.totalEpisodes})',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Episode grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: widget.totalEpisodes,
              itemBuilder: (context, index) {
                final epNum = index + 1;
                final isCurrent = epNum == _currentEpisode;
                return GestureDetector(
                  onTap: () => _switchEpisode(epNum),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF6C63FF)
                            : Colors.grey[800]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$epNum',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.grey[400],
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
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
}
