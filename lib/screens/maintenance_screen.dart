import 'package:flutter/material.dart';

import '../models/app_remote_config.dart';

class MaintenanceScreen extends StatefulWidget {
  final AppRemoteConfig config;
  final Future<void> Function() onRetry;

  const MaintenanceScreen({
    super.key,
    required this.config,
    required this.onRetry,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry();
    } catch (_) {
      // Retry errors are handled by the remote-config fallback.
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(context),
                const SizedBox(height: 28),
                const Text(
                  'Sedang Dalam Pemeliharaan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.config.maintenanceMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _isRetrying ? null : _retry,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_isRetrying ? 'Memeriksa...' : 'Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    if (widget.config.logoUrl.isEmpty) {
      return Icon(
        Icons.construction_rounded,
        size: 84,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return SizedBox(
      width: 120,
      height: 120,
      child: Image.network(
        widget.config.logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.construction_rounded,
          size: 84,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
