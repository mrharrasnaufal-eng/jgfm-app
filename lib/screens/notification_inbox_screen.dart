import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import 'search_screen.dart';
import 'login_screen.dart';

/// Notification inbox screen — shows all notifications from server.
class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  List<_InboxItem> _items = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      final uri = Uri.parse(
              'https://masterpanel.jagatfilm.com/api/notifications')
          .replace(queryParameters: {
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final response = await http.get(uri, headers: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        setState(() {
          _error = 'Gagal memuat notifikasi';
          _loading = false;
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != true) {
        setState(() {
          _error = 'Data tidak valid';
          _loading = false;
        });
        return;
      }

      final list = decoded['data'] as List? ?? [];
      final items = <_InboxItem>[];
      for (final item in list) {
        if (item is Map) {
          final i = _InboxItem.fromJson(Map<String, dynamic>.from(item));
          if (i != null) items.add(i);
        }
      }

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat: $e';
        _loading = false;
      });
    }
  }

  void _handleAction(_InboxItem item) {
    final nav = JagatFilmApp.navigatorKey.currentState;
    if (nav == null) return;

    final action = item.action;
    if (action.isEmpty) return;

    if (action == 'external' && item.externalUrl.isNotEmpty) {
      final uri = Uri.tryParse(item.externalUrl);
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    switch (action) {
      case 'page:search':
        nav.push(MaterialPageRoute(builder: (_) => const SearchScreen()));
        break;
      case 'page:login':
        nav.push(MaterialPageRoute(builder: (_) => const LoginScreen()));
        break;
      case 'page:home':
      case 'page:profile':
      case 'page:update':
        // Pop back to main shell for these.
        nav.popUntil((route) => route.isFirst);
        break;
    }
  }

  String _timeAgo(String publishedAt) {
    try {
      final dt = DateTime.parse(publishedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error.isNotEmpty
              ? _buildError()
              : _items.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _buildCard(_items[index]),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textTertiary),
          const SizedBox(height: 12),
          Text(_error, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_rounded, size: 56, color: AppTheme.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'Notifikasi tentang drama baru dan promo akan muncul di sini',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_InboxItem item) {
    final hasImage = item.imageUrl.isNotEmpty;
    final hasAction = item.action.isNotEmpty;
    final actionLabel = _actionLabel(item.action);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: InkWell(
        onTap: hasAction ? () => _handleAction(item) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster / image
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 60,
                      height: 80,
                      color: AppTheme.surface,
                      child: const Icon(Icons.image_rounded,
                          color: AppTheme.textTertiary, size: 24),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 60,
                      height: 80,
                      color: AppTheme.surface,
                      child: const Icon(Icons.broken_image_rounded,
                          color: AppTheme.textTertiary, size: 24),
                    ),
                  ),
                ),
              if (hasImage) const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _timeAgo(item.publishedAt),
                          style: const TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (hasAction)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              actionLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'page:search':
        return 'Cari';
      case 'page:home':
        return 'Lihat';
      case 'page:login':
        return 'Login';
      case 'page:update':
        return 'Update';
      case 'page:profile':
        return 'Profil';
      case 'external':
        return 'Buka';
      default:
        return 'Tonton';
    }
  }
}

class _InboxItem {
  final String id;
  final String title;
  final String message;
  final String imageUrl;
  final String action;
  final String externalUrl;
  final String publishedAt;

  _InboxItem({
    required this.id,
    required this.title,
    required this.message,
    required this.imageUrl,
    required this.action,
    required this.externalUrl,
    required this.publishedAt,
  });

  static _InboxItem? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final title = (json['title'] as String?)?.trim() ?? '';
    final message = (json['message'] as String?)?.trim() ?? '';
    if (id.isEmpty || title.isEmpty) return null;
    return _InboxItem(
      id: id,
      title: title,
      message: message,
      imageUrl: (json['image_url'] as String?)?.trim() ?? '',
      action: (json['action'] as String?)?.trim() ?? '',
      externalUrl: (json['external_url'] as String?)?.trim() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
    );
  }
}
