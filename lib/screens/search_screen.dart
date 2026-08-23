import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import '../widgets/drama_card_grid.dart';
import '../widgets/shimmer_grid.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _historyKey = 'search_history';
  static const int _maxHistory = 10;

  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<Drama> _results = [];
  List<String> _trendingTitles = [];
  List<String> _history = [];
  Map<String, int> _viewCounts = {};
  bool _isLoading = false;
  bool _isTrendingLoading = true;
  bool _hasSearched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _fetchTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // === HISTORY ===

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _history = prefs.getStringList(_historyKey) ?? [];
      });
    } catch (_) {}
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _history.remove(query);
      _history.insert(0, query);
      if (_history.length > _maxHistory) {
        _history = _history.sublist(0, _maxHistory);
      }
      await prefs.setStringList(_historyKey, _history);
      setState(() {});
    } catch (_) {}
  }

  Future<void> _removeFromHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _history.remove(query);
      await prefs.setStringList(_historyKey, _history);
      setState(() {});
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      setState(() {
        _history = [];
      });
    } catch (_) {}
  }

  // === TRENDING ===

  Future<void> _fetchTrending() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/dramas/trending?days=7&limit=10');
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'JagatFilm-Android/1.0',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null) {
          final titles = <String>[];
          for (final item in json['data'] as List) {
            final title = item['title']?.toString() ?? '';
            if (title.isNotEmpty) {
              titles.add(title);
            }
          }
          setState(() {
            _trendingTitles = titles;
            _isTrendingLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _isTrendingLoading = false);
  }

  // === SEARCH ===

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 2) {
        _performSearch(query.trim());
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final results = await _api.searchDramas(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _triggerSearch(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _saveToHistory(query);
    _performSearch(query);
  }

  void _onDramaTap(Drama drama) {
    _saveToHistory(drama.title);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(drama: drama)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: _buildSearchField(),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      autofocus: true,
      onChanged: _onSearchChanged,
      onSubmitted: (q) {
        if (q.trim().length >= 2) {
          _saveToHistory(q.trim());
          _performSearch(q.trim());
        }
      },
      style: const TextStyle(
        fontSize: AppFontSize.h3,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Cari drama...',
        hintStyle: const TextStyle(
          color: AppTheme.textTertiary,
          fontSize: AppFontSize.h3,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.textTertiary,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _results = [];
                    _hasSearched = false;
                    _error = null;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasSearched) {
      return _buildSearchResults();
    }
    return _buildIdleContent();
  }

  // === IDLE: Trending + History ===

  Widget _buildIdleContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending section
          _buildTrendingSection(),
          const SizedBox(height: AppSpacing.xl),
          // History section
          if (_history.isNotEmpty) _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🔥',
              style: TextStyle(fontSize: AppFontSize.h3),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Sedang Trending',
              style: TextStyle(
                fontSize: AppFontSize.h3,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isTrendingLoading)
          Shimmer.fromColors(
            baseColor: AppTheme.card,
            highlightColor: AppTheme.surface,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: List.generate(
                6,
                (_) => Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          )
        else if (_trendingTitles.isEmpty)
          const Text(
            'Tidak ada data trending',
            style: TextStyle(
              fontSize: AppFontSize.body,
              color: AppTheme.textTertiary,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _trendingTitles.map((title) {
              return ActionChip(
                label: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: AppTheme.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(
                    color: AppTheme.trending.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                onPressed: () => _triggerSearch(title),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🕐',
              style: TextStyle(fontSize: AppFontSize.h3),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Riwayat Pencarian',
                style: TextStyle(
                  fontSize: AppFontSize.h3,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(_history.length, (index) {
          final item = _history[index];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.history_rounded,
              color: AppTheme.textTertiary,
              size: 20,
            ),
            title: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSize.body,
                color: AppTheme.textPrimary,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppTheme.textTertiary,
              ),
              onPressed: () => _removeFromHistory(item),
            ),
            onTap: () => _triggerSearch(item),
          );
        }),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: _clearHistory,
            child: const Text(
              'Hapus Semua',
              style: TextStyle(
                fontSize: AppFontSize.body,
                color: AppTheme.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // === SEARCH RESULTS ===

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const ShimmerGrid(columns: 3, rows: 3);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                AppStrings.errorLoad,
                style: TextStyle(
                  fontSize: AppFontSize.h3,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppFontSize.body,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: () => _performSearch(_searchController.text.trim()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(AppStrings.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_outlined,
                size: 64,
                color: AppTheme.textTertiary.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tidak ditemukan drama dengan kata kunci "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppFontSize.body,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final drama = _results[index];
        return DramaCardGrid(
          drama: drama,
          onTap: () => _onDramaTap(drama),
        );
      },
    );
  }
}
