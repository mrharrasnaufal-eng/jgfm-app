import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_remote_config.dart';

class RemoteConfigService {
  static final List<Uri> defaultEndpoints = [
    Uri.parse('https://masterpanel.jagatfilm.com/api/config'),
    Uri.parse('https://www.jagatfilm.com/app/config.json'),
  ];

  final http.Client _client;
  final bool _ownsClient;
  final List<Uri> _endpoints;
  final Duration requestTimeout;

  RemoteConfigService({
    http.Client? client,
    List<Uri>? endpoints,
    this.requestTimeout = const Duration(seconds: 5),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _endpoints = List.unmodifiable(endpoints ?? defaultEndpoints);

  Future<AppRemoteConfig> fetch() async {
    for (final endpoint in _endpoints) {
      try {
        final cacheBustEndpoint = endpoint.replace(
          queryParameters: {
            ...endpoint.queryParameters,
            't': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        final response = await _client.get(
          cacheBustEndpoint,
          headers: const {
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ).timeout(requestTimeout);

        if (response.statusCode != 200 ||
            response.body.isEmpty ||
            response.body.length > 100000) {
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map || decoded.isEmpty) continue;

        return AppRemoteConfig.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      } catch (_) {
        // Try the next endpoint. Remote config must never crash startup.
      }
    }

    return const AppRemoteConfig.defaults();
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
