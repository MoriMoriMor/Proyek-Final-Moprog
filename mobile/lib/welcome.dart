import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/earth_globe.dart';
import 'ui/motion.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class _Slide {
  const _Slide({
    required this.kicker,
    required this.big,
    required this.highlight,
  });

  final String kicker, big, highlight;
}

/// Halaman sambutan dengan ilustrasi Globe Bumi 3D bergaya chibi dari luar
/// angkasa, animasi pin lokasi jatuh, dan tata letak kaca seragam di ponsel
/// maupun desktop.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.repo, required this.onDone});
  final SpotsRepository repo;
  final VoidCallback onDone;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const slides = [
    _Slide(
      kicker: 'Spot berikutnya',
      big: 'Wajib Datang',
      highlight: 'mulai dari sini',
    ),
    _Slide(
      kicker: 'Ada yang seru',
      big: 'Dekat Kamu',
      highlight: 'cek petanya',
    ),
    _Slide(
      kicker: 'Bukan cuma',
      big: 'Rekomendasi',
      highlight: 'bisa langsung jajan',
    ),
  ];

  Timer? auto;
  int index = 0;
  bool busy = false;
  StreamSubscription<void>? auth;

  @override
  void initState() {
    super.initState();
    auth = widget.repo.authChanges.listen((_) {
      if (widget.repo.userId != null && mounted) widget.onDone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auto?.cancel();
    if (calm(context) || !TickerMode.valuesOf(context).enabled) return;
    auto = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
        return;
      }
      setState(() => index = (index + 1) % slides.length);
    });
  }

  @override
  void dispose() {
    auto?.cancel();
    auth?.cancel();
    super.dispose();
  }

  Future<void> google() async {
    HapticFeedback.mediumImpact();
    setState(() => busy = true);
    try {
      await widget.repo.signInWithGoogle();
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> email() async {
    await openAuth(context, widget.repo);
    if (widget.repo.userId != null && mounted) widget.onDone();
  }

  void goToSlide(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final slide = slides[index];
    final screen = MediaQuery.sizeOf(context);
    final wide =
        screen.width >= 820 ||
        (screen.width > screen.height && screen.height < 580);
    final compactH = screen.height < 640;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF060C22),
        body: Stack(
          fit: StackFit.expand,
          children: [
            CosmicSpaceBackdrop(wide: wide),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1160 : 480),
                  child: wide
                      ? _buildWide(context, slide, screen.height)
                      : _buildMobile(context, slide, compactH),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context, _Slide slide, double height) {
    final veryShort = height < 460;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 28,
        vertical: veryShort ? 8 : 20,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: GestureDetector(
                    onHorizontalDragEnd: (d) {
                      final vx = d.primaryVelocity ?? 0;
                      if (vx.abs() < 120) return;
                      setState(() {
                        index = vx < 0
                            ? (index + 1) % slides.length
                            : (index - 1 + slides.length) % slides.length;
                      });
                    },
                    child: FrostedSurface(
                      radius: 34,
                      fill: Colors.white,
                      borderColor: line,
                      padding: EdgeInsets.fromLTRB(
                        26,
                        veryShort ? 16 : 26,
                        26,
                        veryShort ? 14 : 22,
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x42020818),
                          blurRadius: 38,
                          offset: Offset(0, 18),
                        ),
                      ],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'assets/logo.svg',
                            height: veryShort ? 26 : 34,
                            semanticsLabel: 'Spots',
                          ),
                          SizedBox(height: veryShort ? 12 : 22),
                          AnimatedSwitcher(
                            duration: motionTime(context, motionReveal),
                            transitionBuilder: (child, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(
                                position: Tween(
                                  begin: const Offset(0, .08),
                                  end: Offset.zero,
                                ).animate(a),
                                child: child,
                              ),
                            ),
                            child: _Headline(
                              key: ValueKey(index),
                              slide: slide,
                              alignStart: true,
                              compact: veryShort,
                            ),
                          ),
                          SizedBox(height: veryShort ? 10 : 18),
                          _SlideDots(
                            count: slides.length,
                            index: index,
                            onSelect: goToSlide,
                            alignStart: true,
                          ),
                          SizedBox(height: veryShort ? 12 : 22),
                          _ActionStack(
                            busy: busy,
                            compact: veryShort,
                            onEmail: email,
                            onGoogle: google,
                            onSkip: widget.onDone,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 13,
            child: SpotsEarthGlobe(compact: veryShort),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context, _Slide slide, bool compactH) =>
      Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          compactH ? 4 : 10,
          14,
          compactH ? 6 : 12,
        ),
        child: Column(
          children: [
            FrostedSurface(
              radius: 99,
              fill: Colors.white,
              borderColor: line,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: SvgPicture.asset(
                'assets/logo.svg',
                height: compactH ? 22 : 27,
                semanticsLabel: 'Spots',
              ),
            ),
            SizedBox(height: compactH ? 2 : 6),
            Expanded(
              child: SpotsEarthGlobe(compact: compactH),
            ),
            SizedBox(height: compactH ? 2 : 6),
            GestureDetector(
              onHorizontalDragEnd: (d) {
                final vx = d.primaryVelocity ?? 0;
                if (vx.abs() < 120) return;
                setState(() {
                  index = vx < 0
                      ? (index + 1) % slides.length
                      : (index - 1 + slides.length) % slides.length;
                });
              },
              child: FrostedSurface(
                radius: 32,
                fill: Colors.white,
                borderColor: line,
                padding: EdgeInsets.fromLTRB(
                  20,
                  compactH ? 12 : 18,
                  20,
                  compactH ? 10 : 14,
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x42020818),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SlideDots(
                      count: slides.length,
                      index: index,
                      onSelect: goToSlide,
                    ),
                    SizedBox(height: compactH ? 8 : 12),
                    AnimatedSwitcher(
                      duration: motionTime(context, motionReveal),
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, .08),
                            end: Offset.zero,
                          ).animate(a),
                          child: child,
                        ),
                      ),
                      child: _Headline(
                        key: ValueKey(index),
                        slide: slide,
                        compact: compactH,
                      ),
                    ),
                    SizedBox(height: compactH ? 10 : 16),
                    _ActionStack(
                      busy: busy,
                      compact: compactH,
                      onEmail: email,
                      onGoogle: google,
                      onSkip: widget.onDone,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _SlideDots extends StatelessWidget {
  const _SlideDots({
    required this.count,
    required this.index,
    required this.onSelect,
    this.alignStart = false,
  });

  final int count, index;
  final ValueChanged<int> onSelect;
  final bool alignStart;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: alignStart
        ? MainAxisAlignment.start
        : MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: i == index ? 24 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: i == index
                  ? const LinearGradient(
                      colors: [Color(0xFF62A2FF), Color(0xFF3B76F6)],
                    )
                  : null,
              color: i == index ? null : ink.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
    ],
  );
}

