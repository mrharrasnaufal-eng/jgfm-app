import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _versionUrl =
      'https://www.jagatfilm.com/app/version.json';
  static const String _fallbackApkUrl =
      'https://jagatfilm.com/download/app-release.apk';

  /// Get current app version safely.
  static Future<Map<String, String>> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'code': packageInfo.buildNumber,
      };
    } catch (_) {
      return {'version': '?', 'code': '0'};
    }
  }

  /// Get update info from server.
  /// Returns Map on success, null on network/parse error.
  /// Adds cache-bust query param to bypass any caching layer.
  static Future<Map<String, dynamic>?> getUpdateInfo() async {
    try {
      final cacheBust = DateTime.now().millisecondsSinceEpoch;
      final url = '$_versionUrl?t=$cacheBust';

      final response = await http
          .get(
            Uri.parse(url),
            headers: const {
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;
      if (!json.containsKey('versionCode') || !json.containsKey('version')) {
        return null;
      }

      return json;
    } catch (_) {
      return null;
    }
  }

  /// Compares dotted numeric versions without throwing.
  /// Invalid values are considered safe and never trigger a forced update.
  static bool isVersionBelowMinimum(String current, String minimum) {
    final currentParts = _parseVersion(current);
    final minimumParts = _parseVersion(minimum);
    if (currentParts == null || minimumParts == null) return false;

    final length = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;
    for (var index = 0; index < length; index++) {
      final currentPart =
          index < currentParts.length ? currentParts[index] : 0;
      final minimumPart =
          index < minimumParts.length ? minimumParts[index] : 0;
      if (currentPart < minimumPart) return true;
      if (currentPart > minimumPart) return false;
    }
    return false;
  }

  static List<int>? _parseVersion(String value) {
    final normalized = value.trim().split('+').first.split('-').first;
    if (normalized.isEmpty) return null;

    final parts = normalized.split('.');
    final result = <int>[];
    for (final part in parts) {
      final number = int.tryParse(part);
      if (number == null || number < 0) return null;
      result.add(number);
    }
    return result.isEmpty ? null : result;
  }

  /// Enforces the minimum version received from Remote Config.
  /// Returns true when a minimum-version dialog was shown.
  static Future<bool> checkMinimumVersion(
    BuildContext context, {
    required String minimumVersion,
    required bool forceUpdate,
  }) async {
    try {
      final appInfo = await getAppVersion();
      final currentVersion = appInfo['version'] ?? '';
      if (!isVersionBelowMinimum(currentVersion, minimumVersion)) {
        return false;
      }

      final updateInfo = await getUpdateInfo();
      if (!context.mounted) return false;

      final advertisedVersion =
          updateInfo?['version'] as String? ?? minimumVersion;
      final apkUrl = updateInfo?['apk_url'] as String? ?? _fallbackApkUrl;
      final changelog = updateInfo?['changelog'] as String? ??
          'Versi ini diperlukan agar aplikasi tetap dapat digunakan.';

      await _showUpdateDialog(
        context,
        version: advertisedVersion,
        changelog: changelog,
        apkUrl: apkUrl,
        forceUpdate: forceUpdate,
      );
      return true;
    } catch (_) {
      // Invalid config, plugin, or network errors must never block startup.
      return false;
    }
  }

  /// Open download URL in browser.
  static Future<void> openDownloadUrl(
    BuildContext context,
    String apkUrl,
  ) async {
    if (apkUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL download tidak tersedia'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final uri = Uri.tryParse(apkUrl);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL download tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka browser'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka browser'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check for app update and show dialog if available (auto-check on app open).
  static Future<void> checkForUpdate(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3));

    try {
      final appInfo = await getAppVersion();
      final currentVersionCode = int.tryParse(appInfo['code'] ?? '0') ?? 0;

      final json = await getUpdateInfo();
      if (json == null) return;

      final remoteVersionCode = json['versionCode'] as int? ?? 0;
      final remoteVersion = json['version'] as String? ?? '';
      final apkUrl = json['apk_url'] as String? ?? '';
      final changelog = json['changelog'] as String? ?? '';
      final forceUpdate = json['force_update'] as bool? ?? false;

      if (remoteVersionCode <= currentVersionCode || !context.mounted) return;

      await _showUpdateDialog(
        context,
        version: remoteVersion,
        changelog: changelog,
        apkUrl: apkUrl,
        forceUpdate: forceUpdate,
      );
    } catch (_) {
      // Silently fail - NEVER crash.
    }
  }

  static Future<void> _showUpdateDialog(
    BuildContext context, {
    required String version,
    required String changelog,
    required String apkUrl,
    required bool forceUpdate,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.system_update_rounded,
                color: Color(0xFF6C63FF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  forceUpdate ? 'Update Wajib' : 'Update Tersedia',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Versi terbaru: $version',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (changelog.isNotEmpty) ...[
                Text(
                  'Perubahan:',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  changelog,
                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                forceUpdate
                    ? 'Update diperlukan untuk melanjutkan menggunakan aplikasi.'
                    : 'Unduh dan install APK terbaru.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Nanti',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            FilledButton.icon(
              onPressed: () async {
                if (!forceUpdate) Navigator.pop(ctx);
                await openDownloadUrl(context, apkUrl);
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Update Sekarang'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
