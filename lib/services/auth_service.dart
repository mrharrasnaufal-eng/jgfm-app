import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'https://jagatfilm.com';

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _google {
    _googleSignIn ??= GoogleSignIn(scopes: ['email', 'profile']);
    return _googleSignIn!;
  }

  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null;
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
      } catch (_) {
        await logout();
      }
    }
  }

  /// Login with Google
  Future<String?> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return 'Login dibatalkan';
      }

      // Login berhasil dengan Google
      _token = 'google_${googleUser.id}';
      _user = User(
        uid: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName ?? googleUser.email.split('@')[0],
        photoURL: googleUser.photoUrl,
        isVip: false,
        currentPlanName: 'Free Plan',
      );
      await _saveUser();

      // Simpan juga ke local accounts agar konsisten
      final prefs = await SharedPreferences.getInstance();
      final accounts = _getLocalAccounts(prefs);
      final existing = accounts.any((a) => a['email'] == googleUser.email);
      if (!existing) {
        accounts.add({
          'uid': googleUser.id,
          'email': googleUser.email,
          'displayName': googleUser.displayName ?? googleUser.email.split('@')[0],
          'photoURL': googleUser.photoUrl ?? '',
          'provider': 'google',
        });
        await prefs.setString('local_accounts', jsonEncode(accounts));
      }

      _isLoading = false;
      notifyListeners();
      return null; // success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // ApiException 10 = SHA-1 not registered in Google Cloud Console
      final errorStr = e.toString();
      if (errorStr.contains('ApiException: 10') ||
          errorStr.contains('sign_in_failed')) {
        return 'Login Google belum dikonfigurasi. Silakan gunakan email/password.';
      }
      if (errorStr.contains('network_error') ||
          errorStr.contains('NetworkError')) {
        return 'Tidak ada koneksi internet.';
      }
      return 'Gagal login dengan Google. Silakan gunakan email/password.';
    }
  }

  /// Login with email and password
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Coba koneksi ke backend auth jika tersedia
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          _token = json['token'];
          _user = User.fromJson(json['user']);
          await _saveUser();
          _isLoading = false;
          notifyListeners();
          return null;
        }
        _isLoading = false;
        notifyListeners();
        return json['error'] ?? 'Login gagal';
      } else if (response.statusCode == 401) {
        _isLoading = false;
        notifyListeners();
        final json = jsonDecode(response.body);
        return json['error'] ?? 'Email atau password salah';
      }
    } catch (_) {
      // Backend tidak tersedia - gunakan local auth
    }

    // Fallback: Local auth
    final prefs = await SharedPreferences.getInstance();
    final accounts = _getLocalAccounts(prefs);

    final account = accounts.firstWhere(
      (a) => a['email'] == email && a['provider'] != 'google',
      orElse: () => {},
    );

    if (account.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
    }

    if (account['password'] != _hashPassword(password)) {
      _isLoading = false;
      notifyListeners();
      return 'Password salah';
    }

    // Login sukses (local)
    _token = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _user = User(
      uid: account['uid'] ?? '',
      email: email,
      displayName: account['displayName'] ?? email.split('@')[0],
      isVip: false,
      currentPlanName: 'Free Plan',
    );
    await _saveUser();
    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Register new account
  Future<String?> register(String email, String password, String displayName) async {
    _isLoading = true;
    notifyListeners();

    // Coba koneksi ke backend auth jika tersedia
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          _token = json['token'];
          _user = User.fromJson(json['user']);
          await _saveUser();
          _isLoading = false;
          notifyListeners();
          return null;
        }
        _isLoading = false;
        notifyListeners();
        return json['error'] ?? 'Registrasi gagal';
      } else if (response.statusCode == 409) {
        _isLoading = false;
        notifyListeners();
        return 'Email sudah terdaftar';
      }
    } catch (_) {
      // Backend tidak tersedia - gunakan local auth
    }

    // Fallback: Local auth
    final prefs = await SharedPreferences.getInstance();
    final accounts = _getLocalAccounts(prefs);

    // Cek duplicate
    final existing = accounts.any(
        (a) => a['email'] == email && a['provider'] != 'google');
    if (existing) {
      _isLoading = false;
      notifyListeners();
      return 'Email sudah terdaftar';
    }

    // Simpan akun baru
    final uid = 'local_${DateTime.now().millisecondsSinceEpoch}';
    accounts.add({
      'uid': uid,
      'email': email,
      'password': _hashPassword(password),
      'displayName': displayName,
      'provider': 'email',
    });
    await prefs.setString('local_accounts', jsonEncode(accounts));

    // Auto login setelah register
    _token = 'local_$uid';
    _user = User(
      uid: uid,
      email: email,
      displayName: displayName,
      isVip: false,
      currentPlanName: 'Free Plan',
    );
    await _saveUser();
    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Logout
  Future<void> logout() async {
    // Sign out Google juga
    try {
      await _google.signOut();
    } catch (_) {}

    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    notifyListeners();
  }

  /// Get local accounts from SharedPreferences
  List<Map<String, dynamic>> _getLocalAccounts(SharedPreferences prefs) {
    final raw = prefs.getString('local_accounts');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
    return [];
  }

  /// Simple password hash
  String _hashPassword(String password) {
    int hash = 0;
    for (int i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return 'h${hash.toRadixString(16)}';
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
