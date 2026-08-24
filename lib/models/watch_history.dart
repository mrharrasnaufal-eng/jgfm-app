/// Model for a watch history entry.
class WatchHistory {
  final String dramaId;
  final String title;
  final String cover;
  final String genre;
  final String source;
  final int episode;
  final int totalEpisodes;
  final DateTime watchedAt;

  WatchHistory({
    required this.dramaId,
    required this.title,
    required this.cover,
    required this.genre,
    required this.source,
    required this.episode,
    required this.totalEpisodes,
    DateTime? watchedAt,
  }) : watchedAt = watchedAt ?? DateTime.now();

  /// Proxied cover URL via JagatFilm image proxy.
  String get proxiedCover {
    if (cover.isEmpty) return '';
    return 'https://jagatfilm.com/api/img?url=${Uri.encodeComponent(cover)}';
  }

  /// Human-readable relative time.
  String get timeAgo {
    final diff = DateTime.now().difference(watchedAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    return '${(diff.inDays / 30).floor()} bulan lalu';
  }

  Map<String, dynamic> toJson() => {
        'dramaId': dramaId,
        'title': title,
        'cover': cover,
        'genre': genre,
        'source': source,
        'episode': episode,
        'totalEpisodes': totalEpisodes,
        'watchedAt': watchedAt.toIso8601String(),
      };

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      dramaId: json['dramaId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      cover: json['cover']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      episode: json['episode'] as int? ?? 1,
      totalEpisodes: json['totalEpisodes'] as int? ?? 0,
      watchedAt: json['watchedAt'] != null
          ? DateTime.tryParse(json['watchedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
