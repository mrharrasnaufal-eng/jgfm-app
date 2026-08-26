import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A single notification item delivered from MasterPanel.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String imageUrl;
  final String action;
  final String externalUrl;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.imageUrl,
    required this.action,
    required this.externalUrl,
  });

  static const Set<String> _allowedActions = {
    '',
    'page:home',
    'page:search',
    'page:profile',
    'page:update',
    'page:login',
    'external',
  };

  static String _text(dynamic value, {int maxLength = 500}) {
    if (value is! String) return '';
    final normalized = value.trim();
    if (normalized.isEmpty) return '';
    return normalized.length <= maxLength
        ? normalized
        : normalized.substring(0, maxLength);
  }

  static String _httpUrl(dynamic value) {
    if (value is! String) return '';
    final normalized = value.trim();
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return '';
    if (uri.scheme != 'http' && uri.scheme != 'https') return '';
    return normalized;
  }

  static String _action(dynamic value) {
    if (value is! String) return '';
    final normalized = value.trim().toLowerCase();
    return _allowedActions.contains(normalized) ? normalized : '';
  }

  /// Parse from JSON. Returns null if the payload is malformed / missing core fields.
  static AppNotification? fromJson(Map<String, dynamic> json) {
    final id = _text(json['id'], maxLength: 64);
    final title = _text(json['title'], maxLength: 200);
    final message = _text(json['message'], maxLength: 2000);
    if (id.isEmpty || title.isEmpty || message.isEmpty) return null;

    final action = _action(json['action']);
    return AppNotification(
      id: id,
      title: title,
      message: message,
      imageUrl: _httpUrl(json['image_url']),
      action: action,
      externalUrl: action == 'external' ? _httpUrl(json['external_url']) : '',
    );
  }
}

