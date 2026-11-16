import 'package:flutter_test/flutter_test.dart';
import 'package:spots/demo_repository.dart';

void main() {
  test('demo: blokir menyembunyikan spot dan buka blokir mengembalikannya', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('kamu@demo.spots', 'demo1234');

    final before = await repo.feed(mode: 'popular');
    final target = before.firstWhere((s) => s.ownerId != repo.userId);
    final ownerId = target.ownerId;

    await repo.setBlocked(ownerId, true);
    expect(await repo.isBlocked(ownerId), isTrue);

    final afterBlock = await repo.feed(mode: 'popular');
    expect(afterBlock.any((s) => s.ownerId == ownerId), isFalse);

    await repo.setBlocked(ownerId, false);
    expect(await repo.isBlocked(ownerId), isFalse);

    final afterUnblock = await repo.feed(mode: 'popular');
    expect(afterUnblock.any((s) => s.ownerId == ownerId), isTrue);
  });

  test('demo: lapor konten valid & tolak blokir diri sendiri', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('kamu@demo.spots', 'demo1234');

    await expectLater(
      repo.setBlocked(repo.userId!, true),
      throwsStateError,
    );
    await expectLater(
      repo.reportContent(targetType: 'post', targetId: 'd1', reason: 'ab'),
      throwsStateError,
    );
    await repo.reportContent(
      targetType: 'post',
      targetId: 'd1',
      reason: 'Spam atau iklan',
    );
  });
}
