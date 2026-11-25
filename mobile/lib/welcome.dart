import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class _HeroScene {
  const _HeroScene({
    required this.photo,
    required this.skyHeadline,
    required this.placeName,
    required this.placeMeta,
    required this.tags,
    required this.sheetTitle,
    required this.sheetBody,
  });

  final String photo, skyHeadline, placeName, placeMeta, sheetTitle, sheetBody;
  final List<String> tags;
}

const _scenes = [
  _HeroScene(
    photo: 'assets/photos/hangout.jpg',
    skyHeadline: 'KETEMU SPOT\nFAVORITMU',
    placeName: 'Kopi Sudut Sore',
    placeMeta: 'Surabaya · 650 m dari sini',
    tags: ['Kopi', 'Nongkrong', 'Buka'],
    sheetTitle: 'Spot Terbaik Hanya\nSatu Geseran Saja',
    sheetBody:
        'Temukan kedai kopi, warung lokal, dan sudut kota dari cerita jujur orang sekitar.',
  ),
  _HeroScene(
    photo: 'assets/photos/kuliner.jpg',
    skyHeadline: 'KULINER ASLI\nWARGA LOKAL',
    placeName: 'Rawon Setan Mbak Endang',
    placeMeta: 'Embong Malang · 12 dokumentasi',
    tags: ['Kuliner', 'Malam', 'Rame'],
    sheetTitle: 'Foto Jujur dari\nPengunjung Nyata',
    sheetBody:
        'Lihat foto dan video asli berbagai pengunjung sebelum berangkat, lengkap dengan rute.',
  ),
  _HeroScene(
    photo: 'assets/photos/taman.jpg',
    skyHeadline: 'JALAN SORE\nTANPA NYASAR',
    placeName: 'Tugu Pahlawan',
    placeMeta: 'Rute motor 6 mnt · Jalan kaki',
    tags: ['Wisata', 'Taman', 'Sore'],
    sheetTitle: 'Buka Peta & Pesan\nLangsung di Tempat',
    sheetBody:
        'Cek jarak di peta sekitar, simpan favoritmu, atau pesan langsung dari tokonya.',
  ),
];

