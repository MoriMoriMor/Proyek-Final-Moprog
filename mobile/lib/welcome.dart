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

const _night = Color(0xFF16226B);
const _deep = Color(0xFF0D1546);
const _lime = Color(0xFFCDF25A);
const _paper = Color(0xFFF3E7CF);

class _Slide {
  const _Slide(this.kicker, this.big, this.highlight, this.art);
  final String kicker, big, highlight;
  final Widget Function(double t) art;
}

/// Halaman sambutan dan masuk. Muncul saat aplikasi dibuka tanpa akun.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.repo, required this.onDone});
  final SpotsRepository repo;

  /// Dipanggil setelah berhasil masuk atau memilih lihat-lihat dulu.
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
  )..repeat();
  Timer? auto;
  int index = 0;
  bool busy = false;
  StreamSubscription<void>? auth;

  late final slides = [
    _Slide(
      'Spot berikutnya',
      'Wajib Datang',
      'mulai dari sini',
      (t) => _CollageFriends(t: t),
    ),
    _Slide(
      'Ada yang seru',
      'Dekat Kamu',
      'cek petanya',
      (t) => _CollageMap(t: t),
    ),
    _Slide(
      'Bukan cuma',
      'Rekomendasi',
      'bisa langsung jajan',
      (t) => _CollageShop(t: t),
    ),
  ];

  @override
  void initState() {
    super.initState();
    auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!pages.hasClients) return;
      pages.animateToPage(
        (index + 1) % slides.length,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
    // Masuk lewat Google kembali ke aplikasi; tutup halaman ini begitu ada akun.
    auth = widget.repo.authChanges.listen((_) {
      if (widget.repo.userId != null && mounted) widget.onDone();
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

  @override
  Widget build(BuildContext context) {
    final slide = slides[index];
    final screen = MediaQuery.sizeOf(context);
    final height = screen.height;
    final landscape = screen.width > screen.height && screen.height < 560;
    return Scaffold(
      backgroundColor: _deep,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_night, _deep],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: landscape ? 900 : 460),
              child: landscape
                  ? Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: height < 500 ? 6 : 14,
                                ),
                                child: SvgPicture.asset(
                                  'assets/logo_light.svg',
                                  height: height < 500 ? 24 : 34,
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
                                      18,
                                      12,
                                      18,
                                      0,
                                    ),
                                    child: AnimatedBuilder(
                                      animation: float,
                                      builder: (_, _) =>
                                          slides[i].art(float.value),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < slides.length; i++)
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      width: i == index ? 22 : 7,
                                      height: 7,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: i == index
                                            ? _lime
                                            : Colors.white24,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 380),
                                    transitionBuilder: (child, a) =>
                                        FadeTransition(
                                          opacity: a,
                                          child: SlideTransition(
                                            position: Tween(
                                              begin: const Offset(0, .12),
                                              end: Offset.zero,
                                            ).animate(a),
                                            child: child,
                                          ),
                                        ),
                                    child: _Headline(
                                      key: ValueKey(index),
                                      slide: slide,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                    ),
                                    child: Column(
                                      children: [
                                        _PillButton(
                                          onTap: busy ? null : google,
                                          color: Colors.black,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const GoogleMark(size: 22),
                                              const SizedBox(width: 12),
                                              Flexible(
                                                child: Text(
                                                  busy
                                                      ? 'Menghubungkan…'
                                                      : 'Lanjut dengan Google',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _PillButton(
                                          onTap: busy ? null : email,
                                          color: Colors.white.withValues(
                                            alpha: .12,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SpotIcon(
                                                Glyph.chat,
                                                size: 20,
                                                color: Colors.white,
                                                tint: false,
                                              ),
                                              SizedBox(width: 10),
                                              Text('Pakai email'),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: widget.onDone,
                                          child: const Text(
                                            'Lihat-lihat dulu',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                          padding: EdgeInsets.only(top: height < 500 ? 6 : 14),
                          child: SvgPicture.asset(
                            'assets/logo_light.svg',
                            height: height < 500 ? 24 : 34,
                            semanticsLabel: 'Spots',
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: pages,
                            itemCount: slides.length,
                            onPageChanged: (i) => setState(() => index = i),
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                              child: AnimatedBuilder(
                                animation: float,
                                builder: (_, _) => slides[i].art(float.value),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < slides.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                width: i == index ? 22 : 7,
                                height: 7,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: i == index ? _lime : Colors.white24,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: height < 700 ? 10 : 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, .12),
                                end: Offset.zero,
                              ).animate(a),
                              child: child,
                            ),
                          ),
                          child: _Headline(key: ValueKey(index), slide: slide),
                        ),
                        SizedBox(height: height < 700 ? 14 : 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              _PillButton(
                                onTap: busy ? null : google,
                                color: Colors.black,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const GoogleMark(size: 22),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        busy
                                            ? 'Menghubungkan…'
                                            : 'Lanjut dengan Google',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _PillButton(
                                onTap: busy ? null : email,
                                color: Colors.white.withValues(alpha: .12),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SpotIcon(
                                      Glyph.chat,
                                      size: 20,
                                      color: Colors.white,
                                      tint: false,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Pakai email'),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onDone,
                                child: const Text(
                                  'Lihat-lihat dulu',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
  const _Headline({super.key, required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        slide.kicker,
        style: const TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontSize: 18,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              // Garis putih tebal di belakang huruf, seperti stiker yang digunting.
              Text(
                slide.big,
                style: TextStyle(
                  fontFamily: fontDisplay,
                  fontSize: 54,
                  height: 1.05,
                  letterSpacing: -.5,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 12
                    ..strokeJoin = StrokeJoin.round
                    ..color = Colors.white,
                ),
              ),
              Text(
                slide.big,
                style: const TextStyle(
                  fontFamily: fontDisplay,
                  fontSize: 54,
                  height: 1.05,
                  letterSpacing: -.5,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -6),
        child: Transform.rotate(
          angle: -.035,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 6),
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              slide.highlight,
              style: const TextStyle(
                fontFamily: fontBody,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                height: 1.1,
                color: Color(0xFF1C3A0E),
              ),
            ),
          ),
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
  });
  final Widget child;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: Bouncy(
      onTap: onTap,
      scale: .96,
      child: Container(
        height: 56,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(40),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16.5,
          ),
          child: child,
        ),
      ),
    ),
  );
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

// ---------- Kolase per slide ----------

/// Kartu foto berbingkai putih yang sedikit miring.
class _Photo extends StatelessWidget {
  const _Photo({
    required this.seed,
    required this.width,
    required this.height,
    this.angle = 0,
  });
  final String seed;
  final double width, height, angle;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: DemoCover(seed: seed),
      ),
    ),
  );
}

/// Sobekan kertas dengan tulisan tangan.
class _Note extends StatelessWidget {
  const _Note(
    this.text, {
    this.angle = 0,
    this.width = 150,
    this.color = _paper,
  });
  final String text;
  final double angle, width;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: ClipPath(
      clipper: _TornClipper(),
      child: Container(
        width: width,
        color: color,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            height: 1.2,
            color: Color(0xFF3A2E1E),
          ),
        ),
      ),
    ),
  );
}

class _TornClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final r = math.Random(size.width.toInt());
    final path = Path()..moveTo(0, 6);
    for (var x = 0.0; x <= size.width; x += 9) {
      path.lineTo(x, 2 + r.nextDouble() * 7);
    }
    path.lineTo(size.width, size.height - 6);
    for (var x = size.width; x >= 0; x -= 9) {
      path.lineTo(x, size.height - 2 - r.nextDouble() * 7);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornClipper old) => false;
}

