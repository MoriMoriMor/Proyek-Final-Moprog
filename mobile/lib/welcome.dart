import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/mascots.dart';
import 'ui/motion.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class _Slide {
  const _Slide({
    required this.kicker,
    required this.big,
    required this.highlight,
    required this.backdropPhoto,
    required this.skyTint,
    required this.art,
  });

  final String kicker, big, highlight, backdropPhoto;
  final Color skyTint;
  final Widget Function(double t) art;
}

/// Halaman sambutan berilustrasi kolase & maskot 3D dengan latar pemandangan
/// foto nyata + langit awan berlapis kaca yang seragam di ponsel maupun desktop.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.repo, required this.onDone});
  final SpotsRepository repo;
  final VoidCallback onDone;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  final pages = PageController();
  late final float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  Timer? auto;
  int index = 0;
  bool busy = false;
  StreamSubscription<void>? auth;

  late final slides = [
    _Slide(
      kicker: 'Spot berikutnya',
      big: 'Wajib Datang',
      highlight: 'mulai dari sini',
      backdropPhoto: 'assets/photos/hangout.jpg',
      skyTint: const Color(0xFF2E7CF6),
      art: (t) => _CollageFriends(t: t),
    ),
    _Slide(
      kicker: 'Ada yang seru',
      big: 'Dekat Kamu',
      highlight: 'cek petanya',
      backdropPhoto: 'assets/photos/taman.jpg',
      skyTint: const Color(0xFF1E9AD6),
      art: (t) => _CollageMap(t: t),
    ),
    _Slide(
      kicker: 'Bukan cuma',
      big: 'Rekomendasi',
      highlight: 'bisa langsung jajan',
      backdropPhoto: 'assets/photos/kuliner.jpg',
      skyTint: const Color(0xFF3E6CE8),
      art: (t) => _CollageShop(t: t),
    ),
  ];

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
    if (calm(context) || !TickerMode.valuesOf(context).enabled) {
      float.stop();
      return;
    }
    if (!float.isAnimating) float.repeat();
    auto = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!pages.hasClients ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
        return;
      }
      pages.animateToPage(
        (index + 1) % slides.length,
        duration: motionReveal,
        curve: motionCurve,
      );
    });
  }

  @override
  void dispose() {
    auto?.cancel();
    auth?.cancel();
    float.dispose();
    pages.dispose();
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

  void goToSlide(int i) {
    setState(() => index = i);
    if (pages.hasClients) {
      pages.animateToPage(i, duration: motionPage, curve: motionCurve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = slides[index];
    final screen = MediaQuery.sizeOf(context);
    final wide =
        screen.width >= 820 || (screen.width > screen.height && screen.height < 580);
    final compactH = screen.height < 640;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFD6E8FF),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _ImmersiveBackdrop(
              photo: slide.backdropPhoto,
              skyTint: slide.skyTint,
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1120 : 480),
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
            flex: 10,
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FrostedSurface(
                    radius: 34,
                    sigma: 22,
                    fill: Colors.white.withValues(alpha: .84),
                    padding: EdgeInsets.fromLTRB(
                      26,
                      veryShort ? 16 : 26,
                      26,
                      veryShort ? 14 : 22,
                    ),
                    shadows: [
                      BoxShadow(
                        color: ink.withValues(alpha: .12),
                        blurRadius: 34,
                        offset: const Offset(0, 14),
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
          const SizedBox(width: 24),
          Expanded(
            flex: 11,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: pages,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => index = i),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: AnimatedBuilder(
                        animation: float,
                        builder: (_, _) => slides[i].art(
                          calm(context) ? 0 : float.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context, _Slide slide, bool compactH) =>
      Padding(
        padding: EdgeInsets.fromLTRB(14, compactH ? 4 : 10, 14, compactH ? 6 : 12),
        child: Column(
          children: [
            FrostedSurface(
              radius: 99,
              sigma: 16,
              fill: Colors.white.withValues(alpha: .78),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: SvgPicture.asset(
                'assets/logo.svg',
                height: compactH ? 23 : 28,
                semanticsLabel: 'Spots',
              ),
            ),
            SizedBox(height: compactH ? 4 : 8),
            Expanded(
              child: PageView.builder(
                controller: pages,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedBuilder(
                    animation: float,
                    builder: (_, _) => slides[i].art(
                      calm(context) ? 0 : float.value,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compactH ? 4 : 8),
            FrostedSurface(
              radius: 32,
              sigma: 22,
              fill: Colors.white.withValues(alpha: .86),
              padding: EdgeInsets.fromLTRB(
                20,
                compactH ? 12 : 18,
                20,
                compactH ? 10 : 14,
              ),
              shadows: [
                BoxShadow(
                  color: ink.withValues(alpha: .12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
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
          ],
        ),
      );
}

/// Latar penuh layar yang memadukan foto tempat nyata dengan ilustrasi langit,
/// cahaya matahari, awan lembut, dan siluet bukit agar kolase terasa imersif.
class _ImmersiveBackdrop extends StatelessWidget {
  const _ImmersiveBackdrop({required this.photo, required this.skyTint});
  final String photo;
  final Color skyTint;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: motionTime(context, const Duration(milliseconds: 650)),
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, ?current],
            ),
            child: Image.asset(
              photo,
              key: ValueKey(photo),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              gaplessPlayback: true,
            ),
          ),
          AnimatedContainer(
            duration: motionTime(context, const Duration(milliseconds: 650)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  skyTint.withValues(alpha: .54),
                  const Color(0xFFDDF0FF).withValues(alpha: .58),
                  const Color(0xFFF3F8FF).withValues(alpha: .76),
                ],
                stops: const [0, .52, 1],
              ),
            ),
          ),
          const CustomPaint(painter: _ScenicIllustrationPainter()),
        ],
      ),
    ),
  );
}

class _ScenicIllustrationPainter extends CustomPainter {
  const _ScenicIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pancaran matahari hangat di kanan atas
    final sunCenter = Offset(w * .84, h * .12);
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF7D6).withValues(alpha: .65),
          const Color(0xFFFFFFFF).withValues(alpha: .22),
          Colors.transparent,
        ],
        stops: const [0, .42, 1],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: w * .52));
    canvas.drawCircle(sunCenter, w * .52, sunGlow);

    // Ilustrasi awan menyatu tanpa garis tumpang-tindih
    void drawCloud(double cx, double cy, double scale, double alpha) {
      var cloud = Path()
        ..addOval(
          Rect.fromCircle(center: Offset(cx, cy), radius: 36 * scale),
        );
      for (final part in [
        Path()
          ..addOval(
            Rect.fromCircle(
              center: Offset(cx - 28 * scale, cy + 8 * scale),
              radius: 26 * scale,
            ),
          ),
        Path()
          ..addOval(
            Rect.fromCircle(
              center: Offset(cx + 30 * scale, cy + 6 * scale),
              radius: 28 * scale,
            ),
          ),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(cx, cy + 17 * scale),
                width: 104 * scale,
                height: 30 * scale,
              ),
              Radius.circular(15 * scale),
            ),
          ),
      ]) {
        cloud = Path.combine(PathOperation.union, cloud, part);
      }
      canvas.drawPath(cloud, Paint()..color = Colors.white.withValues(alpha: alpha));
    }

    drawCloud(w * .16, h * .13, 1.1, .55);
    drawCloud(w * .82, h * .20, .95, .46);
    drawCloud(w * .48, h * .08, .78, .38);

    // Ilustrasi padang bukit hijau-biru lembut di kaki cakrawala
    final backHill = Path()
      ..moveTo(0, h * .78)
      ..quadraticBezierTo(w * .28, h * .69, w * .62, h * .76)
      ..quadraticBezierTo(w * .84, h * .80, w, h * .73)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      backHill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFA7E2C8).withValues(alpha: .46),
            const Color(0xFFD9F2E6).withValues(alpha: .65),
          ],
        ).createShader(Offset.zero & size),
    );

    final frontHill = Path()
      ..moveTo(0, h * .84)
      ..quadraticBezierTo(w * .36, h * .77, w * .74, h * .84)
      ..quadraticBezierTo(w * .9, h * .87, w, h * .82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      frontHill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8FD9B6).withValues(alpha: .38),
            const Color(0xFFEAF6FF).withValues(alpha: .78),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_ScenicIllustrationPainter oldDelegate) => false;
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
    final disc = h - 10;
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
              padding: const EdgeInsets.all(5),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: disc,
                      height: disc,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Transform.flip(
                        flipX: true,
                        child: const SpotIcon(
                          Glyph.back,
                          size: 17,
                          color: Color(0xFF0B1120),
                          tint: false,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: disc + 8),
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
                ],
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

