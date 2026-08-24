import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coin_transaction.dart';

/// Fungsional coin service — connects to backend API.
/// Device ID based (no login required to earn).
/// Login required only for withdrawal.
class CoinService extends ChangeNotifier {
  static const String _baseUrl = 'https://jagatfilm.com/api/coins';
  static const String _deviceIdKey = 'jgfm_device_id';
  static const int maxDailyAds = 50;

  String? _deviceId;
  int _balance = 0;
  int _totalEarned = 0;
  int _dailyAdCount = 0;
  int _dailyRemaining = 50;
  bool _isLoading = false;
  String? _lastError;
  List<CoinTransaction> _transactions = [];

  // Getters
  String? get deviceId => _deviceId;
  int get balance => _balance;
  int get totalEarned => _totalEarned;
  int get dailyAdCount => _dailyAdCount;
  int get dailyRemaining => _dailyRemaining;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  List<CoinTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isActive => true; // Connected to real backend

  /// Format balance as Rupiah equivalent.
  String get balanceRupiah => 'Rp ${_balance.toStringAsFixed(0)}';

  CoinService() {
    _init();
  }

  /// Initialize: generate/load device_id, fetch balance.
  Future<void> _init() async {
    await _loadOrCreateDeviceId();
    await fetchBalance();
  }

  /// Generate a unique device_id on first install, persist in SharedPreferences.
  Future<void> _loadOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString(_deviceIdKey);

      if (_deviceId == null || _deviceId!.length < 10) {
        // Generate UUID-like device ID
        final now = DateTime.now().millisecondsSinceEpoch;
        final random = now.hashCode.toRadixString(36);
        _deviceId = 'jgfm_${now}_$random';
        await prefs.setString(_deviceIdKey, _deviceId!);
      }
    } catch (_) {
      // Fallback: generate ephemeral ID (will be lost on restart)
      _deviceId = 'jgfm_${DateTime.now().millisecondsSinceEpoch}_fallback';
    }
  }

  /// Fetch current balance from server.
  Future<void> fetchBalance() async {
    if (_deviceId == null) return;

    try {
      final uri = Uri.parse('$_baseUrl/balance?device_id=$_deviceId');
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          _balance = json['balance'] as int? ?? 0;
          _totalEarned = json['total_earned'] as int? ?? 0;
          _dailyAdCount = json['daily_ad_count'] as int? ?? 0;
          _dailyRemaining = json['daily_remaining'] as int? ?? 50;
          _lastError = null;
          notifyListeners();
        }
      }
    } catch (_) {
      // Silent fail — show cached data
    }
  }

  /// Earn coins from watching an ad. Returns true if successful.
  Future<bool> earnFromAd() async {
    if (_deviceId == null) return false;
    if (_dailyRemaining <= 0) {
      _lastError = 'Batas harian tercapai (50 iklan/hari)';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/earn');
      final response = await http.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': _deviceId,
          'type': 'ad_reward',
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        _balance = json['balance'] as int? ?? _balance;
        _dailyRemaining = json['daily_remaining'] as int? ?? _dailyRemaining;
        _dailyAdCount++;
        _totalEarned += json['amount'] as int? ?? 1;
        _isLoading = false;
        _lastError = null;
        notifyListeners();
        return true;
      } else {
        _lastError = json['error'] as String? ?? 'Gagal mendapat koin';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = 'Koneksi gagal';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Earn coins from daily login.
  Future<bool> claimDailyLogin() async {
    if (_deviceId == null) return false;

    try {
      final uri = Uri.parse('$_baseUrl/earn');
      final response = await http.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': _deviceId,
          'type': 'daily_login',
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        _balance = json['balance'] as int? ?? _balance;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Link device coins to user account (called on login).
  Future<bool> linkToUser(String userId) async {
    if (_deviceId == null) return false;

    try {
      final uri = Uri.parse('$_baseUrl/link');
      final response = await http.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': _deviceId,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        await fetchBalance();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Request withdrawal (requires login).
  Future<Map<String, dynamic>> requestWithdrawal({
    required String userId,
    required int amountCoins,
    required String method,
    required String accountInfo,
    String? accountName,
  }) async {
    if (_deviceId == null) {
      return {'success': false, 'error': 'Device not initialized'};
    }

    try {
      final uri = Uri.parse('$_baseUrl/withdraw');
      final response = await http.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': _deviceId,
          'user_id': userId,
          'amount_coins': amountCoins,
          'method': method,
          'account_info': accountInfo,
          'account_name': accountName ?? '',
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        _balance = json['balance'] as int? ?? _balance;
        notifyListeners();
      }
      return json as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Koneksi gagal'};
    }
  }

  /// Fetch transaction history.
  Future<void> fetchHistory() async {
    if (_deviceId == null) return;

    try {
      final uri = Uri.parse('$_baseUrl/history?device_id=$_deviceId&limit=20');
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final data = json['data'] as List<dynamic>? ?? [];
          _transactions = data.map((e) {
            return CoinTransaction(
              id: '',
              type: _parseType(e['type'] as String? ?? ''),
              amount: e['amount'] as int? ?? 0,
              description: e['description'] as String? ?? '',
              createdAt: DateTime.tryParse(e['created_at']?.toString() ?? ''),
            );
          }).toList();
          notifyListeners();
        }
      }
    } catch (_) {
      // Silent fail
    }
  }

  CoinTransactionType _parseType(String type) {
    switch (type) {
      case 'ad_reward':
        return CoinTransactionType.adReward;
      case 'daily_login':
        return CoinTransactionType.dailyLogin;
      case 'mission':
        return CoinTransactionType.mission;
      case 'withdrawal':
        return CoinTransactionType.withdrawal;
      default:
        return CoinTransactionType.adminAdjust;
    }
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'User-Agent': 'JagatFilm-Android/2.3',
      };
}
