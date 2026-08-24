import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watchlist_item.dart';

/// Service to manage the user's watchlist (local SharedPreferences).
class WatchlistService extends ChangeNotifier {
  static const String _storageKey = 'watchlist_items';

  List<WatchlistItem> _items = [];
  bool _loaded = false;

  List<WatchlistItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isLoaded => _loaded;

  WatchlistService() {
    _load();
  }

  /// Check if a drama is in the watchlist.
  bool isInWatchlist(String dramaId) {
    return _items.any((item) => item.dramaId == dramaId);
  }

  /// Get a watchlist item by drama ID, or null if not found.
  WatchlistItem? getItem(String dramaId) {
    try {
      return _items.firstWhere((item) => item.dramaId == dramaId);
    } catch (_) {
      return null;
    }
  }

  /// Add a drama to the watchlist.
  Future<void> add(WatchlistItem item) async {
    // Don't add duplicates — update instead
    final existingIndex =
        _items.indexWhere((i) => i.dramaId == item.dramaId);
    if (existingIndex >= 0) {
      _items[existingIndex] = item;
    } else {
      _items.insert(0, item); // newest first
    }
    notifyListeners();
    await _save();
  }

  /// Remove a drama from the watchlist.
  Future<void> remove(String dramaId) async {
    _items.removeWhere((item) => item.dramaId == dramaId);
    notifyListeners();
    await _save();
  }

  /// Update the last watched episode for a drama in the watchlist.
  Future<void> updateProgress(String dramaId, int lastEpisode) async {
    final index = _items.indexWhere((i) => i.dramaId == dramaId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(lastEpisode: lastEpisode);
      notifyListeners();
      await _save();
    }
  }

  /// Clear all watchlist items.
  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();
    await _save();
  }

  /// Load watchlist from SharedPreferences.
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _items = decoded
            .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Load failure is non-critical — start with empty list
    }
    _loaded = true;
    notifyListeners();
  }

  /// Save watchlist to SharedPreferences.
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