/// Gumpalan warna di belakang kolase.
class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size, this.angle = 0});
  final Color color;
  final double size, angle;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: size,
      height: size * .82,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * .5),
          topRight: Radius.circular(size * .35),
          bottomLeft: Radius.circular(size * .3),
          bottomRight: Radius.circular(size * .55),
        ),
      ),
    ),
  );
}

double _bob(double t, double phase) => math.sin((t + phase) * math.pi * 2) * 4;

class _Canvas extends StatelessWidget {
  const _Canvas({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = math.min(box.maxWidth, 420.0);
      final h = math.min(box.maxHeight, w * 1.05);
      return Center(
        child: SizedBox(
          width: w,
          height: h,
          child: FittedBox(
            child: SizedBox(
              width: 360,
              height: 378,
              child: Stack(clipBehavior: Clip.none, children: children),
            ),
          ),
        ),
      );
    },
  );
}

class _CollageFriends extends StatelessWidget {
  const _CollageFriends({required this.t});
  final double t;
  @override
  Widget build(BuildContext context) => _Canvas(
    children: [
      const Positioned(
        left: 20,
        top: 40,
        child: _Blob(color: Color(0xFFFF7A2F), size: 330, angle: -.1),
      ),
      const Positioned(
        left: 36,
        top: 54,
        child: _Blob(color: yellow, size: 296, angle: .08),
      ),
      Positioned(
        left: 14,
        top: 22 + _bob(t, 0),
        child: const _Photo(
          seed: 'demo:kuliner:welcome1',
          width: 200,
          height: 160,
          angle: -.06,
        ),
      ),
      Positioned(
        right: 6,
        top: 8 + _bob(t, .3),
        child: const _Note(
          'Mie kocoknya\njuara banget',
          angle: .07,
          width: 140,
          color: Color(0xFFE9F7B7),
        ),
      ),
      Positioned(
        right: 14,
        bottom: 26 + _bob(t, .55),
        child: const _Photo(
          seed: 'demo:destinasi:welcome2',
          width: 170,
          height: 190,
          angle: .07,
        ),
      ),
      Positioned(
        left: 26,
        bottom: 34 + _bob(t, .8),
        child: const _Note('Weekend\nkemarin!', angle: -.08, width: 128),
      ),
      Positioned(
        left: 170,
        top: 150 + _bob(t, .15),
        child: const Mascot(
          kind: MascotKind.piko,
          size: 84,
          mood: MascotMood.cool,
          wave: true,
          interactive: false,
        ),
      ),
      const Positioned(
        left: 6,
        top: 8,
        child: SpotIcon(
          Glyph.heart,
          size: 34,
          color: Colors.white,
          accent: coral,
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
        left: 10,
        top: 30,
        child: _Blob(color: mint, size: 340, angle: .12),
      ),
      const Positioned(
        left: 30,
        top: 48,
        child: _Blob(color: yellow, size: 300, angle: -.08),
      ),
      Positioned(
        left: 46,
        top: 30,
        child: Transform.rotate(
          angle: .05,
          child: Container(
            width: 270,
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1EA),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CustomPaint(painter: _MapPainter()),
            ),
          ),
        ),
      ),
      for (final (x, y, glyph, color, phase) in [
        (110.0, 90.0, Glyph.cup, caramel, 0.0),
        (230.0, 130.0, Glyph.bowl, tomato, .3),
        (150.0, 220.0, Glyph.mountain, mint, .6),
        (240.0, 250.0, Glyph.ball, lime, .85),
      ])
        Positioned(
          left: x,
          top: y + _bob(t, phase),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SpotIcon(glyph, size: 22, color: Colors.white, tint: false),
          ),
        ),
      Positioned(
        left: 0,
        top: 40 + _bob(t, .2),
        child: Transform.rotate(
          angle: -.08,
          child: Container(
            padding: const EdgeInsets.all(8),
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox.square(
                    dimension: 44,
                    child: DemoCover(seed: 'demo:kafe:map1'),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kopi Teras\n1,2 km',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
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
      Positioned(
        left: 24,
        bottom: 24 + _bob(t, .5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
          decoration: BoxDecoration(
            color: yellow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpotIcon(Glyph.fire, size: 18, accent: coral),
              SizedBox(width: 4),
              Text(
                'Lagi rame',
                style: TextStyle(fontWeight: FontWeight.w900, color: ink),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: 0,
        bottom: 6 + _bob(t, .7),
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
      Paint()..color = const Color(0xFFF4F1EA),
    );
    final park = Paint()..color = const Color(0xFFCDEBC4);
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
    final water = Paint()..color = const Color(0xFFBFE2F7);
    canvas.drawPath(
      Path()
        ..moveTo(0, 260)
        ..quadraticBezierTo(120, 240, 280, 290)
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
    canvas.drawLine(const Offset(230, -10), const Offset(260, 310), road);
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
        child: _Blob(color: coral, size: 330, angle: -.14),
      ),
      const Positioned(
        left: 40,
        top: 50,
        child: _Blob(color: Color(0xFFFF9F1C), size: 290, angle: .1),
      ),
      Positioned(
        left: 70,
        top: 20 + _bob(t, 0),
        child: const _Photo(
          seed: 'demo:belanja:welcome3',
          width: 210,
          height: 240,
          angle: .04,
        ),
      ),
      Positioned(
        left: 10,
        top: 50 + _bob(t, .35),
        child: const _Photo(
          seed: 'demo:kafe:welcome4',
          width: 110,
          height: 120,
          angle: -.12,
        ),
      ),
      Positioned(
        right: 0,
        top: 170 + _bob(t, .6),
        child: Transform.rotate(
          angle: .08,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Es Kopi Aren',
                  style: TextStyle(fontWeight: FontWeight.w900, color: ink),
                ),
                Text(
                  'Rp22.000',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD9541E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 20,
        bottom: 20 + _bob(t, .8),
        child: const _Note('Ambil di\ntempat aja!', angle: -.06, width: 130),
      ),
      Positioned(
        right: 30,
        bottom: 6 + _bob(t, .25),
        child: const Mascot(
          kind: MascotKind.tote,
          size: 96,
          mood: MascotMood.love,
          wave: true,
          interactive: false,
        ),
      ),
    ],
  );
}
