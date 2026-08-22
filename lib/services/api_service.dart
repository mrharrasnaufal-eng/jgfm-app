import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drama.dart';

class ApiService {
  static const String baseUrl = 'https://jagatfilm.com';
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final http.Client _client = http.Client();

  /// Fetch drama list with pagination, provider filter, and search
  Future<DramaListResponse> getDramas({
    int page = 1,
    int limit = 30,
    String provider = 'all',
    String query = '',
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (provider != 'all') params['provider'] = provider;
    if (query.isNotEmpty) params['q'] = query;

    final uri = Uri.parse('$baseUrl/api/dramas').replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final dramas = (json['data'] as List)
            .map((e) => Drama.fromJson(e))
            .toList();
        final pagination = json['pagination'] ?? {};
        final providers = (json['providers'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {};
        return DramaListResponse(
          dramas: dramas,
          page: pagination['page'] ?? page,
          totalPages: pagination['totalPages'] ?? 1,
          total: pagination['total'] ?? dramas.length,
          hasMore: pagination['hasMore'] ?? false,
          providers: providers,
        );
      }
    }
    throw ApiException('Gagal memuat drama', response.statusCode);
  }

  /// Get drama detail by composite ID
  Future<DramaDetail> getDramaDetail(String id) async {
    // The website fetches detail via the stream API or renders server-side
    // We use the dramas list endpoint filtered, then stream endpoint for detail
    // Actually, the detail page on website calls getDramaDetail from lib/api.ts server-side
    // For the Flutter app, we get basic info from list, then episodes from stream trial
    
    // First try: search for this specific drama in the list
    final listResponse = await getDramas(query: '', page: 1, limit: 1);
    
    // The website doesn't expose a direct detail API endpoint via HTTP
    // But the stream endpoint gives us stream URLs per episode
    // We'll construct detail from the drama list data + episode count
    throw ApiException('Use getDramaDetailFromStream instead', 501);
  }

  /// Get stream data for a specific drama episode
  Future<StreamData> getStream(String dramaId, int episode) async {
    final uri = Uri.parse('$baseUrl/api/stream').replace(
      queryParameters: {
        'id': dramaId,
        'episode': episode.toString(),
      },
    );
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return StreamData.fromJson(json['data']);
      }
    }
    throw ApiException('Stream tidak tersedia', response.statusCode);
  }

  /// Search dramas
  Future<List<Drama>> searchDramas(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await getDramas(query: query, page: 1, limit: 50);
    return response.dramas;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'User-Agent': 'JagatFilm-Android/1.0',
      };
}

class DramaListResponse {
  final List<Drama> dramas;
  final int page;
  final int totalPages;
  final int total;
  final bool hasMore;
  final Map<String, int> providers;

  DramaListResponse({
    required this.dramas,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.hasMore,
    required this.providers,
  });
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
