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
    required this.subtitle,
    required this.art,
  });
  final String kicker, big, subtitle;
  final Widget Function(double t) art;
}

/// Halaman sambutan bernuansa cerah, bersih, dan hangat dengan foto tempat nyata
/// serta lapisan kaca buram (frosted glass). Muncul saat dibuka tanpa akun.
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
      kicker: 'Cerita warga sekitar',
      big: 'Tempat jujur,\nfoto asli.',
      subtitle: 'Warung, kedai kopi, dan sudut kota dari orang yang benar-benar ke sana.',
      art: (t) => _PhotoStage(
        t: t,
        primaryAsset: 'assets/photos/kuliner.jpg',
        secondaryAsset: 'assets/photos/nongkrong.jpg',
        placeLabel: 'Rawon Setan · Surabaya',
        tagLabel: 'Kuliner malam',
        glyph: Glyph.bowl,
        accent: tomato,
        mascot: MascotKind.piko,
        mood: MascotMood.happy,
      ),
    ),
    _Slide(
      kicker: 'Peta & rute langsung',
      big: 'Dekat kamu,\ntanpa nyasar.',
      subtitle: 'Lihat jarak, intip dokumentasi pengunjung lain, dan buka rute langsung.',
      art: (t) => _PhotoStage(
        t: t,
        primaryAsset: 'assets/photos/taman.jpg',
        secondaryAsset: 'assets/photos/kuliner.jpg',
        placeLabel: 'Tugu Pahlawan · 1,2 km',
        tagLabel: 'Rute motor & jalan',
        glyph: Glyph.pin,
        accent: mint,
        mascot: MascotKind.pino,
        mood: MascotMood.laugh,
      ),
    ),
    _Slide(
      kicker: 'Dukung usaha lokal',
      big: 'Lihat spotnya,\nlangsung pesan.',
      subtitle: 'Pesan menu favorit untuk diambil di lokasi atau diantar ke tempatmu.',
      art: (t) => _PhotoStage(
        t: t,
        primaryAsset: 'assets/photos/sate.jpg',
        secondaryAsset: 'assets/photos/nongkrong.jpg',
        placeLabel: 'Sate Klopo · Buka',
        tagLabel: 'Bisa ambil langsung',
        glyph: Glyph.bag,
        accent: caramel,
        mascot: MascotKind.tote,
        mood: MascotMood.love,
      ),
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

  Widget _dots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < slides.length; i++)
        AnimatedContainer(
          duration: motionTime(context, motionPage),
          curve: motionCurve,
          width: i == index ? 24 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i == index ? piko : ink.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
    ],
  );

  Widget _actions() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _PillButton(
        onTap: busy ? null : google,
        color: ink,
        foreground: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const GoogleMark(size: 17),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                busy ? 'Menghubungkan…' : 'Lanjut dengan Google',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _PillButton(
        onTap: busy ? null : email,
        color: glassStrong,
        foreground: ink,
        frosted: true,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpotIcon(Glyph.chat, size: 20, color: ink, accent: yellow),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Pakai email',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 2),
      TextButton(
        onPressed: widget.onDone,
        child: const Text(
          'Lihat-lihat dulu',
          style: TextStyle(
            color: muted,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final slide = slides[index];
    final screen = MediaQuery.sizeOf(context);
    final height = screen.height;
    final landscape = screen.width > screen.height && screen.height < 580;

    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: skyGlassGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: landscape ? 940 : 460),
              child: landscape
                  ? Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: height < 500 ? 6 : 12,
                                ),
                                child: SvgPicture.asset(
                                  'assets/logo.svg',
                                  height: height < 500 ? 24 : 32,
                                  semanticsLabel: 'Spots',
                                ),
                              ),
                              Expanded(
                                child: PageView.builder(
                                  controller: pages,
                                  itemCount: slides.length,
                                  onPageChanged: (i) =>
                                      setState(() => index = i),
                                  itemBuilder: (context, i) => Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      4,
                                    ),
                                    child: AnimatedBuilder(
                                      animation: float,
                                      builder: (_, _) =>
                                          slides[i].art(float.value),
                                    ),
                                  ),
                                ),
                              ),
                              _dots(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                24,
                                12,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: motionTime(context, motionReveal),
                                    child: _Headline(
                                      key: ValueKey(index),
                                      slide: slide,
                                      compact: true,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _actions(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: height < 620 ? 8 : 16),
                          child: SvgPicture.asset(
                            'assets/logo.svg',
                            height: height < 620 ? 28 : 34,
                            semanticsLabel: 'Spots',
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: pages,
                            itemCount: slides.length,
                            onPageChanged: (i) => setState(() => index = i),
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                              child: AnimatedBuilder(
                                animation: float,
                                builder: (_, _) => slides[i].art(float.value),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _dots(),
                        SizedBox(height: height < 680 ? 10 : 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AnimatedSwitcher(
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
                              compact: height < 680,
                            ),
                          ),
                        ),
                        SizedBox(height: height < 680 ? 12 : 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _actions(),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    super.key,
    required this.slide,
    this.compact = false,
  });
  final _Slide slide;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FrostedSurface(
        radius: 30,
        sigma: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(
          slide.kicker,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w900,
            color: blue,
            fontSize: 12.5,
          ),
        ),
      ),
      SizedBox(height: compact ? 6 : 10),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          slide.big,
          textAlign: TextAlign.center,
          style: display(compact ? 32 : 38, height: 1.06),
        ),
      ),
      SizedBox(height: compact ? 6 : 8),
      Text(
        slide.subtitle,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w700,
          color: muted,
          fontSize: compact ? 13 : 14,
          height: 1.38,
        ),
      ),
    ],
  );
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.child,
    required this.onTap,
    required this.color,
    required this.foreground,
    this.frosted = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final Color color, foreground;
  final bool frosted;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: 52,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
          ),
          child: child,
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Bouncy(
        onTap: onTap,
        scale: .97,
        child: frosted
            ? FrostedSurface(
                radius: 30,
                sigma: 16,
                fill: color,
                child: content,
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: surfaceShadow,
                ),
                child: content,
              ),
      ),
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

