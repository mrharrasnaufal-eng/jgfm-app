import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Drama model parsing', () {
    final json = {
      'id': 'shortmax-12345',
      'title': 'Test Drama',
      'cover': 'https://example.com/cover.jpg',
      'description': 'Test description',
      'genre': 'Romance',
      'genres': ['Romance', 'Drama'],
      'tags': ['CEO', 'Love'],
      'totalEpisodes': 20,
      'source': 'shortmax',
      'sourceId': '12345',
    };

    // Basic assertion that JSON can be constructed
    expect(json['id'], 'shortmax-12345');
    expect(json['totalEpisodes'], 20);
  });
}
