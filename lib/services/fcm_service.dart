import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background message handler (MUST be a top-level function, not a method).
/// Called by FCM when a data/notification message arrives while the app is terminated or in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate.
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM background message: ${message.messageId}');
  // Android automatically shows the notification from the "notification" payload.
  // No extra work needed for display — the system tray handles it.
}

/// FCMService — manages Firebase Cloud Messaging for real-time push notifications.
///
/// Usage:
///   await FCMService.instance.init();
///
/// This integrates with the existing NotificationService (Fase 1) for foreground display.
class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  static const String _tokenKey = 'fcm_token';
  static const String _topicAll = 'all';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  /// The flutter_local_notifications plugin instance (shared with NotificationService Fase 1).
  FlutterLocalNotificationsPlugin? _localNotifPlugin;

  /// Initialize FCM: request permission, get token, subscribe to topic, set up foreground handler.
  Future<void> init({FlutterLocalNotificationsPlugin? localNotifPlugin}) async {
    if (_initialized) return;
    try {
      _localNotifPlugin = localNotifPlugin;

      // Register the background handler.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request notification permission (Android 13+ / iOS).
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Get and store FCM token.
      final token = await _messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        debugPrint('FCM token: ${token.substring(0, 20)}...');
      }

      // Subscribe to the "all" topic (for broadcast push from admin panel).
      await _messaging.subscribeToTopic(_topicAll);
      debugPrint('FCM subscribed to topic: $_topicAll');

      // Listen for foreground messages.
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is opened from terminated state.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Handle notification tap when app is in background (not terminated).
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _initialized = true;
      debugPrint('FCMService initialized');
    } catch (e) {
      debugPrint('FCMService.init error: $e');
      // FCM failure must NEVER crash the app.
    }
  }

  /// Handle a message received while the app is in the foreground.
  /// Since Android doesn't auto-show notifications for foreground messages,
  /// we display it manually using flutter_local_notifications.
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final title = notification.title ?? '';
      final body = notification.body ?? '';
      if (title.isEmpty && body.isEmpty) return;

      // Extract action from data payload (mirrors our Fase 1 schema).
      final action = message.data['action'] ?? '';
      final externalUrl = message.data['external_url'] ?? '';
      String payload = action;
      if (action == 'external' && externalUrl.isNotEmpty) {
        payload = 'external:$externalUrl';
      }

      // Show via flutter_local_notifications (same channel as Fase 1).
      _localNotifPlugin?.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'jagatfilm_general',
            'Notifikasi JagatFilm',
            channelDescription: 'Info drama baru, event, dan promosi JagatFilm',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('FCM foreground handler error: $e');
    }
  }

  /// Handle when user taps a notification (from background/terminated).
  void _handleNotificationTap(RemoteMessage message) {
    try {
      final action = message.data['action'] ?? '';
      final externalUrl = message.data['external_url'] ?? '';
      String payload = action;
      if (action == 'external' && externalUrl.isNotEmpty) {
        payload = 'external:$externalUrl';
      }
      if (payload.isNotEmpty) {
        // Store for main.dart to pick up and navigate.
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('pending_notification_action', payload);
        }).catchError((_) => false);
      }
    } catch (e) {
      debugPrint('FCM tap handler error: $e');
    }
  }

  /// Get stored FCM token (for debugging/display).
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }
}
