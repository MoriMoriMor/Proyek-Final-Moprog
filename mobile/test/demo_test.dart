import 'package:flutter_test/flutter_test.dart';
import 'package:spots/demo_repository.dart';
import 'package:spots/spot_views.dart';

void main() {
  test('jarak ditulis singkat sesuai besarnya', () {
    expect(distanceLabel(0.42), '420 m');
    expect(distanceLabel(2.35), '2.4 km');
    expect(distanceLabel(943.6), '944 km');
    expect(compact(950), '950');
    expect(compact(1250), '1.3rb');
  });

  test('mode dekat hanya memuat spot dalam 20 km', () async {
    final repo = DemoSpotsRepository();
    final near = await repo.feed(lat: -6.905, lng: 107.61, mode: 'near');
    expect(near, isNotEmpty);
    expect(near.every((spot) => spot.distanceKm! <= 20), isTrue);

    final all = await repo.feed(mode: 'popular');
    expect(all.length, greaterThan(near.length));
  });

  test('interaksi butuh akun dan tersimpan setelah masuk', () async {
    final repo = DemoSpotsRepository();
    expect(() => repo.setReaction('d1', 'save', true), throwsStateError);

    await repo.signIn('mira@mail.com', 'rahasia1');
    await repo.setReaction('d1', 'save', true);
    final saved = await repo.feed(mode: 'saved');
    expect(saved.map((spot) => spot.id), contains('d1'));
  });
}
