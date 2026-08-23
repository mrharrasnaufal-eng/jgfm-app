import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _versionUrl = 'https://jagatfilm.com/app/version.json';

  /// Get update info from server. Returns null if failed.
  static Future<Map<String, dynamic>?> getUpdateInfo() async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = response.body;
      if (body.isEmpty) return null;

      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;

      return json;
    } catch (_) {
      return null;
    }
  }

  /// Open download URL in browser
  static Future<void> openDownloadUrl(BuildContext context, String apkUrl) async {
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
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;

      final json = await getUpdateInfo();
      if (json == null) return;

      final remoteVersionCode = json['versionCode'] as int? ?? 0;
      final remoteVersion = json['version'] as String? ?? '';
      final apkUrl = json['apk_url'] as String? ?? '';
      final changelog = json['changelog'] as String? ?? '';
      final forceUpdate = json['force_update'] as bool? ?? false;

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
      // Silently fail
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
