import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'ui/mascots.dart';
import 'ui/motion.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';

class _Slide {
  const _Slide(this.word, this.title, this.body, this.colors, this.crew);
  final String word, title, body;
  final List<Color> colors;
  final List<MascotKind> crew;
}

const _slides = [
  _Slide(
    'SPOTS',
    'Temukan spot\nwajib datang.',
    'Rekomendasi asli dari orang sekitar, lengkap dengan peta.',
    [Color(0xFFCFE0FF), Color(0xFFF3F5FC)],
    [MascotKind.mimi, MascotKind.pino, MascotKind.gugu],
  ),
  _Slide(
    'REELS',
    'Geser, simpan,\nkumpulkan XP.',
    'Nonton reels tempat seru dan jaga streak harianmu.',
    [Color(0xFFE6DCFF), Color(0xFFF3F5FC)],
    [MascotKind.bobi, MascotKind.cici, MascotKind.tika],
  ),
  _Slide(
    'JAJAN',
    'Pesan langsung\ndari spotnya.',
    'Ambil di tempat atau minta dikirim. Bagikan ke squad-mu.',
    [Color(0xFFFFEDC4), Color(0xFFF3F5FC)],
    [MascotKind.jojo, MascotKind.tote, MascotKind.rumi],
  ),
];

/// Tiga layar perkenalan untuk pengguna baru.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final pages = PageController();
  int index = 0;

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  void next() {
    HapticFeedback.selectionClick();
    if (index == _slides.length - 1) {
      widget.onDone();
    } else {
      pages.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[index];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: slide.colors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 12, 0),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/logo.svg', height: 34),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onDone,
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: pages,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => index = i),
                      itemBuilder: (context, i) =>
                          _SlideView(slide: _slides[i]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                    child: Row(
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutBack,
                            width: i == index ? 26 : 9,
                            height: 9,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: i == index
                                  ? ink
                                  : ink.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        const Spacer(),
                        _PillButton(
                          label: index == _slides.length - 1
                              ? 'Mulai jelajah'
                              : 'Lanjut',
                          onTap: next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: FittedBox(
                  child: Text(
                    slide.word,
                    style: TextStyle(
                      fontFamily: fontDisplay,
                      fontSize: 104,
                      height: 1,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2.6
                        ..color = ink.withValues(alpha: .14),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 30,
                right: 10,
                child: _Spark(color: coral, size: 26),
              ),
              const Positioned(
                bottom: 40,
                left: 6,
                child: _Spark(color: yellow, size: 20),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: MascotCrew(
                  kinds: slide.crew,
                  size: 112,
                  mood: MascotMood.laugh,
                ),
              ),
            ],
          ),
        ),
        Rise(child: Text(slide.title, style: display(38, height: 1.04))),
        const SizedBox(height: 10),
        Rise(
          index: 1,
          child: Text(
            slide.body,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: muted,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    ),
  );
}

class _Spark extends StatelessWidget {
  const _Spark({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) =>
      SpotIcon(Glyph.sparkle, size: size, color: color, accent: color);
}

/// Tombol pil hitam dengan lingkaran panah.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Bouncy(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 7, 22, 7),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: ink.withValues(alpha: .25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Transform.rotate(
                angle: 3.1416,
                child: const SpotIcon(Glyph.back, size: 20, tint: false),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                key: ValueKey(label),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
