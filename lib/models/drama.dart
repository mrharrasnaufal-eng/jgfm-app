class Drama {
  final String id;
  final String title;
  final String cover;
  final String? coverHorizontal;
  final String description;
  final String genre;
  final List<String> genres;
  final List<String> tags;
  final int totalEpisodes;
  final String source;
  final String sourceId;

  Drama({
    required this.id,
    required this.title,
    required this.cover,
    this.coverHorizontal,
    required this.description,
    required this.genre,
    required this.genres,
    required this.tags,
    required this.totalEpisodes,
    required this.source,
    required this.sourceId,
  });

  factory Drama.fromJson(Map<String, dynamic> json) {
    return Drama(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      coverHorizontal: json['coverHorizontal'],
      description: json['description'] ?? '',
      genre: json['genre'] ?? '',
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalEpisodes: json['totalEpisodes'] ?? 0,
      source: json['source'] ?? '',
      sourceId: json['sourceId'] ?? '',
    );
  }

  /// Get proxied cover URL via JagatFilm image proxy
  String get proxiedCover {
    if (cover.isEmpty) return '';
    return 'https://jagatfilm.com/api/img?url=${Uri.encodeComponent(cover)}';
  }

  String get proxiedCoverHorizontal {
    if (coverHorizontal == null || coverHorizontal!.isEmpty) return proxiedCover;
    return 'https://jagatfilm.com/api/img?url=${Uri.encodeComponent(coverHorizontal!)}';
  }
}

class DramaDetail extends Drama {
  final List<EpisodeInfo> episodes;

  DramaDetail({
    required super.id,
    required super.title,
    required super.cover,
    super.coverHorizontal,
    required super.description,
    required super.genre,
    required super.genres,
    required super.tags,
    required super.totalEpisodes,
    required super.source,
    required super.sourceId,
    required this.episodes,
  });

  factory DramaDetail.fromJson(Map<String, dynamic> json) {
    return DramaDetail(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      coverHorizontal: json['coverHorizontal'],
      description: json['description'] ?? '',
      genre: json['genre'] ?? '',
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalEpisodes: json['totalEpisodes'] ?? 0,
      source: json['source'] ?? '',
      sourceId: json['sourceId'] ?? '',
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => EpisodeInfo.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EpisodeInfo {
  final String id;
  final int number;
  final String title;
  final int? duration;
  final bool isFree;

  EpisodeInfo({
    required this.id,
    required this.number,
    required this.title,
    this.duration,
    this.isFree = true,
  });

  factory EpisodeInfo.fromJson(Map<String, dynamic> json) {
    return EpisodeInfo(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? 0,
      title: json['title'] ?? 'Episode ${json['number'] ?? 0}',
      duration: json['duration'],
      isFree: json['isFree'] ?? true,
    );
  }
}

class StreamData {
  final String sdUrl;
  final String hdUrl;
  final List<Subtitle> subtitles;

  StreamData({
    required this.sdUrl,
    required this.hdUrl,
    required this.subtitles,
  });

  factory StreamData.fromJson(Map<String, dynamic> json) {
    return StreamData(
      sdUrl: json['sdUrl'] ?? '',
      hdUrl: json['hdUrl'] ?? '',
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((e) => Subtitle.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Get best available URL (prefer HD, fallback to SD)
  String get bestUrl => hdUrl.isNotEmpty ? hdUrl : sdUrl;

  /// Get HLS proxied URL for playback
  String get proxiedHdUrl {
    if (hdUrl.isEmpty) return proxiedSdUrl;
    return 'https://jagatfilm.com/api/hls?url=${Uri.encodeComponent(hdUrl)}';
  }

  String get proxiedSdUrl {
    if (sdUrl.isEmpty) return '';
    return 'https://jagatfilm.com/api/hls?url=${Uri.encodeComponent(sdUrl)}';
  }
}

class Subtitle {
  final String lang;
  final String url;
  final String label;

  Subtitle({
    required this.lang,
    required this.url,
    required this.label,
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      lang: json['lang'] ?? '',
      url: json['url'] ?? '',
      label: json['label'] ?? '',
    );
  }

  /// Get proxied subtitle URL
  String get proxiedUrl {
    if (url.isEmpty) return '';
    return 'https://jagatfilm.com/api/subtitle?url=${Uri.encodeComponent(url)}';
  }
}
