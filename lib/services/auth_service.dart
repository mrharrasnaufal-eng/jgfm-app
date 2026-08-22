import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'https://jagatfilm.com';
  // Auth backend on port 3001 (may not be running)
  // Fallback: store locally
  static const String _authUrl = '$_baseUrl:3001';

  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null && _token != null;
  bool get isLoading => _isLoading;
  bool get isVip => _user?.isVip ?? false;

  /// Load saved user from SharedPreferences
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final savedToken = prefs.getString('token');

    if (userJson != null && savedToken != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson));
        _token = savedToken;
        notifyListeners();

        // Verify token is still valid
        await _refreshProfile();
      } catch (_) {
        await logout();
      }
    }
  }

  /// Login with email and password
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_authUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          _token = json['token'];
          _user = User.fromJson(json['user']);
          await _saveUser();
          _isLoading = false;
          notifyListeners();
          return null; // success
        }
        _isLoading = false;
        notifyListeners();
        return json['error'] ?? 'Login gagal';
      } else {
        final json = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return json['error'] ?? 'Login gagal (${response.statusCode})';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Server tidak dapat dihubungi. Coba lagi nanti.';
    }
  }

  /// Register new account
  Future<String?> register(String email, String password, String displayName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_authUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          _token = json['token'];
          _user = User.fromJson(json['user']);
          await _saveUser();
          _isLoading = false;
          notifyListeners();
          return null; // success
        }
        _isLoading = false;
        notifyListeners();
        return json['error'] ?? 'Registrasi gagal';
      } else {
        final json = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return json['error'] ?? 'Registrasi gagal (${response.statusCode})';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Server tidak dapat dihubungi. Coba lagi nanti.';
    }
  }

  /// Logout
  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    notifyListeners();
  }

  /// Refresh profile from server
  Future<void> _refreshProfile() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_authUrl/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['user'] != null) {
          _user = User.fromJson(json['user']);
          await _saveUser();
          notifyListeners();
        }
      } else if (response.statusCode == 401) {
        // Token expired
        await logout();
      }
    } catch (_) {
      // Server unreachable — keep local data
    }
  }

  Future<void> _saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user != null) {
      await prefs.setString('user', jsonEncode(_user!.toJson()));
    }
    if (_token != null) {
      await prefs.setString('token', _token!);
    }
  }
}