/// Halaman sambutan bergaya editorial langit cerah (inspirasi happn & Recenter):
/// bagian atas kanvas langit biru dengan tipografi besar & kartu foto nyata berlabel kaca,
/// bagian bawah lembaran putih membulat dengan tombol pil hitam berikon lingkaran.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.repo, required this.onDone});
  final SpotsRepository repo;
  final VoidCallback onDone;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final pages = PageController();
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
      if (!pages.hasClients ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
        return;
      }
      pages.animateToPage(
        (index + 1) % _scenes.length,
        duration: motionReveal,
        curve: motionCurve,
      );
    });
  }

  @override
  void dispose() {
    auto?.cancel();
    auth?.cancel();
    pages.dispose();
    super.dispose();
  }

  Future<void> startAuth() async {
    await openAuth(context, widget.repo);
    if (widget.repo.userId != null && mounted) widget.onDone();
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

  Widget _dots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < _scenes.length; i++)
        AnimatedContainer(
          duration: motionTime(context, motionPage),
          curve: motionCurve,
          width: i == index ? 20 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i == index
                ? const Color(0xFF1E78F0)
                : ink.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
    ],
  );

  Widget _bottomCard(_HeroScene scene, {bool compact = false}) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      compact ? 14 : 22,
      24,
      compact ? 10 : 16,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dots(),
        SizedBox(height: compact ? 10 : 16),
        AnimatedSwitcher(
          duration: motionTime(context, motionPage),
          child: Column(
            key: ValueKey(index),
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  scene.sheetTitle,
                  textAlign: TextAlign.center,
                  style: display(
                    compact ? 25 : 29,
                    color: const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 330),
                child: Text(
                  scene.sheetBody,
                  textAlign: TextAlign.center,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: fontBody,
                    fontWeight: FontWeight.w700,
                    color: muted,
                    fontSize: compact ? 12.5 : 13.5,
                    height: 1.42,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 14 : 22),
        // Tombol pil utama bergaya happn: kapsul gelap dengan lingkaran panah putih di kiri
        Semantics(
          button: true,
          label: 'Mulai Sekarang',
          child: Bouncy(
            onTap: busy ? null : startAuth,
            scale: .97,
            child: Container(
              height: compact ? 50 : 56,
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1120),
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x260B1120),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: compact ? 38 : 44,
                      height: compact ? 38 : 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Transform.rotate(
                        angle: math.pi,
                        child: const SpotIcon(
                          Glyph.back,
                          size: 19,
                          color: Color(0xFF0B1120),
                          tint: false,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Mulai Sekarang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 14.5 : 16,
                        letterSpacing: -.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        // Baris sekunder yang bersih & tenang: Google cepat atau lihat-lihat dulu
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Bouncy(
                onTap: busy ? null : google,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GoogleMark(size: 15),
                      const SizedBox(width: 6),
                      Text(
                        busy ? 'Menghubungkan…' : 'Masuk dengan Google',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: .4),
                  shape: BoxShape.circle,
                ),
              ),
              Bouncy(
                onTap: widget.onDone,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    'Lihat-lihat dulu',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: muted,
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

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[index];
    final screen = MediaQuery.sizeOf(context);
    final landscape = screen.width > screen.height && screen.height < 580;

    return Scaffold(
      backgroundColor: const Color(0xFF1474EA),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E68DC),
              Color(0xFF429BF8),
              Color(0xFFCBE6FF),
            ],
            stops: [0, .52, 1],
          ),
        ),
        child: landscape
            ? SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 11,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: _SkyHeroPager(
                                controller: pages,
                                index: index,
                                compact: true,
                                onPageChanged: (i) =>
                                    setState(() => index = i),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: surfaceShadow,
                              ),
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                child: _bottomCard(scene, compact: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      Expanded(
                        child: SafeArea(
                          bottom: false,
                          child: _SkyHeroPager(
                            controller: pages,
                            index: index,
                            compact: screen.height < 680,
                            onPageChanged: (i) => setState(() => index = i),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(36),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F0D2558),
                              blurRadius: 32,
                              offset: Offset(0, -6),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: _bottomCard(
                            scene,
                            compact: screen.height < 680,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SkyHeroPager extends StatelessWidget {
  const _SkyHeroPager({
    required this.controller,
    required this.index,
    required this.onPageChanged,
    this.compact = false,
  });

  final PageController controller;
  final int index;
  final ValueChanged<int> onPageChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      // Cahaya awan lembut di latar langit
      Positioned(
        top: -40,
        right: -50,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .16),
          ),
        ),
      ),
      Positioned(
        bottom: 10,
        left: -40,
        child: Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .22),
          ),
        ),
      ),
      // Watermark huruf besar SPOTS di langit seperti referensi happn
      Positioned(
        left: 12,
        right: 12,
        top: compact ? 34 : 52,
        child: IgnorePointer(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SPOTS',
              style: TextStyle(
                fontFamily: fontDisplay,
                fontSize: 96,
                height: .95,
                letterSpacing: 3,
                color: Colors.white.withValues(alpha: .20),
              ),
            ),
          ),
        ),
      ),
      Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: compact ? 6 : 12, bottom: 6),
            child: SvgPicture.asset(
              'assets/logo_light.svg',
              height: compact ? 24 : 30,
              semanticsLabel: 'Spots',
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: _scenes.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  compact ? 4 : 8,
                  18,
                  compact ? 10 : 14,
                ),
                child: _SkyPhotoCard(scene: _scenes[i], compact: compact),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _SkyPhotoCard extends StatelessWidget {
  const _SkyPhotoCard({required this.scene, required this.compact});
  final _HeroScene scene;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: Colors.white.withValues(alpha: .55),
        width: 1.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x290A2558),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28.5),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            scene.photo,
            fit: BoxFit.cover,
            cacheWidth: 800,
            errorBuilder: (_, _, _) => DemoCover(seed: scene.photo),
          ),
          // Gradasi biru langit di atas & gelap lembut di bawah agar teks putih selalu tajam
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x660E5EC4),
                  Color(0x0D0E5EC4),
                  Color(0xAA0C1838),
                ],
                stops: [0, .46, 1],
              ),
            ),
          ),
          // Lencana kaca di pojok atas (seperti kartu tengah happn)
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            child: Row(
              children: [
                FrostedSurface(
                  radius: 20,
                  sigma: 12,
                  dark: true,
                  fill: Colors.white.withValues(alpha: .26),
                  borderColor: Colors.white.withValues(alpha: .45),
                  shadows: const [],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  child: const Text(
                    'Dekat kamu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const Spacer(),
                FrostedSurface(
                  radius: 20,
                  sigma: 12,
                  dark: true,
                  fill: Colors.white.withValues(alpha: .26),
                  borderColor: Colors.white.withValues(alpha: .45),
                  shadows: const [],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpotIcon(
                        Glyph.fire,
                        size: 14,
                        color: Colors.white,
                        tint: false,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Populer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tipografi miring putih khas poster di atas foto
          if (!compact)
            Positioned(
              left: 16,
              right: 60,
              top: 48,
              child: Transform.rotate(
                angle: -.04,
                alignment: Alignment.topLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    scene.skyHeadline,
                    style: display(26, color: Colors.white, height: 1.02),
                  ),
                ),
              ),
            ),
          // Tombol aksi kaca bundar mengambang di sisi kanan bawah foto
          if (!compact)
            Positioned(
              right: 12,
              bottom: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final glyph in [Glyph.chat, Glyph.heart, Glyph.pin])
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: FrostedSurface(
                        radius: 20,
                        sigma: 12,
                        dark: true,
                        fill: Colors.white.withValues(alpha: .26),
                        borderColor: Colors.white.withValues(alpha: .48),
                        shadows: const [],
                        child: SizedBox.square(
                          dimension: 36,
                          child: Center(
                            child: SpotIcon(
                              glyph,
                              size: 17,
                              color: Colors.white,
                              tint: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Info tempat + pil kategori kaca di bagian bawah foto
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scene.placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scene.placeMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in scene.tags)
                      FrostedSurface(
                        radius: 16,
                        sigma: 10,
                        dark: true,
                        fill: Colors.white.withValues(alpha: .22),
                        borderColor: Colors.white.withValues(alpha: .40),
                        shadows: const [],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
