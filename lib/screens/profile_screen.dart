import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    if (!auth.isLoggedIn) {
      // Not logged in - show login prompt + update button
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 80, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Belum login',
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Masuk'),
              ),
              const SizedBox(height: 32),
              // Cek update button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdateScreen()),
                  );
                },
                icon: const Icon(Icons.system_update_rounded, size: 20),
                label: const Text('Cek Pembaruan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.grey[700]!),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = auth.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showLogoutDialog(context, auth),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withAlpha(50),
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 40,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Info cards
          _buildInfoCard(context,
              icon: Icons.email_outlined, title: 'Email', value: user.email),
          _buildInfoCard(context,
              icon: Icons.card_membership_outlined,
              title: 'Paket',
              value: user.currentPlanName ?? 'Free Plan'),

          const SizedBox(height: 24),

          // Cek Pembaruan button
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpdateScreen()),
                );
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFF1A1A2E),
              leading: const Icon(Icons.system_update_rounded,
                  color: Color(0xFF6C63FF)),
              title: const Text('Cek Pembaruan'),
              subtitle: Text('Periksa versi terbaru aplikasi',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),

          const SizedBox(height: 16),

          // App info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text('Tentang Aplikasi',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Developer', 'JagatFilm Team'),
                _buildInfoRow('Website', 'jagatfilm.com'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

/// Halaman Cek Pembaruan
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _isChecking = true;
  String _currentVersion = '';
  String _currentCode = '';
  String? _newVersion;
  String? _changelog;
  String? _apkUrl;
  String? _error;
  bool _isUpToDate = false;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isChecking = true;
      _error = null;
      _isUpToDate = false;
      _newVersion = null;
    });

    try {
      final appInfo = await UpdateService.getAppVersion();
      _currentVersion = appInfo['version'] ?? '?';
      _currentCode = appInfo['code'] ?? '0';

      final result = await UpdateService.getUpdateInfo();

      if (result == null) {
        setState(() {
          _isUpToDate = true;
          _isChecking = false;
        });
        return;
      }

      final currentCode = int.tryParse(_currentCode) ?? 0;
      final remoteCode = result['versionCode'] as int? ?? 0;

      if (remoteCode > currentCode) {
        setState(() {
          _newVersion = result['version'] as String? ?? '';
          _changelog = result['changelog'] as String? ?? '';
          _apkUrl = result['apk_url'] as String? ?? '';
          _isChecking = false;
        });
      } else {
        setState(() {
          _isUpToDate = true;
          _isChecking = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memeriksa pembaruan: $e';
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Pembaruan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isChecking) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6C63FF)),
          const SizedBox(height: 16),
          const Text('Memeriksa pembaruan...',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Versi saat ini: $_currentVersion',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 16),
          FilledButton(onPressed: _checkUpdate, child: const Text('Coba Lagi')),
        ],
      );
    }

    if (_isUpToDate) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Aplikasi sudah terbaru!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Versi $_currentVersion (build $_currentCode)',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _checkUpdate,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Periksa Lagi'),
          ),
        ],
      );
    }

    // Update tersedia
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.system_update_rounded,
            size: 64, color: Color(0xFF6C63FF)),
        const SizedBox(height: 16),
        const Text('Update Tersedia!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Versi $_newVersion',
              style: const TextStyle(
                  color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        if (_changelog != null && _changelog!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perubahan:',
                    style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_changelog!,
                    style: TextStyle(color: Colors.grey[300], fontSize: 13)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('Versi saat ini: $_currentVersion (build $_currentCode)',
            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            if (_apkUrl != null && _apkUrl!.isNotEmpty) {
              UpdateService.openDownloadUrl(context, _apkUrl!);
            }
          },
          icon: const Icon(Icons.download_rounded),
          label: const Text('Update Sekarang'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Nanti', style: TextStyle(color: Colors.grey[500])),
        ),
      ],
    );
  }
}
