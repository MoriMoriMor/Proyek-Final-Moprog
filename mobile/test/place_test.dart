import 'package:flutter_test/flutter_test.dart';
import 'package:spots/demo_repository.dart';
import 'package:spots/place_page.dart';
import 'package:spots/spot.dart';

Spot spot(String id, {int likes = 0, int days = 1, int photos = 2}) =>
    Spot.fromJson({
      'id': id,
      'owner_id': 'u$id',
      'title': 'Tempat',
      'category': 'kuliner',
      'lat': -7.0,
      'lng': 112.0,
      'likes': likes,
      'created_at': DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String(),
      'media': [
        for (var i = 0; i < photos; i++) {'path': '$id-$i', 'type': 'image'},
      ],
    });

void main() {
  test('skor viral turun seiring umur postingan', () {
    final baru = spot('a', likes: 50, days: 1);
    final lama = spot('b', likes: 50, days: 60);
    expect(baru.viralScore(), greaterThan(lama.viralScore()));
    expect(
      spot('c', likes: 200, days: 60).viralScore(),
      greaterThan(spot('d', likes: 5, days: 1).viralScore()),
    );
  });

  test('sorotan tempat: maksimal 10 foto, dari spot paling viral', () {
    final spots = [
      spot('sepi', likes: 1, photos: 5),
      spot('ramai', likes: 99, photos: 4),
      spot('sedang', likes: 40, photos: 5),
    ];
    final photos = rankedPhotos(spots);
    expect(photos.length, 10);
    expect(photos.first.spot.id, 'ramai');
    expect(photos.take(4).every((p) => p.spot.id == 'ramai'), isTrue);
    expect(photos.last.spot.id, 'sepi');
  });

  test('demo: dokumentasi satu tempat dari beberapa orang', () async {
    final repo = DemoSpotsRepository();
    final list = await repo.placeSpots('p-d1');
    expect(list.length, greaterThanOrEqualTo(4));
    expect(list.map((s) => s.ownerId).toSet().length, greaterThan(1));
    for (var i = 1; i < list.length; i++) {
      expect(list[i - 1].engagement, greaterThanOrEqualTo(list[i].engagement));
    }
    final near = await repo.nearbyPlaces(-6.914, 107.609);
    expect(near.first.id, 'p-d1');
    expect(near.first.people, greaterThan(1));
  });

  test('demo: spot baru bisa bergabung ke tempat lama', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('a@b.c', 'rahasia1');
    final before = (await repo.placeSpots('p-d1')).length;
    await repo.createSpot(
      title: 'Mie Kocok Mang Ujang',
      city: 'Bandung',
      category: 'kuliner',
      story: 'Enak banget',
      lat: -6.914,
      lng: 107.609,
      files: const [],
      placeId: 'p-d1',
    );
    expect((await repo.placeSpots('p-d1')).length, before + 1);
    await repo.createSpot(
      title: 'Warung sebelah',
      city: 'Bandung',
      category: 'kuliner',
      story: 'Beda tempat',
      lat: -6.914,
      lng: 107.609,
      files: const [],
    );
    expect((await repo.placeSpots('p-d1')).length, before + 1);
  });
}
