import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watch_history.dart';

/// Service to manage watch history (local SharedPreferences).
/// Keeps the most recent 50 entries.
class HistoryService extends ChangeNotifier {
  static const String _storageKey = 'watch_history';
  static const int _maxEntries = 50;

  List<WatchHistory> _items = [];
  bool _loaded = false;

  List<WatchHistory> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isLoaded => _loaded;

  HistoryService() {
    _load();
  }

  /// Record a watch event. If the same drama+episode already exists,
  /// update its timestamp instead of adding a duplicate.
  Future<void> record({
    required String dramaId,
    required String title,
    required String cover,
    required String genre,
    required String source,
    required int episode,
    required int totalEpisodes,
  }) async {
    // Remove existing entry for same drama (we'll re-add at top)
    _items.removeWhere(
        (item) => item.dramaId == dramaId && item.episode == episode);

    final entry = WatchHistory(
      dramaId: dramaId,
      title: title,
      cover: cover,
      genre: genre,
      source: source,
      episode: episode,
      totalEpisodes: totalEpisodes,
    );

    _items.insert(0, entry); // newest first

    // Trim to max entries
    if (_items.length > _maxEntries) {
      _items = _items.sublist(0, _maxEntries);
    }

    notifyListeners();
    await _save();
  }

  /// Get the last watched episode for a drama (or null).
  int? getLastEpisode(String dramaId) {
    try {
      final item = _items.firstWhere((i) => i.dramaId == dramaId);
      return item.episode;
    } catch (_) {
      return null;
    }
  }

  /// Remove a single history entry.
  Future<void> removeEntry(String dramaId, int episode) async {
    _items.removeWhere(
        (item) => item.dramaId == dramaId && item.episode == episode);
    notifyListeners();
    await _save();
  }

  /// Clear all history.
  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();
    await _save();
  }

  /// Load history from SharedPreferences.
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _items = decoded
            .map((e) => WatchHistory.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Load failure is non-critical
    }
    _loaded = true;
    notifyListeners();
  }

  /// Save history to SharedPreferences.
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Save failure is non-critical
    }
  }
}
