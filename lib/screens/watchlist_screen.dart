import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watch_history.dart';
import '../models/watchlist_item.dart';
import '../services/history_service.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'detail_screen.dart';
import '../models/drama.dart';

/// Daftarku screen — Sedang Ditonton + Riwayat Tontonan tabs.
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _WatchlistTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: const [
          Text(
            'Daftarku',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppFontSize.h1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textTertiary,
        labelStyle: const TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppTheme.accent,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'Sedang Ditonton'),
          Tab(text: 'Riwayat'),
        ],
      ),
    );
  }
}

/// Tab: Sedang Ditonton (watchlist items with progress).
class _WatchlistTab extends StatelessWidget {
  const _WatchlistTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchlistService>(
      builder: (context, watchlistService, _) {
        final items = watchlistService.items;

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = items[index];
            return _WatchlistTile(
              item: item,
              onTap: () => _navigateToDetail(context, item),
              onRemove: () => _removeItem(context, item.dramaId),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.bookmark_border_rounded,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Belum ada drama di daftar',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppFontSize.h3,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Mulai tonton untuk menambahkan',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: AppFontSize.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, WatchlistItem item) {
    final drama = Drama(
      id: item.dramaId,
      title: item.title,
      cover: item.cover,
      description: '',
      genre: item.genre,
      genres: item.genre.isNotEmpty ? [item.genre] : [],
      tags: [],
      totalEpisodes: item.totalEpisodes,
      source: item.source,
      sourceId: '',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(drama: drama)),
    );
  }

  void _removeItem(BuildContext context, String dramaId) {
    context.read<WatchlistService>().remove(dramaId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dihapus dari daftar'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Tab: Riwayat Tontonan.
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryService>(
      builder: (context, historyService, _) {
        final items = historyService.items;

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _HistoryTile(
                    item: item,
                    onTap: () => _navigateToDetail(context, item),
                  );
                },
              ),
            ),
            // Clear all button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmClearAll(context),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus Semua Riwayat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error, width: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Belum ada riwayat',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppFontSize.h3,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Drama yang kamu tonton akan muncul di sini',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: AppFontSize.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, WatchHistory item) {
    final drama = Drama(
      id: item.dramaId,
      title: item.title,
      cover: item.cover,
      description: '',
      genre: item.genre,
      genres: item.genre.isNotEmpty ? [item.genre] : [],
      tags: [],
      totalEpisodes: item.totalEpisodes,
      source: item.source,
      sourceId: '',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(drama: drama)),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Hapus Semua Riwayat?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Semua riwayat tontonan akan dihapus permanen.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryService>().clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Riwayat dihapus')),
              );
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile widget for watchlist item.
class _WatchlistTile extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _WatchlistTile({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 96,
                child: CachedNetworkImage(
                  imageUrl: item.proxiedCover,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surface),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surface,
                    child: const Icon(
                      Icons.movie_rounded,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.progressText,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor: AppTheme.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.success),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Action buttons
                  Row(
                    children: [
                      _ActionChip(
                        icon: Icons.play_arrow_rounded,
                        label: 'Lanjut',
                        color: AppTheme.accent,
                        onTap: onTap,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionChip(
                        icon: Icons.close_rounded,
                        label: 'Hapus',
                        color: AppTheme.textTertiary,
                        onTap: onRemove,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile widget for history item.
class _HistoryTile extends StatelessWidget {
  final WatchHistory item;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: item.proxiedCover,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surface),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surface,
                    child: const Icon(
                      Icons.movie_rounded,
                      color: AppTheme.textTertiary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Episode ${item.episode}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.timeAgo,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: AppFontSize.micro,
                    ),
                  ),
                ],
              ),
            ),
            // Play icon
            const Icon(
              Icons.play_circle_outline_rounded,
              color: AppTheme.accent,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small action chip button.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5), width: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
