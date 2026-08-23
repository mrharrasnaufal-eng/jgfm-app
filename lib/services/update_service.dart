import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // Use www to avoid 301 redirect (non-www redirects to www via Cloudflare)
  static const String _versionUrl =
      'https://www.jagatfilm.com/app/version.json';

  /// Get current app version safely
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
      // Cache bust: append timestamp to bypass Cloudflare/browser cache
      final cacheBust = DateTime.now().millisecondsSinceEpoch;
      final url = '$_versionUrl?t=$cacheBust';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final body = response.body;
      if (body.isEmpty) return null;

      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;

      // Validate required fields exist
      if (!json.containsKey('versionCode') || !json.containsKey('version')) {
        return null;
      }

      return json;
    } catch (_) {
      return null;
    }
  }

  /// Open download URL in browser
  static Future<void> openDownloadUrl(
      BuildContext context, String apkUrl) async {
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
    if (uri == null) {
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
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  /// Check for app update and show dialog if available (auto-check on app open)
  static Future<void> checkForUpdate(BuildContext context) async {
    // Delay agar app fully loaded dulu
    await Future.delayed(const Duration(seconds: 3));

    try {
      final appInfo = await getAppVersion();
      final currentVersionCode = int.tryParse(appInfo['code'] ?? '0') ?? 0;

      final json = await getUpdateInfo();
      // If null = network error, silently fail (don't show "up to date")
      if (json == null) return;

      final remoteVersionCode = json['versionCode'] as int? ?? 0;
      final remoteVersion = json['version'] as String? ?? '';
      final apkUrl = json['apk_url'] as String? ?? '';
      final changelog = json['changelog'] as String? ?? '';
      final forceUpdate = json['force_update'] as bool? ?? false;

      // Only show dialog if remote is NEWER
      if (remoteVersionCode <= currentVersionCode) return;

      if (!context.mounted) return;

      _showUpdateDialog(
        context,
        version: remoteVersion,
        changelog: changelog,
        apkUrl: apkUrl,
        forceUpdate: forceUpdate,
      );
    } catch (_) {
      // Silently fail - NEVER crash
    }
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String version,
    required String changelog,
    required String apkUrl,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.system_update_rounded, color: Color(0xFF6C63FF)),
              SizedBox(width: 10),
              Text('Update Tersedia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                Text('Perubahan:',
                    style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(changelog,
                    style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                const SizedBox(height: 14),
              ],
              Text(
                'Unduh dan install APK terbaru.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Nanti', style: TextStyle(color: Colors.grey[500])),
              ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                openDownloadUrl(context, apkUrl);
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