class _Headline extends StatelessWidget {
  const _Headline({
    super.key,
    required this.slide,
    this.alignStart = false,
    this.compact = false,
  });

  final _Slide slide;
  final bool alignStart, compact;

  @override
  Widget build(BuildContext context) {
    final bigSize = compact ? 38.0 : 48.0;
    return Column(
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          slide.kicker,
          style: TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w900,
            color: blue,
            fontSize: compact ? 14 : 16,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignStart ? Alignment.centerLeft : Alignment.center,
          child: Stack(
            children: [
              Text(
                slide.big,
                style: TextStyle(
                  fontFamily: fontDisplay,
                  fontSize: bigSize,
                  height: 1.05,
                  letterSpacing: -.5,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 9
                    ..strokeJoin = StrokeJoin.round
                    ..color = Colors.white,
                ),
              ),
              Text(
                slide.big,
                style: TextStyle(
                  fontFamily: fontDisplay,
                  fontSize: bigSize,
                  height: 1.05,
                  letterSpacing: -.5,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Transform.rotate(
          angle: -.02,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF62A2FF), Color(0xFF3B76F6)],
              ),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: Colors.white.withValues(alpha: .55),
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x293B76F6),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              slide.highlight,
              style: TextStyle(
                fontFamily: fontBody,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 14 : 16,
                height: 1.1,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionStack extends StatelessWidget {
  const _ActionStack({
    required this.busy,
    required this.compact,
    required this.onEmail,
    required this.onGoogle,
    required this.onSkip,
  });

  final bool busy, compact;
  final VoidCallback onEmail, onGoogle, onSkip;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 46.0 : 52.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          enabled: !busy,
          label: 'Mulai Sekarang',
          child: Bouncy(
            onTap: busy ? null : onEmail,
            scale: .97,
            child: Container(
              height: h,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1120),
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x240B1120),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  busy ? 'Memproses…' : 'Mulai Sekarang',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                enabled: !busy,
                child: Bouncy(
                  onTap: busy ? null : onGoogle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GoogleMark(size: 16),
                        const SizedBox(width: 7),
                        Text(
                          busy ? 'Menghubungkan…' : 'Lanjut dengan Google',
                          style: const TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                child: Bouncy(
                  onTap: onSkip,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Lihat-lihat dulu',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Logo "G" untuk tombol masuk dengan Google.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});
  final double size;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * .2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -.45, -1.1, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect, -1.55, -1.6, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, -3.15, -1.55, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, -4.7, -1.1, false, arc(const Color(0xFF4285F4)));
    canvas.drawRect(
      Rect.fromLTWH(s * .5, s * .5 - stroke / 2, s * .5 - stroke * .05, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}
