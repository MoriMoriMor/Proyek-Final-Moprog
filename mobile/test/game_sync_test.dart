import 'package:flutter_test/flutter_test.dart';
import 'package:spots/demo_repository.dart';
import 'package:spots/game.dart';

void main() {
  test('demo: catat aksi, klaim misi sekali, dan undangan sekali', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('kamu@demo.spots', 'demo1234');
    const day = '2026-11-16';

    final first = await repo.recordGameAction('comment', day);
    expect(first?.gained, 20);
    expect(first?.xp, 20);
    expect(first?.finishedQuest, 'comment');

    final second = await repo.recordGameAction('comment', day);
    expect(second?.gained, 5);
    expect(second?.xp, 25);
    expect(second?.finishedQuest, isNull);

    final inv1 = await repo.recordGameAction('invited', day);
    expect(inv1?.gained, 30);
    expect(inv1?.xp, 55);

    final inv2 = await repo.recordGameAction('invited', day);
    expect(inv2?.gained, 0);
    expect(inv2?.xp, 55);

    final state = await repo.fetchGameState(day);
    expect(state?.xp, 55);
    expect(state?.quests['comment']?.claimed, isTrue);
    expect(state?.quests['comment']?.progress, 1);
  });

  test('GameState sinkron dengan server saat masuk', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('kamu@demo.spots', 'demo1234');
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await repo.recordGameAction('share', today);
    final game = GameState.instance;
    game.bind(repo);
    await game.syncFromServer();

    expect(game.xp, 30);
    expect(game.claimed.contains('share'), isTrue);
    expect(game.progress['share'], 1);
  });
}
