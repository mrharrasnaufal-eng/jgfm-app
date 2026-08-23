import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_remote_config.dart';

Future<String?> showRemoteConfigPopup(
  BuildContext context,
  AppRemoteConfig config,
) async {
  if (!config.popupEnabled || !config.hasPopupContent) return null;

  BuildContext? dialogContext;
  var dialogOpen = true;

  final dialogFuture = showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      dialogContext = ctx;
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (config.popupImageUrl.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Image.network(
                    config.popupImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (config.popupTitle.isNotEmpty)
                      Text(
                        config.popupTitle,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (config.popupTitle.isNotEmpty &&
                        config.popupMessage.isNotEmpty)
                      const SizedBox(height: 10),
                    if (config.popupMessage.isNotEmpty)
                      Text(
                        config.popupMessage,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          if (config.hasPopupAction)
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(config.popupAction),
              child: Text(
                config.popupAction == 'external' ? 'Buka' : 'Lihat',
              ),
            ),
        ],
      );
    },
  );

  final autoCloseTimer = Timer(
    Duration(seconds: config.popupDurationSeconds),
    () {
      final ctx = dialogContext;
      if (dialogOpen && ctx != null && Navigator.of(ctx).canPop()) {
        Navigator.of(ctx).pop();
      }
    },
  );

  try {
    return await dialogFuture;
  } finally {
    dialogOpen = false;
    autoCloseTimer.cancel();
  }
}
