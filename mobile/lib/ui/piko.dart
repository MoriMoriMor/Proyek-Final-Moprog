import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PikoMood { happy, wow, sleepy, wink }

/// Piko, maskot Spots. Bentuknya sama dengan assets/mascot.svg,
/// wajahnya diganti sesuai suasana dan matanya berkedip.
class Piko extends StatefulWidget {
  const Piko({
    super.key,
    this.size = 120,
    this.mood = PikoMood.happy,
    this.bounce = true,
  });

  final double size;
  final PikoMood mood;
  final bool bounce;

  @override
  State<Piko> createState() => _PikoState();
}

class _PikoState extends State<Piko> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final t = controller.value;
      final blink = (t > .62 && t < .655) || (t > .70 && t < .735);
      final wave = math.sin(t * math.pi * 4);
      final dy = widget.bounce ? -wave * widget.size * .03 : 0.0;
      final squash = widget.bounce ? 1 + wave * .025 : 1.0;
      return Transform.translate(
        offset: Offset(0, dy),
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(2 - squash, squash, 1),
          child: SvgPicture.string(
            _pikoSvg(widget.mood, blink && widget.mood != PikoMood.sleepy),
            width: widget.size,
            height: widget.size * 260 / 240,
            excludeFromSemantics: true,
          ),
        ),
      );
    },
  );
}

const _body = '''
<path d="M86 200c-12 7-18 18-13 25 5 8 19 8 31 1l14-15M153 200c12 7 18 18 13 25-5 8-19 8-31 1l-14-15" fill="#17358B" stroke="#17358B" stroke-width="5" stroke-linejoin="round"/>
<path d="M122 45c41 0 68 27 71 69 15 0 25 8 25 20 0 12-10 19-27 17-7 38-32 61-70 61-39 0-64-23-71-61-17 2-27-5-27-17 0-12 10-20 25-20 3-42 31-69 74-69Z" fill="#416CF4" stroke="#17358B" stroke-width="6" stroke-linejoin="round"/>
<path d="M93 48c-4-13-3-25 3-30 8-6 20 4 25 24m25 6c4-13 3-25-3-30-8-6-20 4-25 24" fill="#82A1FF" stroke="#17358B" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M68 107c4-24 18-38 39-43" stroke="#9AB4FF" stroke-width="10" stroke-linecap="round"/>
<circle cx="69" cy="146" r="9" fill="#FF8E9B"/>
<circle cx="172" cy="146" r="9" fill="#FF8E9B"/>
<path d="M100 176c13 8 29 8 42 0" stroke="#17358B" stroke-opacity=".38" stroke-width="5" stroke-linecap="round"/>
<path d="m182 25 5 11 11 5-11 5-5 11-5-11-11-5 11-5 5-11Z" fill="#FFCE3B" stroke="#17358B" stroke-width="4" stroke-linejoin="round"/>
<path d="m39 65 3 7 7 3-7 3-3 7-3-7-7-3 7-3 3-7Z" fill="#FF7795"/>
''';

const _closedEyes =
    '<path d="M83 126q8 7 16 0M142 126q8 7 16 0" stroke="#172657" stroke-width="5" stroke-linecap="round" fill="none"/>';

final _cache = <String, String>{};

String _pikoSvg(
  PikoMood mood,
  bool blink,
) => _cache.putIfAbsent('$mood$blink', () {
  final eyes = blink
      ? _closedEyes
      : switch (mood) {
          PikoMood.wow => '<circle cx="91" cy="123" r="11" fill="#fff" stroke="#172657" stroke-width="4"/><circle cx="150" cy="123" r="11" fill="#fff" stroke="#172657" stroke-width="4"/><circle cx="93" cy="125" r="5" fill="#172657"/><circle cx="152" cy="125" r="5" fill="#172657"/>',
          PikoMood.sleepy => '<path d="M82 127h18M141 127h18" stroke="#172657" stroke-width="5" stroke-linecap="round"/>',
          PikoMood.wink => '<circle cx="91" cy="125" r="7" fill="#172657"/><path d="M142 127q8-7 16 0" stroke="#172657" stroke-width="5" stroke-linecap="round" fill="none"/>',
          PikoMood.happy => '<circle cx="91" cy="125" r="7" fill="#172657"/><circle cx="150" cy="125" r="7" fill="#172657"/>',
        };
  final mouth = switch (mood) {
    PikoMood.wow =>
      '<ellipse cx="120" cy="154" rx="8" ry="10" fill="#172657"/>',
    PikoMood.sleepy => '<path d="M112 153h16" stroke="#172657" stroke-width="5" stroke-linecap="round"/><path d="M196 74h12l-12 13h12M212 52h8l-8 9h8" stroke="#17358B" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    _ => '<path d="M106 148c8 10 21 10 29 0" stroke="#172657" stroke-width="5" stroke-linecap="round" fill="none"/>',
  };
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 260" fill="none">$_body$eyes$mouth</svg>';
});
