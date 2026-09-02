import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/drama.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class DramaCardGrid extends StatelessWidget {
  final Drama drama;
  final int? viewCount;
  final VoidCallback? onTap;

  const DramaCardGrid({
    super.key,
    required this.drama,
    this.viewCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster with badges
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Hero(
              tag: 'drama_cover_${drama.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster image
                    CachedNetworkImage(
                      imageUrl: drama.proxiedCover,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.card,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.card,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),

                  // View count badge — bottom left
                  if (viewCount != null && viewCount! > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xCC000000),
                              Color(0x00000000),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 12,
                              color: AppTheme.textPrimary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatViews(viewCount!),
                              style: const TextStyle(
                                fontSize: AppFontSize.micro,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Provider badge — top right
                  if (drama.source.isNotEmpty)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          drama.sourceCode,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Title
          Text(
            drama.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Genre pill
          if (_genreText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _genreText,
                style: const TextStyle(
                  fontSize: AppFontSize.micro,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  /// Gets the first available genre text, handling empty lists safely.
  String get _genreText {
    if (drama.genres.isNotEmpty) return drama.genres[0];
    if (drama.genre.isNotEmpty) return drama.genre;
    return '';
  }
}
