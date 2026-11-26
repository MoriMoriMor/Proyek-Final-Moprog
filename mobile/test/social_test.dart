import 'package:flutter_test/flutter_test.dart';
import 'package:spots/demo_repository.dart';
import 'package:spots/spot.dart';

void main() {
  test('ikuti dan berhenti mengikuti mengubah angka pengikut', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('mira@mail.com', 'rahasia1');
    final before = await repo.profileStats('u-Rara');
    await repo.setFollow('u-Rara', true);
    final after = await repo.profileStats('u-Rara');
    expect(after.followers, before.followers + 1);
    expect(after.isFollowing, isTrue);
    await repo.setFollow('u-Rara', false);
    expect((await repo.profileStats('u-Rara')).isFollowing, isFalse);
  });

  test('username harus unik dan sesuai format', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('mira@mail.com', 'rahasia1');
    expect(
      () => repo.updateProfile(
        displayName: 'Mira',
        username: 'rara.jalan',
        bio: '',
      ),
      throwsStateError,
    );
    expect(
      () => repo.updateProfile(
        displayName: 'Mira',
        username: 'Ada Spasi',
        bio: '',
      ),
      throwsStateError,
    );
    await repo.updateProfile(
      displayName: 'Mira',
      username: 'mira.jalan',
      bio: 'Halo',
    );
    expect((await repo.myProfile())?.username, 'mira.jalan');
  });

  test('feed per orang dan feed ditandai', () async {
    final repo = DemoSpotsRepository();
    final rara = await repo.feed(mode: 'user', user: 'u-Rara');
    expect(rara.every((s) => s.ownerId == 'u-Rara'), isTrue);
    final tagged = await repo.feed(mode: 'tagged', user: 'u-Bimo');
    expect(tagged.map((s) => s.id), contains('d1'));
    expect(rara.first.authorUsername, 'rara.jalan');
  });

  test('mention dikenali di teks', () {
    final found = mentionPattern
        .allMatches('Ke sini bareng @bimo.ngopi dan @rara_jalan!')
        .map((m) => m.group(1))
        .toList();
    expect(found, ['bimo.ngopi', 'rara_jalan']);
  });

  test('pendaftaran menolak email ganda maupun username ganda', () async {
    final repo = DemoSpotsRepository();
    await repo.signUp(
      'Arga Pertama',
      'arga@spots.id',
      'rahasia123',
      username: 'arga.sby',
    );
    expect((await repo.myProfile())?.username, 'arga.sby');
    await repo.signOut();

    // Email sama (termasuk beda huruf kapital) harus ditolak
    await expectLater(
      repo.signUp(
        'Arga Kedua',
        'ARGA@spots.id',
        'rahasia123',
        username: 'arga.dua',
      ),
      throwsStateError,
    );

    // Username sama (termasuk beda huruf kapital) harus ditolak
    await expectLater(
      repo.signUp(
        'Arga Ketiga',
        'arga3@spots.id',
        'rahasia123',
        username: 'ARGA.SBY',
      ),
      throwsStateError,
    );

    // Username otomatis untuk nama kembar tidak boleh bentrok
    await repo.signUp('Budi', 'budi1@spots.id', 'rahasia123');
    final u1 = (await repo.myProfile())!.username;
    await repo.signOut();
    await repo.signUp('Budi', 'budi2@spots.id', 'rahasia123');
    final u2 = (await repo.myProfile())!.username;
    expect(u1, isNot(equals(u2)));
  });
}