class _PhotoStage extends StatelessWidget {
  const _PhotoStage({
    required this.t,
    required this.primaryAsset,
    required this.secondaryAsset,
    required this.placeLabel,
    required this.tagLabel,
    required this.glyph,
    required this.accent,
    required this.mascot,
    required this.mood,
  });

  final double t;
  final String primaryAsset, secondaryAsset, placeLabel, tagLabel;
  final Glyph glyph;
  final Color accent;
  final MascotKind mascot;
  final MascotMood mood;

  double _bob(double phase) => math.sin((t + phase) * math.pi * 2) * 3.5;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = math.min(box.maxWidth, 380.0);
      final h = math.min(box.maxHeight, w * 1.02);
      return Center(
        child: SizedBox(
          width: w,
          height: h,
          child: FittedBox(
            child: SizedBox(
              width: 340,
              height: 346,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Kartu foto sekunder berbingkai putih lembut di kiri belakang
                  Positioned(
                    left: 8,
                    top: 38 + _bob(.35),
                    child: Transform.rotate(
                      angle: -.055,
                      child: _RealPhotoCard(
                        asset: secondaryAsset,
                        width: 146,
                        height: 186,
                        radius: 24,
                      ),
                    ),
                  ),
                  // Kartu foto utama tempat nyata
                  Positioned(
                    right: 12,
                    top: 14 + _bob(0),
                    child: _RealPhotoCard(
                      asset: primaryAsset,
                      width: 224,
                      height: 282,
                      radius: 30,
                      overlay: Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: FrostedSurface(
                          radius: 18,
                          sigma: 14,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              SpotIcon(glyph, size: 18, accent: accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  placeLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    color: ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Lencana kaca mengambang di kiri atas
                  Positioned(
                    left: 6,
                    top: 16 + _bob(.6),
                    child: FrostedSurface(
                      radius: 20,
                      sigma: 14,
                      fill: glassStrong,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            tagLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Maskot penyambut yang ramah di pojok kiri bawah
                  Positioned(
                    left: 14,
                    bottom: 8 + _bob(.18),
                    child: Mascot(
                      kind: mascot,
                      size: 86,
                      mood: mood,
                      wave: true,
                      interactive: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RealPhotoCard extends StatelessWidget {
  const _RealPhotoCard({
    required this.asset,
    required this.width,
    required this.height,
    required this.radius,
    this.overlay,
  });

  final String asset;
  final double width, height, radius;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glassBorder, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F192553),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius - 4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            cacheWidth: 640,
            errorBuilder: (_, _, _) => DemoCover(seed: asset),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0, .2),
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x55121B3D)],
              ),
            ),
          ),
          ?overlay,
        ],
      ),
    ),
  );
}
