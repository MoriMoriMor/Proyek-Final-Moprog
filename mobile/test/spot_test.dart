import 'package:flutter_test/flutter_test.dart';
import 'package:spots/spot.dart';

void main() {
  test('feed response keeps mixed media and engagement values', () {
    final spot = Spot.fromJson({
      'id': 'post-1',
      'owner_id': 'user-1',
      'author': 'Mira',
      'title': 'Sate Pak Hadi',
      'city': 'Bandung',
      'category': 'kuliner',
      'story': 'Bumbu kacangnya enak.',
      'lat': -6.91,
      'lng': 107.61,
      'likes': 12,
      'saves': 5,
      'comment_count': 3,
      'rating': 4.5,
      'liked': true,
      'saved': false,
      'distance_km': 2.4,
      'media': [
        {'path': 'user-1/post-1/0.jpg', 'type': 'image'},
        {'path': 'user-1/post-1/1.mp4', 'type': 'video'},
      ],
    });

    expect(spot.media.map((item) => item.type), ['image', 'video']);
    expect(spot.distanceKm, 2.4);
    expect(spot.likes, 12);
    expect(spot.liked, isTrue);
    expect(spot.saved, isFalse);
  });
}
