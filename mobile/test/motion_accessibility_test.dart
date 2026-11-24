import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/ui/motion.dart';
import 'package:spots/ui/theme.dart';

void main() {
  testWidgets('tombol bisa dipakai dengan keyboard dan fokus terlihat', (
    t,
  ) async {
    var pressed = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: spotsTheme(),
        home: Scaffold(
          body: Column(
            children: [
              Chunky(onTap: () => pressed++, child: const Text('Bagikan spot')),
              Bouncy(onTap: () => pressed++, child: const Text('Buka peta')),
              const Chunky(onTap: null, child: Text('Tunggu')),
            ],
          ),
        ),
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(pressed, 1);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    expect(pressed, 2);
    await t.tap(find.text('Tunggu'));
    expect(pressed, 2);
    expect(FocusManager.instance.primaryFocus?.context?.widget, isA<Focus>());
  });

  testWidgets('reduced motion menampilkan konten tanpa ticker berulang', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Column(
              children: [
                Rise(child: const Text('Tempat sekitar')),
                Shimmer(child: const Bone(height: 40, width: 100)),
                Bouncy(onTap: () {}, child: const Text('Jelajah')),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    expect(t.hasRunningAnimations, isFalse);
    expect(find.text('Tempat sekitar').hitTestable(), findsOneWidget);
    final gesture = await t.startGesture(t.getCenter(find.text('Jelajah')));
    await t.pump();
    final scale = t.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1);
    expect(scale.duration, Duration.zero);
    await gesture.up();
    await t.pump();
    expect(t.takeException(), isNull);
  });

  test('warna teks tombol memenuhi kontras minimum', () {
    for (final color in [
      piko,
      blue,
      coral,
      yellow,
      mint,
      grape,
      tomato,
      caramel,
    ]) {
      final foreground = foregroundOn(color).computeLuminance();
      final background = color.computeLuminance();
      final ratio = foreground > background
          ? (foreground + .05) / (background + .05)
          : (background + .05) / (foreground + .05);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: '$color');
    }
  });
}
