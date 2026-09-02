import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Analytics service — kirim heartbeat device ke backend untuk tracking:
/// install (device_id + versi + model + os) + frekuensi online + status online.
/// Best-effort: TIDAK boleh crash / mengganggu startup.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  static const MethodChannel _channel =
      MethodChannel('com.jagatfilm.jagatfilm/notifications');

  static const String _deviceIdKey = 'jgfm_device_id';
  static const String _endpoint = 'https://www.jagatfilm.com/api/app/heartbeat';

  Timer? _timer;
  bool _started = false;
  bool _sessionSent = false;

  String? _deviceId;
  String _version = '';
  String _model = '';
  String _os = '';

  /// Panggil sekali setelah startup (setelah remote config load).
  /// Kirim session heartbeat + mulai heartbeat periodik tiap 5 menit.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      _version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}

    try {
      final info = await _channel.invokeMethod<Map>('getDeviceInfo');
      if (info != null) {
        _model = (info['model'] ?? '').toString();
        _os = (info['os'] ?? '').toString();
      }
    } catch (_) {}

    await _send(session: true);

    // Retry cepat bila device_id belum siap (first install — CoinService generate async).
    Timer(const Duration(seconds: 10), () async {
      if (!_sessionSent) await _send(session: true);
    });

    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _send(session: false);
    });
  }

  Future<void> _send({required bool session}) async {
    // Baca device_id (dibuat CoinService, disimpan di SharedPreferences).
    if (_deviceId == null || _deviceId!.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _deviceId = prefs.getString(_deviceIdKey);
      } catch (_) {}
    }
    if (_deviceId == null || _deviceId!.isEmpty) return;

    try {
      await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device_id': _deviceId,
              'app_version': _version,
              'device_model': _model,
              'os_version': _os,
              'session': session,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (session) _sessionSent = true;
    } catch (_) {
      // Analytics best-effort — abaikan semua error.
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
