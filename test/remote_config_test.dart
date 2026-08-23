import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jagatfilm/models/app_remote_config.dart';
import 'package:jagatfilm/services/remote_config_service.dart';
import 'package:jagatfilm/services/update_service.dart';

void main() {
  group('AppRemoteConfig', () {
    test('parses and sanitizes a valid dashboard payload', () {
      final config = AppRemoteConfig.fromJson({
        'logo_url': ' https://example.com/logo.png ',
        'splash_image_url': 'https://example.com/splash.jpg',
        'popup_enabled': 'true',
        'popup_image_url': 'https://example.com/popup.jpg',
        'popup_title': ' Promo ',
        'popup_message': ' Pesan promo ',
        'popup_action_url': 'PAGE:SEARCH',
        'popup_external_url': 'https://ignored.example.com',
        'popup_duration': '45',
        'maintenance_mode': 0,
        'maintenance_message': '',
        'announcement': ' Pengumuman ',
        'force_update': 1,
        'min_version': '1.2.3',
      });

      expect(config.logoUrl, 'https://example.com/logo.png');
      expect(config.popupEnabled, isTrue);
      expect(config.popupAction, 'page:search');
      expect(config.popupExternalUrl, isEmpty);
      expect(config.popupDurationSeconds, 30);
      expect(config.maintenanceMode, isFalse);
      expect(
        config.maintenanceMessage,
        AppRemoteConfig.defaultMaintenanceMessage,
      );
      expect(config.announcement, 'Pengumuman');
      expect(config.forceUpdate, isTrue);
      expect(config.minimumVersion, '1.2.3');
      expect(config.hasPopupContent, isTrue);
      expect(config.hasPopupAction, isTrue);
    });

    test('rejects dangerous or malformed values with safe defaults', () {
      final config = AppRemoteConfig.fromJson({
        'logo_url': 'javascript:alert(1)',
        'splash_image_url': 'not a url',
        'popup_enabled': null,
        'popup_action_url': 'page:unknown',
        'popup_external_url': 'file:///tmp/file',
        'popup_duration': -100,
        'maintenance_mode': 'false',
        'force_update': 'no',
        'min_version': 'latest',
      });

      expect(config.logoUrl, isEmpty);
      expect(config.splashImageUrl, isEmpty);
      expect(config.popupEnabled, isFalse);
      expect(config.popupAction, isEmpty);
      expect(config.popupDurationSeconds, 2);
      expect(config.maintenanceMode, isFalse);
      expect(config.forceUpdate, isFalse);
      expect(config.minimumVersion, '1.0.0');
      expect(config.hasPopupAction, isFalse);
    });

    test('only enables an external action when its URL is safe', () {
      final invalid = AppRemoteConfig.fromJson({
        'popup_action_url': 'external',
        'popup_external_url': 'javascript:alert(1)',
      });
      final valid = AppRemoteConfig.fromJson({
        'popup_action_url': 'external',
        'popup_external_url': 'https://jagatfilm.com/promo',
      });

      expect(invalid.hasPopupAction, isFalse);
      expect(valid.hasPopupAction, isTrue);
    });
  });

  group('RemoteConfigService', () {
    test('uses the secondary endpoint when the primary endpoint fails', () async {
      final requestedHosts = <String>[];
      final client = MockClient((request) async {
        requestedHosts.add(request.url.host);
        expect(request.url.queryParameters['t'], isNotEmpty);

        if (request.url.host == 'primary.example.com') {
          return http.Response('unavailable', 503);
        }
        return http.Response(
          jsonEncode({
            'announcement': 'Fallback aktif',
            'popup_enabled': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = RemoteConfigService(
        client: client,
        endpoints: [
          Uri.parse('https://primary.example.com/api/config'),
          Uri.parse('https://secondary.example.com/app/config.json'),
        ],
      );

      final config = await service.fetch();

      expect(
        requestedHosts,
        ['primary.example.com', 'secondary.example.com'],
      );
      expect(config.announcement, 'Fallback aktif');
      service.dispose();
    });

    test('returns safe defaults when every endpoint fails', () async {
      final client = MockClient((_) async => http.Response('{broken', 200));
      final service = RemoteConfigService(
        client: client,
        endpoints: [Uri.parse('https://invalid.example.com/config')],
      );

      final config = await service.fetch();

      expect(config.maintenanceMode, isFalse);
      expect(config.forceUpdate, isFalse);
      expect(config.popupEnabled, isFalse);
      expect(config.minimumVersion, '1.0.0');
      service.dispose();
    });
  });

  group('UpdateService version comparison', () {
    test('compares dotted semantic versions safely', () {
      expect(UpdateService.isVersionBelowMinimum('1.0.3', '1.0.4'), isTrue);
      expect(UpdateService.isVersionBelowMinimum('1.0.4', '1.0.4'), isFalse);
      expect(UpdateService.isVersionBelowMinimum('1.2', '1.1.9'), isFalse);
      expect(UpdateService.isVersionBelowMinimum('2.0.0+5', '2.0'), isFalse);
      expect(UpdateService.isVersionBelowMinimum('unknown', '2.0'), isFalse);
      expect(UpdateService.isVersionBelowMinimum('1.0', 'latest'), isFalse);
    });
  });
}
