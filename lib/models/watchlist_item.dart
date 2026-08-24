/// Model for a drama saved to the user's watchlist.
class WatchlistItem {
  final String dramaId;
  final String title;
  final String cover;
  final String genre;
  final String source;
  final int totalEpisodes;
  final int lastEpisode;
  final DateTime addedAt;

  WatchlistItem({
    required this.dramaId,
    required this.title,
    required this.cover,
    required this.genre,
    required this.source,
    required this.totalEpisodes,
    this.lastEpisode = 0,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Progress percentage (0.0 - 1.0).
  double get progress =>
      totalEpisodes > 0 ? (lastEpisode / totalEpisodes).clamp(0.0, 1.0) : 0.0;

  /// Human-readable progress text.
  String get progressText => 'Episode $lastEpisode/$totalEpisodes';

  /// Proxied cover URL via JagatFilm image proxy.
  String get proxiedCover {
    if (cover.isEmpty) return '';
    return 'https://jagatfilm.com/api/img?url=${Uri.encodeComponent(cover)}';
  }

  WatchlistItem copyWith({
    int? lastEpisode,
  }) {
    return WatchlistItem(
      dramaId: dramaId,
      title: title,
      cover: cover,
      genre: genre,
      source: source,
      totalEpisodes: totalEpisodes,
      lastEpisode: lastEpisode ?? this.lastEpisode,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'dramaId': dramaId,
        'title': title,
        'cover': cover,
        'genre': genre,
        'source': source,
        'totalEpisodes': totalEpisodes,
        'lastEpisode': lastEpisode,
        'addedAt': addedAt.toIso8601String(),
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      dramaId: json['dramaId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      cover: json['cover']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      totalEpisodes: json['totalEpisodes'] as int? ?? 0,
      lastEpisode: json['lastEpisode'] as int? ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
