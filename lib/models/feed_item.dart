import 'drama.dart';

/// Item untuk feed "Untuk Anda" (Reels-style) — drama + status like.
/// liked/likeCount mutable karena di-update saat user toggle like.
class FeedItem {
  final Drama drama;
  bool liked;
  int likeCount;

  FeedItem({
    required this.drama,
    this.liked = false,
    this.likeCount = 0,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      drama: Drama.fromJson(json),
      liked: json['liked'] == true,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
    );
  }
}