// ---------- Kolase ilustrasi & foto nyata per slide ----------

double _bob(double t, double phase) => math.sin((t + phase) * math.pi * 2) * 4;

class _Canvas extends StatelessWidget {
  const _Canvas({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = math.min(box.maxWidth, 430.0);
      final h = math.min(box.maxHeight, w * 1.04);
      return Center(
        child: SizedBox(
          width: w,
          height: h,
          child: FittedBox(
            child: SizedBox(
              width: 360,
              height: 374,
              child: Stack(clipBehavior: Clip.none, children: children),
            ),
          ),
        ),
      );
    },
  );
}

class _GlassAura extends StatelessWidget {
  const _GlassAura({required this.color, required this.size, this.angle = 0});
  final Color color;
  final double size, angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: size,
      height: size * .82,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .64),
            color.withValues(alpha: .28),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * .48),
          topRight: Radius.circular(size * .36),
          bottomLeft: Radius.circular(size * .32),
          bottomRight: Radius.circular(size * .52),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: .72),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
    ),
  );
}

class _PolaroidPhoto extends StatelessWidget {
  const _PolaroidPhoto({
    required this.asset,
    required this.width,
    required this.height,
    required this.caption,
    this.angle = 0,
  });

  final String asset, caption;
  final double width, height, angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: .16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                asset,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GlassNote extends StatelessWidget {
  const _GlassNote(
    this.text, {
    this.angle = 0,
    this.width = 144,
    this.glyph = Glyph.sparkle,
  });

  final String text;
  final double angle, width;
  final Glyph glyph;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: FrostedSurface(
      radius: 20,
      sigma: 14,
      fill: Colors.white.withValues(alpha: .88),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      shadows: [
        BoxShadow(
          color: ink.withValues(alpha: .12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      child: SizedBox(
        width: width - 24,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SpotIcon(glyph, size: 16, color: piko, accent: piko),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: fontBody,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  height: 1.2,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CollageFriends extends StatelessWidget {
  const _CollageFriends({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) => _Canvas(
    children: [
      const Positioned(
        left: 22,
        top: 38,
        child: _GlassAura(color: Color(0xFF62A2FF), size: 320, angle: -.08),
      ),
      Positioned(
        left: 12,
        top: 20 + _bob(t, 0),
        child: const _PolaroidPhoto(
          asset: 'assets/photos/kuliner.jpg',
          caption: 'Rawon Setan · Surabaya',
          width: 196,
          height: 174,
          angle: -.05,
        ),
      ),
      Positioned(
        right: 4,
        top: 12 + _bob(t, .3),
        child: const _GlassNote(
          'Kuahnya asli\njuara banget!',
          angle: .05,
          width: 148,
          glyph: Glyph.heart,
        ),
      ),
      Positioned(
        right: 12,
        bottom: 22 + _bob(t, .55),
        child: const _PolaroidPhoto(
          asset: 'assets/photos/hangout.jpg',
          caption: 'Kopi Sudut Sore',
          width: 174,
          height: 188,
          angle: .06,
        ),
      ),
      Positioned(
        left: 18,
        bottom: 34 + _bob(t, .8),
        child: CategorySticker(spotCategories[0], tilt: -.05),
      ),
      Positioned(
        left: 156,
        top: 144 + _bob(t, .15),
        child: const Mascot(
          kind: MascotKind.piko,
          size: 92,
          mood: MascotMood.cool,
          wave: true,
          interactive: false,
        ),
      ),
    ],
  );
}

class _CollageMap extends StatelessWidget {
  const _CollageMap({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) => _Canvas(
    children: [
      const Positioned(
        left: 16,
        top: 32,
        child: _GlassAura(color: mint, size: 326, angle: .08),
      ),
      Positioned(
        left: 44,
        top: 26,
        child: Transform.rotate(
          angle: .04,
          child: Container(
            width: 272,
            height: 298,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: ink.withValues(alpha: .16),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(painter: _MapPainter()),
            ),
          ),
        ),
      ),
      for (final (x, y, glyph, active, phase) in [
        (112.0, 92.0, Glyph.cup, true, 0.0),
        (226.0, 128.0, Glyph.bowl, false, .3),
        (148.0, 214.0, Glyph.mountain, false, .6),
      ])
        Positioned(
          left: x,
          top: y + _bob(t, phase),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xFF62A2FF), Color(0xFF3B76F6)],
                    )
                  : null,
              color: active ? null : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: surfaceShadow,
            ),
            child: SpotIcon(
              glyph,
              size: 22,
              color: active ? Colors.white : ink,
              accent: piko,
              tint: !active,
            ),
          ),
        ),
      Positioned(
        left: 2,
        top: 38 + _bob(t, .2),
        child: Transform.rotate(
          angle: -.05,
          child: FrostedSurface(
            radius: 20,
            sigma: 14,
            fill: Colors.white.withValues(alpha: .90),
            padding: const EdgeInsets.all(8),
            shadows: surfaceShadow,
            child: SizedBox(
              width: 152,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/photos/nongkrong.jpg',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kopi Teras\n650 m dari sini',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: ink,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: 22,
        bottom: 24 + _bob(t, .5),
        child: FrostedSurface(
          radius: 99,
          sigma: 14,
          fill: Colors.white.withValues(alpha: .90),
          padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
          shadows: surfaceShadow,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpotIcon(Glyph.fire, size: 17, color: piko, accent: coral),
              SizedBox(width: 5),
              Text(
                '18 spot dekatmu',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: 2,
        bottom: 8 + _bob(t, .7),
        child: const Mascot(
          kind: MascotKind.pino,
          size: 92,
          mood: MascotMood.laugh,
          wave: true,
          interactive: false,
        ),
      ),
    ],
  );
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEEF4FC),
    );
    final park = Paint()..color = const Color(0xFFCBEEDB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 160, 90, 70),
        const Radius.circular(16),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(170, 30, 70, 60),
        const Radius.circular(16),
      ),
      park,
    );
    final water = Paint()..color = const Color(0xFFB9DCF9);
    canvas.drawPath(
      Path()
        ..moveTo(0, 252)
        ..quadraticBezierTo(120, 234, 280, 284)
        ..lineTo(280, 310)
        ..lineTo(0, 310)
        ..close(),
      water,
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-10, 120), Offset(size.width + 10, 70), road);
    canvas.drawLine(const Offset(140, -10), const Offset(120, 310), road);
    canvas.drawLine(
      const Offset(-10, 210),
      Offset(size.width + 10, 240),
      road..strokeWidth = 6,
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) => false;
}

class _CollageShop extends StatelessWidget {
  const _CollageShop({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) => _Canvas(
    children: [
      const Positioned(
        left: 20,
        top: 34,
        child: _GlassAura(color: coral, size: 324, angle: -.09),
      ),
      Positioned(
        left: 68,
        top: 18 + _bob(t, 0),
        child: const _PolaroidPhoto(
          asset: 'assets/photos/sate.jpg',
          caption: 'Sate Klopo Ondomohen',
          width: 212,
          height: 232,
          angle: .04,
        ),
      ),
      Positioned(
        left: 8,
        top: 48 + _bob(t, .35),
        child: const _PolaroidPhoto(
          asset: 'assets/photos/nongkrong.jpg',
          caption: 'Es Kopi',
          width: 116,
          height: 132,
          angle: -.10,
        ),
      ),
      Positioned(
        right: 2,
        top: 172 + _bob(t, .6),
        child: Transform.rotate(
          angle: .06,
          child: FrostedSurface(
            radius: 20,
            sigma: 14,
            fill: Colors.white.withValues(alpha: .92),
            padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
            shadows: surfaceShadow,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Es Kopi Aren',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Rp22.000 · Market',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: piko,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 16,
        bottom: 22 + _bob(t, .8),
        child: const _GlassNote(
          'Pesan dulu,\nambil di tempat!',
          angle: -.05,
          width: 152,
          glyph: Glyph.bag,
        ),
      ),
      Positioned(
        right: 24,
        bottom: 6 + _bob(t, .25),
        child: const Mascot(
          kind: MascotKind.tote,
          size: 94,
          mood: MascotMood.love,
          wave: true,
          interactive: false,
        ),
      ),
    ],
  );
}
