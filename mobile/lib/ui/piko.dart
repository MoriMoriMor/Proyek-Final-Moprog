import 'package:flutter/widgets.dart';

import 'mascots.dart';

export 'mascots.dart';

enum PikoMood { happy, wow, sleepy, wink, laugh, love, cool }

/// Piko, maskot utama Spots. Pintasan untuk [Mascot] jenis piko.
class Piko extends StatelessWidget {
  const Piko({
    super.key,
    this.size = 120,
    this.mood = PikoMood.happy,
    this.bounce = true,
    this.kind = MascotKind.piko,
    this.wave = false,
  });

  final double size;
  final PikoMood mood;
  final bool bounce, wave;
  final MascotKind kind;

  @override
  Widget build(BuildContext context) => Mascot(
    kind: kind,
    size: size,
    bounce: bounce,
    wave: wave,
    interactive: bounce,
    mood: switch (mood) {
      PikoMood.happy => MascotMood.happy,
      PikoMood.wow => MascotMood.wow,
      PikoMood.sleepy => MascotMood.sleepy,
      PikoMood.wink => MascotMood.wink,
      PikoMood.laugh => MascotMood.laugh,
      PikoMood.love => MascotMood.love,
      PikoMood.cool => MascotMood.cool,
    },
  );
}
