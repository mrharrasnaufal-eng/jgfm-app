import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _versionUrl = 'https://jagatfilm.com/app/version.json';

  /// Check for app update and show dialog if available
  /// Call this from initState with addPostFrameCallback
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;

      // Fetch remote version info
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final body = response.body;
      if (body.isEmpty) return;

      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return;

      final remoteVersionCode = json['versionCode'] as int? ?? 0;
      final remoteVersion = json['version'] as String? ?? '';
      final apkUrl = json['apk_url'] as String? ?? '';
      final changelog = json['changelog'] as String? ?? '';
      final forceUpdate = json['force_update'] as bool? ?? false;

      // Compare versions
      if (remoteVersionCode <= currentVersionCode) return;

      // Update available - show dialog
      if (!context.mounted) return;

      _showUpdateDialog(
        context,
        version: remoteVersion,
        changelog: changelog,
        apkUrl: apkUrl,
        forceUpdate: forceUpdate,
      );
    } catch (_) {
      // Silently fail - don't crash the app
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
              // Version info
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

              // Changelog
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

              // Instructions
              Text(
                'Silakan unduh dan install APK terbaru untuk mendapatkan fitur dan perbaikan terbaru.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          actions: [
            // "Nanti" button - only if not force update
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text('Nanti', style: TextStyle(color: Colors.grey[500])),
              ),
            // "Update Sekarang" button
            FilledButton.icon(
              onPressed: () => _openUpdateUrl(ctx, apkUrl),
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

  static Future<void> _openUpdateUrl(
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
            content: Text('Gagal membuka browser untuk download'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