/// NotificationService — Fase 1 local notifications (no Firebase).
///
/// Flow (all wrapped in try-catch, must NEVER crash the app):
/// 1. init() the plugin + request POST_NOTIFICATIONS permission.
/// 2. fetch active notifications from MasterPanel.
/// 3. dedupe against IDs already shown (SharedPreferences).
/// 4. show new ones as local notifications in the status bar.
/// 5. on tap, the notification payload (action) is stored so the app can navigate.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _endpoint =
      'https://masterpanel.jagatfilm.com/api/notifications';
  static const String _shownIdsKey = 'shown_notification_ids';
  static const String _pendingActionKey = 'pending_notification_action';
  static const int _maxShownIds = 200;

  static const String _channelId = 'jagatfilm_general';
  static const String _channelName = 'Notifikasi JagatFilm';
  static const String _channelDesc =
      'Info drama baru, event, dan promosi JagatFilm';

  /// MethodChannel for native custom notification (DramaBox-style layout).
  static const MethodChannel _nativeChannel =
      MethodChannel('com.jagatfilm.jagatfilm/notifications');

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Expose the plugin instance so FCMService can reuse it for foreground notifications.
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// The action captured from the most recent notification tap (if any).
  /// main.dart reads and clears this to perform navigation.
  static String? tappedAction;

  /// Initialize the plugin and request permission. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onTap,
      );

      // Create the Android channel explicitly (Android 8+).
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.defaultImportance,
          ),
        );
        // Request POST_NOTIFICATIONS (Android 13+). No-op on older versions.
        await androidImpl.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    tappedAction = payload;
    // Persist so navigation can happen even after a cold start via tap.
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_pendingActionKey, payload))
        .catchError((_) => false);
  }

  /// Fetch active notifications, show any that haven't been shown yet.
  /// Non-blocking friendly: caller should not await if startup must stay fast,
  /// but awaiting is fine — everything is guarded.
  Future<void> checkAndShow() async {
    try {
      if (!_initialized) await init();

      final uri = Uri.parse(_endpoint).replace(queryParameters: {
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'User-Agent': 'JagatFilm-Android/notif',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 ||
          response.body.isEmpty ||
          response.body.length > 200000) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != true) return;
      final list = decoded['data'];
      if (list is! List) return;

      final notifications = <AppNotification>[];
      for (final item in list) {
        if (item is Map) {
          final parsed =
              AppNotification.fromJson(Map<String, dynamic>.from(item));
          if (parsed != null) notifications.add(parsed);
        }
      }
      if (notifications.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final shownIds = prefs.getStringList(_shownIdsKey) ?? <String>[];
      final shownSet = shownIds.toSet();

      var idCounter =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      for (final notif in notifications) {
        if (shownSet.contains(notif.id)) continue;

        await _show(idCounter++, notif);
        shownIds.add(notif.id);
        shownSet.add(notif.id);
      }

      // Trim stored IDs to avoid unbounded growth.
      final trimmed = shownIds.length > _maxShownIds
          ? shownIds.sublist(shownIds.length - _maxShownIds)
          : shownIds;
      await prefs.setStringList(_shownIdsKey, trimmed);
    } catch (e) {
      debugPrint('NotificationService.checkAndShow error: $e');
      // Never rethrow — notifications are optional.
    }
  }

  Future<void> _show(int notifId, AppNotification notif) async {
    try {
      // Payload = action (page:xxx | external:<url>). Empty = just open app.
      String payload = notif.action;
      if (notif.action == 'external' && notif.externalUrl.isNotEmpty) {
        payload = 'external:${notif.externalUrl}';
      }

      // Try native custom notification (DramaBox-style: poster + text + pink button).
      bool nativeSuccess = false;
      try {
        final result = await _nativeChannel.invokeMethod('showCustomNotification', {
          'id': notifId,
          'title': notif.title,
          'message': notif.message,
          'image_url': notif.imageUrl.isNotEmpty ? notif.imageUrl : null,
          'action': payload.isNotEmpty ? payload : null,
        });
        nativeSuccess = result == true;
      } catch (e) {
        debugPrint('Native notification failed (using fallback): $e');
      }

      // Fallback: flutter_local_notifications (standard style).
      if (!nativeSuccess) {
        StyleInformation styleInfo;
        if (notif.imageUrl.isNotEmpty) {
          ByteArrayAndroidBitmap? bigPicture;
          try {
            final imgResponse = await http.get(
              Uri.parse(notif.imageUrl),
            ).timeout(const Duration(seconds: 5));
            if (imgResponse.statusCode == 200 && imgResponse.bodyBytes.isNotEmpty) {
              bigPicture = ByteArrayAndroidBitmap(imgResponse.bodyBytes);
            }
          } catch (_) {}

          if (bigPicture != null) {
            styleInfo = BigPictureStyleInformation(
              bigPicture,
              largeIcon: bigPicture,
              contentTitle: notif.title,
              summaryText: notif.message,
              hideExpandedLargeIcon: false,
            );
          } else {
            styleInfo = BigTextStyleInformation(notif.message);
          }
        } else {
          styleInfo = BigTextStyleInformation(notif.message);
        }

        final androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: styleInfo,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'action_open',
              'Tonton',
              showsUserInterface: true,
            ),
          ],
        );
        final details = NotificationDetails(android: androidDetails);

        await _plugin.show(
          notifId,
          notif.title,
          notif.message,
          details,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('NotificationService._show error: $e');
    }
  }

  /// Read (and clear) any pending tap action captured before the app was ready.
  Future<String?> consumePendingAction() async {
    try {
      final inMemory = tappedAction;
      if (inMemory != null && inMemory.isNotEmpty) {
        tappedAction = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_pendingActionKey);
        return inMemory;
      }

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_pendingActionKey);
      if (stored != null && stored.isNotEmpty) {
        await prefs.remove(_pendingActionKey);
        return stored;
      }
    } catch (e) {
      debugPrint('NotificationService.consumePendingAction error: $e');
    }
    return null;
  }
}
