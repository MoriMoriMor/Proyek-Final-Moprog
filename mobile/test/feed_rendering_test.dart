import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/demo_repository.dart';
import 'package:spots/spot.dart';
import 'package:spots/spot_views.dart';
import 'package:spots/spots_app.dart';
import 'package:spots/ui/motion.dart';
import 'package:spots/ui/theme.dart';

void main() {
  testWidgets('feed tetap dimuat selama izin lokasi belum dijawab', (t) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    final locationReply = Completer<bool>();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    messenger.setMockMethodCallHandler(channel, (_) => locationReply.future);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final repo = DemoSpotsRepository();
    await t.runAsync(() => repo.signIn('mira@mail.com', 'rahasia1'));
    await t.pumpWidget(
      MaterialApp(
        theme: spotsTheme(),
        home: SpotsShell(repo: repo),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(locationReply.isCompleted, isFalse);
    expect(find.text('Lagi viral'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    locationReply.complete(false);
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('suka tetap aktif saat kartu dibuat ulang setelah digulir', (
    t,
  ) async {
    final repo = DemoSpotsRepository();
    late Spot original;
    await t.runAsync(() async {
      await repo.signIn('mira@mail.com', 'rahasia1');
      original = (await repo.feed(mode: 'popular')).first;
      await repo.setReaction(original.id, 'like', false);
      original = (await repo.feed(mode: 'popular'))
          .firstWhere((spot) => spot.id == original.id);
    });
    Spot? updated;
    Widget page(Spot spot) => MaterialApp(
      theme: spotsTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SpotCard(
            spot: spot,
            repo: repo,
            onOpen: () {},
            onChanged: () {},
            onReactionChanged: (spot) => updated = spot,
          ),
        ),
      ),
    );
    await t.pumpWidget(page(original));
    await t.tap(find.bySemanticsLabel('Suka').first);
    await t.pump(const Duration(seconds: 2));
    expect(updated, isNotNull);
    expect(updated!.liked, isTrue);
    expect(updated!.likes, original.likes + 1);
    expect(updated!.media, original.media);
    expect(updated!.placeId, original.placeId);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(page(updated!));
    final like = t
        .widgetList<PopToggle>(find.byType(PopToggle))
        .firstWhere((button) => button.label == 'Batal suka');
    expect(like.active, isTrue);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}
