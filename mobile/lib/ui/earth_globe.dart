import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'earth_geo.dart';
import 'motion.dart';
import 'theme.dart';

/// Data titik ilustrasi di permukaan Bumi untuk ditampilkan pada globe 3D.
class GlobeSpotPin {
  const GlobeSpotPin({
    required this.title,
    required this.city,
    required this.categoryKey,
    required this.lat,
    required this.lon,
    this.indonesia = false,
  });

  final String title, city, categoryKey;
  final double lat, lon;
  final bool indonesia;
}

/// Titik ilustrasi terbatas yang tersebar merata di seluruh dunia (bukan data
/// live database) supaya globe tetap lapang dan tidak terlalu penuh.
const List<GlobeSpotPin> kGlobeSpots = [
  // Nusantara — 3 titik representatif agar tetap rapi & tidak menumpuk
  GlobeSpotPin(
    title: 'Kuliner Nusantara',
    city: 'Sumatera',
    categoryKey: 'kuliner',
    lat: -0.50,
    lon: 101.40,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Kopi & Tongkrongan',
    city: 'Jawa',
    categoryKey: 'kafe',
    lat: -7.30,
    lon: 110.80,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Wisata Bahari',
    city: 'Maluku',
    categoryKey: 'destinasi',
    lat: -3.20,
    lon: 128.50,
    indonesia: true,
  ),
  // Asia & Oseania
  GlobeSpotPin(
    title: 'Kuliner Asia Timur',
    city: 'Tokyo',
    categoryKey: 'kuliner',
    lat: 35.68,
    lon: 139.69,
  ),
  GlobeSpotPin(
    title: 'Pasar Lokal',
    city: 'Mumbai',
    categoryKey: 'belanja',
    lat: 19.08,
    lon: 72.88,
  ),
  GlobeSpotPin(
    title: 'Aktivitas Pesisir',
    city: 'Sydney',
    categoryKey: 'olahraga',
    lat: -33.87,
    lon: 151.21,
  ),
  // Timur Tengah & Eropa
  GlobeSpotPin(
    title: 'Wisata Sejarah',
    city: 'Istanbul',
    categoryKey: 'belanja',
    lat: 41.01,
    lon: 28.98,
  ),
  GlobeSpotPin(
    title: 'Kedai Kopi',
    city: 'Paris',
    categoryKey: 'kafe',
    lat: 48.86,
    lon: 2.35,
  ),
  GlobeSpotPin(
    title: 'Eksplorasi Kota',
    city: 'London',
    categoryKey: 'aktivitas',
    lat: 51.51,
    lon: -0.13,
  ),
  // Afrika
  GlobeSpotPin(
    title: 'Jelajah Budaya',
    city: 'Kairo',
    categoryKey: 'aktivitas',
    lat: 30.04,
    lon: 31.24,
  ),
  GlobeSpotPin(
    title: 'Pesona Alam',
    city: 'Cape Town',
    categoryKey: 'destinasi',
    lat: -33.92,
    lon: 18.42,
  ),
  // Amerika Utara & Selatan
  GlobeSpotPin(
    title: 'Olahraga Taman',
    city: 'New York',
    categoryKey: 'olahraga',
    lat: 40.71,
    lon: -74.01,
  ),
  GlobeSpotPin(
    title: 'Sudut Santai',
    city: 'San Francisco',
    categoryKey: 'kafe',
    lat: 37.77,
    lon: -122.42,
  ),
  GlobeSpotPin(
    title: 'Pantai Selatan',
    city: 'Rio',
    categoryKey: 'destinasi',
    lat: -22.91,
    lon: -43.17,
  ),
  GlobeSpotPin(
    title: 'Penginapan Hangat',
    city: 'Buenos Aires',
    categoryKey: 'menginap',
    lat: -34.60,
    lon: -58.38,
  ),
];

/// Latar angkasa luar penuh layar berbasis vektor (tajam di semua ukuran layar).
class CosmicSpaceBackdrop extends StatefulWidget {
  const CosmicSpaceBackdrop({super.key, required this.wide});
  final bool wide;

  @override
  State<CosmicSpaceBackdrop> createState() => _CosmicSpaceBackdropState();
}

class _CosmicSpaceBackdropState extends State<CosmicSpaceBackdrop>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context) || !TickerMode.valuesOf(context).enabled) {
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
  Widget build(BuildContext context) => RepaintBoundary(
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(
          painter: _CosmicSpacePainter(
            phase: calm(context) ? .25 : controller.value,
            wide: widget.wide,
          ),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

class _CosmicSpacePainter extends CustomPainter {
  const _CosmicSpacePainter({required this.phase, required this.wide});
  final double phase;
  final bool wide;

  // Kecepatan kelip harus bilangan bulat agar sin(phase * speed * 2pi)
  // mulus tanpa lonjakan saat loop 8 detik berulang.
  static final List<(double x, double y, double r, double speed, int tint)>
  _stars = () {
    final rng = math.Random(4207);
    return List.generate(58, (i) {
      return (
        rng.nextDouble(),
        rng.nextDouble(),
        .9 + rng.nextDouble() * 1.9,
        (i % 2) + 1.0,
        i % 4,
      );
    });
  }();

  static const _sparkles = <(double, double, double, double)>[
    (.12, .16, 8.5, .0),
    (.88, .14, 10.0, .32),
    (.64, .09, 7.0, .61),
    (.93, .62, 8.0, .18),
    (.08, .74, 7.5, .77),
    (.46, .86, 6.8, .45),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050A1C), Color(0xFF0A1638), Color(0xFF0F2252)],
          stops: [0, .54, 1],
        ).createShader(rect),
    );

    final focus = wide
        ? Offset(size.width * .68, size.height * .50)
        : Offset(size.width * .50, size.height * .33);
    final haloRadius = size.shortestSide * (wide ? .66 : .62);
    canvas.drawCircle(
      focus,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2D76FF).withValues(alpha: .36),
            const Color(0xFF22C7F0).withValues(alpha: .14),
            Colors.transparent,
          ],
          stops: const [0, .46, 1],
        ).createShader(Rect.fromCircle(center: focus, radius: haloRadius)),
    );

    final secondNebula = Offset(size.width * .18, size.height * .20);
    final nebulaR = size.shortestSide * .42;
    canvas.drawCircle(
      secondNebula,
      nebulaR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6B5BFF).withValues(alpha: .15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: secondNebula, radius: nebulaR)),
    );

    const tints = [
      Color(0xFFFFFFFF),
      Color(0xFFBFE8FF),
      Color(0xFFFFF0C2),
      Color(0xFFFFD6E4),
    ];
    for (final (sx, sy, sr, sp, ti) in _stars) {
      final wave =
          .46 + .54 * (.5 + .5 * math.sin((phase * sp + sx) * math.pi * 2));
      canvas.drawCircle(
        Offset(sx * size.width, sy * size.height),
        sr,
        Paint()..color = tints[ti].withValues(alpha: wave * .82),
      );
    }

    for (final (kx, ky, kr, kp) in _sparkles) {
      final pulse = .74 + .26 * math.sin((phase + kp) * math.pi * 2);
      _drawChibiStar(
        canvas,
        Offset(kx * size.width, ky * size.height),
        kr * pulse,
        const Color(0xFFFFF5CC).withValues(alpha: .78 * pulse),
      );
    }
  }

  void _drawChibiStar(Canvas canvas, Offset c, double r, Color color) {
    final inner = r * .28;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + inner, c.dy - inner, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + inner, c.dy + inner, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - inner, c.dy + inner, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - inner, c.dy - inner, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CosmicSpacePainter old) =>
      old.phase != phase || old.wide != wide;
}

class _ProjPt {
  const _ProjPt(this.x, this.y, this.z);
  final double x, y, z;
}

class _GlobeMotion extends ChangeNotifier {
  static const double initialLonDeg = 114.0;
  static const double baseDegPerSec = -5.0;

  double elapsedSec = 0;
  double centerLonDeg = initialLonDeg;
  double dragVelocityDeg = 0;
  bool dragging = false;
  bool reduced = false;
  int? tappedPinIndex;
  double tappedAtSec = -10;

  void tick(double dt) {
    elapsedSec += dt;
    if (!dragging) {
      dragVelocityDeg *= math.exp(-dt * 3.4);
      final speed = baseDegPerSec + dragVelocityDeg;
      centerLonDeg = (centerLonDeg + speed * dt) % 360.0;
    }
    notifyListeners();
  }

  void dragDelta(double dx) {
    centerLonDeg = (centerLonDeg - dx * 0.42) % 360.0;
    notifyListeners();
  }

  void triggerPinTap(int index) {
    tappedPinIndex = index;
    tappedAtSec = elapsedSec;
    notifyListeners();
  }

  void setReduced(bool value) {
    if (reduced == value) return;
    reduced = value;
    if (value) elapsedSec = 3.0;
  }
}

/// Ilustrasi Globe Bumi 3D bergaya chibi Spots berdasarkan garis pantai asli
/// Natural Earth, berputar mulus dengan titik ilustrasi di seluruh dunia.
class SpotsEarthGlobe extends StatefulWidget {
  const SpotsEarthGlobe({super.key, this.compact = false});
  final bool compact;

  @override
  State<SpotsEarthGlobe> createState() => _SpotsEarthGlobeState();
}

class _SpotsEarthGlobeState extends State<SpotsEarthGlobe>
    with SingleTickerProviderStateMixin {
  static const double _centerLatRad = -4.5 * math.pi / 180.0;
  static const double _tiltRad = 9.5 * math.pi / 180.0;

  late final Ticker _ticker;
  final _GlobeMotion _motion = _GlobeMotion();
  Duration? _lastTick;
  Offset _lastCenter = Offset.zero;
  double _lastRadius = 120.0;

  static final List<List<(double, double, double)>> _unitRings = [
    for (final ring in earthLandRings)
      [
        for (var i = 0; i < ring.length; i += 2)
          _toUnit3D(ring[i] * .1, ring[i + 1] * .1),
      ],
  ];

  static final List<(double, double, double)> _spotUnits = [
    for (final s in kGlobeSpots) _toUnit3D(s.lat, s.lon),
  ];

  static (double, double, double) _toUnit3D(double latDeg, double lonDeg) {
    final phi = latDeg * math.pi / 180.0;
    final lam = lonDeg * math.pi / 180.0;
    final cp = math.cos(phi);
    return (cp * math.sin(lam), math.sin(phi), cp * math.cos(lam));
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCalm = calm(context);
    _motion.setReduced(isCalm);
    if (isCalm || !TickerMode.valuesOf(context).enabled) {
      if (_ticker.isActive) _ticker.stop();
      _lastTick = null;
    } else if (!_ticker.isActive) {
      _lastTick = null;
      _ticker.start();
    }
  }

  void _onTick(Duration now) {
    final prev = _lastTick;
    _lastTick = now;
    if (prev == null) return;
    final dt = ((now - prev).inMicroseconds / 1e6).clamp(0.0, 0.06);
    _motion.tick(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _motion.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPos) {
    final lonRad = _motion.centerLonDeg * math.pi / 180.0;
    final cl = math.cos(lonRad), sl = math.sin(lonRad);
    final cp = math.cos(_centerLatRad), sp = math.sin(_centerLatRad);
    final ct = math.cos(_tiltRad), st = math.sin(_tiltRad);

    int? nearest;
    var bestDist = 34.0;
    for (var i = 0; i < _spotUnits.length; i++) {
      final (ux, uy, uz) = _spotUnits[i];
      final x1 = ux * cl - uz * sl;
      final z1 = ux * sl + uz * cl;
      final y2 = uy * cp - z1 * sp;
      final z2 = uy * sp + z1 * cp;
      if (z2 <= 0.16) continue;
      final x = x1 * ct - y2 * st;
      final y = x1 * st + y2 * ct;
      final pinCenter = Offset(
        _lastCenter.dx + x * _lastRadius,
        _lastCenter.dy - y * _lastRadius - 12,
      );
      final d = (pinCenter - localPos).distance;
      if (d < bestDist) {
        bestDist = d;
        nearest = i;
      }
    }
    if (nearest != null) {
      _motion.triggerPinTap(nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final shortest = math.min(w, h);
        final radius =
            (shortest * (widget.compact ? .37 : .385)).clamp(76.0, 215.0);
        final center = Offset(w * .5, h * .51);
        _lastCenter = center;
        _lastRadius = radius;

        return Semantics(
          label: 'Ilustrasi globe Bumi 3D Spots dengan pin lokasi di seluruh dunia',
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (d) => _handleTap(d.localPosition),
            onHorizontalDragStart: (_) => _motion.dragging = true,
            onHorizontalDragUpdate: (d) => _motion.dragDelta(d.delta.dx),
            onHorizontalDragEnd: (d) {
              _motion.dragging = false;
              _motion.dragVelocityDeg =
                  (-d.velocity.pixelsPerSecond.dx * 0.08).clamp(-95.0, 95.0);
            },
            onHorizontalDragCancel: () => _motion.dragging = false,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(w, h),
                painter: _ChibiEarthPainter(
                  motion: _motion,
                  unitRings: _unitRings,
                  spotUnits: _spotUnits,
                  center: center,
                  radius: radius,
                  centerLatRad: _centerLatRad,
                  tiltRad: _tiltRad,
                  reduced: _motion.reduced,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PinDrawItem {
  const _PinDrawItem({
    required this.index,
    required this.spot,
    required this.category,
    required this.x,
    required this.y,
    required this.z,
  });

  final int index;
  final GlobeSpotPin spot;
  final SpotCategory category;
  final double x, y, z;
}

class _ChibiEarthPainter extends CustomPainter {
  _ChibiEarthPainter({
    required this.motion,
    required this.unitRings,
    required this.spotUnits,
    required this.center,
    required this.radius,
    required this.centerLatRad,
    required this.tiltRad,
    required this.reduced,
  }) : super(repaint: motion);

  final _GlobeMotion motion;
  final List<List<(double, double, double)>> unitRings;
  final List<(double, double, double)> spotUnits;
  final Offset center;
  final double radius, centerLatRad, tiltRad;
  final bool reduced;

  static const _clouds = <(double lat, double lon, double scale)>[
    (8.0, 106.0, 1.0),
    (-14.0, 128.0, .86),
    (24.0, 142.0, .92),
    (-6.0, 74.0, .88),
    (34.0, 18.0, .95),
    (-22.0, -14.0, .84),
    (18.0, -68.0, .96),
    (-26.0, -118.0, .88),
  ];

  static final Path _unitCloudPath = _buildUnitCloudPath();

  static Path _buildUnitCloudPath() {
    var puff = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 11.5));
    for (final part in [
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(-10.0, 2.5), radius: 8.5)),
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(10.5, 2.0), radius: 9.0)),
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: const Offset(0.0, 5.5),
              width: 34.0,
              height: 10.0,
            ),
            const Radius.circular(5.0),
          ),
        ),
    ]) {
      puff = Path.combine(PathOperation.union, puff, part);
    }
    return puff;
  }

  /// Animasi mendarat satu kali saat awal tampil atau saat pin diketuk,
  /// lalu tetap tenang tanpa menghilang/berkedip ulang.
  (double lift, double scaleX, double scaleY, double opacity, double ripple)
  _dropMotion(double ageSec, bool reduced) {
    if (reduced || ageSec >= 1.05) {
      return (0.0, 1.0, 1.0, 1.0, 0.0);
    }
    if (ageSec < 0) {
      return (36.0, .90, 1.06, 0.0, 0.0);
    }
    final u = (ageSec / 1.05).clamp(0.0, 1.0);
    final opacity = (u / 0.22).clamp(0.0, 1.0);
    if (u < 0.44) {
      final k = u / 0.44;
      final fall = 1.0 - Curves.easeInQuad.transform(k);
      return (
        36.0 * fall,
        .92 + .08 * (1 - fall),
        1.08 - .08 * (1 - fall),
        opacity,
        0.0,
      );
    }
    if (u < 0.62) {
      final k = (u - 0.44) / 0.18;
      final s = math.sin(k * math.pi);
      return (0.0, 1.0 + .20 * s, 1.0 - .18 * s, 1.0, k * .45);
    }
    if (u < 0.84) {
      final k = (u - 0.62) / 0.22;
      final hop = math.sin(k * math.pi);
      return (8.0 * hop, 1.0 - .05 * hop, 1.0 + .07 * hop, 1.0, .45 + k * .40);
    }
    final k = (u - 0.84) / 0.16;
    final settle = math.sin(k * math.pi) * .035;
    return (0.0, 1.0 + settle, 1.0 - settle, 1.0, .85 + k * .15);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lonRad = motion.centerLonDeg * math.pi / 180.0;
    final elapsed = motion.elapsedSec;
    final cloudShiftRad = reduced ? .4 : elapsed * 0.11;
    final orbitPhase = reduced ? .2 : (elapsed * 0.09) % 1.0;

    final sphereRect = Rect.fromCircle(center: center, radius: radius);
    final globeClip = Path()..addOval(sphereRect);

    // 1. Busur lintasan orbit bagian belakang
    _drawOrbitArc(canvas, orbitPhase, front: false);

    // 2. Pendaran atmosfer luar
    final atmoRadius = radius * 1.22;
    canvas.drawCircle(
      center,
      atmoRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF4CE6DF).withValues(alpha: .32),
            const Color(0xFF3A80FF).withValues(alpha: .20),
            Colors.transparent,
          ],
          stops: const [.68, .84, 1],
        ).createShader(Rect.fromCircle(center: center, radius: atmoRadius)),
    );

    // 3. Permukaan samudra 3D
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.38, -.42),
          radius: 1.18,
          colors: [
            Color(0xFF6BE0FF),
            Color(0xFF2F8BF8),
            Color(0xFF1950C4),
            Color(0xFF0C246B),
          ],
          stops: [0, .34, .74, 1],
        ).createShader(sphereRect),
    );

    canvas.save();
    canvas.clipPath(globeClip);

    // 4. Garis lintang & bujur
    _drawGraticule(canvas, lonRad);

    // 5. Daratan Natural Earth
    final landPath = _buildVisibleLandPath(lonRad);

    canvas.drawPath(
      landPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (radius * .048).clamp(4.0, 10.0)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF53EFE2).withValues(alpha: .36),
    );

    canvas.save();
    canvas.translate(0, (radius * .016).clamp(1.5, 3.6));
    canvas.drawPath(landPath, Paint()..color = const Color(0xFF13684B));
    canvas.drawPath(
      landPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (radius * .013).clamp(1.2, 2.8)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF13684B),
    );
    canvas.restore();

    final landShader = const RadialGradient(
      center: Alignment(-.42, -.46),
      radius: 1.25,
      colors: [
        Color(0xFFA2F280),
        Color(0xFF43CE88),
        Color(0xFF239B73),
        Color(0xFF166955),
      ],
      stops: [0, .38, .76, 1],
    ).createShader(sphereRect);

    canvas.drawPath(landPath, Paint()..shader = landShader);
    canvas.drawPath(
      landPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (radius * .012).clamp(1.1, 2.5)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = landShader,
    );

    canvas.save();
    canvas.clipPath(landPath);
    canvas.drawCircle(
      Offset(center.dx - radius * .32, center.dy - radius * .34),
      radius * .88,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFE9FFC4).withValues(alpha: .34),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(center.dx - radius * .32, center.dy - radius * .34),
            radius: radius * .88,
          ),
        ),
    );
    canvas.restore();

    // 6. Awan gembul chibi (memakai path terprekomputasi agar mulus)
    _drawChibiClouds(canvas, lonRad, cloudShiftRad);

    // 7. Bayangan malam lembut & kilau kapsul kaca
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.40, -.40),
          radius: 1.04,
          colors: [
            Colors.transparent,
            Colors.transparent,
            const Color(0xFF071544).withValues(alpha: .44),
          ],
          stops: const [0, .64, 1],
        ).createShader(sphereRect),
    );

    canvas.save();
    canvas.translate(center.dx - radius * .44, center.dy - radius * .46);
    canvas.rotate(-.64);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * .42,
        height: radius * .16,
      ),
      Paint()..color = Colors.white.withValues(alpha: .28),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * .14, radius * .14),
        width: radius * .11,
        height: radius * .06,
      ),
      Paint()..color = Colors.white.withValues(alpha: .22),
    );
    canvas.restore();

    canvas.restore(); // lepas globeClip

    // Cincin atmosfer tipis
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC9AF6FF), Color(0x444B8BFF), Color(0x8838D8FF)],
        ).createShader(sphereRect),
    );

    // 8. Pin ilustrasi di seluruh dunia (digambar sinkron di Canvas -> bebas kedip)
    final cl = math.cos(lonRad), sl = math.sin(lonRad);
    final cp = math.cos(centerLatRad), sp = math.sin(centerLatRad);
    final ct = math.cos(tiltRad), st = math.sin(tiltRad);

    final visible = <_PinDrawItem>[];
    for (var i = 0; i < spotUnits.length; i++) {
      final (ux, uy, uz) = spotUnits[i];
      final x1 = ux * cl - uz * sl;
      final z1 = ux * sl + uz * cl;
      final y2 = uy * cp - z1 * sp;
      final z2 = uy * sp + z1 * cp;
      if (z2 <= 0.10) continue;
      final x = x1 * ct - y2 * st;
      final y = x1 * st + y2 * ct;
      visible.add(
        _PinDrawItem(
          index: i,
          spot: kGlobeSpots[i],
          category: categoryOf(kGlobeSpots[i].categoryKey),
          x: x,
          y: y,
          z: z2,
        ),
      );
    }
    visible.sort((a, b) => a.z.compareTo(b.z));

    final labelItems =
        <(Offset anchor, Color color, String label, double alpha)>[];

    for (final v in visible) {
      final pos = Offset(center.dx + v.x * radius, center.dy - v.y * radius);
      // Pudar halus saat mendekati horizon agar tidak pernah mendadak muncul/hilang
      final hzRaw = ((v.z - 0.10) / 0.24).clamp(0.0, 1.0);
      final horizonFade = hzRaw * hzRaw * (3.0 - 2.0 * hzRaw);

      final isTapped =
          motion.tappedPinIndex == v.index &&
          (elapsed - motion.tappedAtSec) < 1.15;
      final age = isTapped
          ? (elapsed - motion.tappedAtSec)
          : elapsed - (v.index % 6) * 0.10;
      final (lift, sx, sy, dropOp, ripple) = _dropMotion(age, reduced);
      final alpha = (horizonFade * dropOp).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      if (ripple > 0 && ripple < 1) {
        final rr = (6.0 + ripple * 20.0) * (radius / 160.0).clamp(.7, 1.2);
        final ra = ((1.0 - ripple) * horizonFade).clamp(0.0, 1.0);
        canvas.drawCircle(
          pos,
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = Colors.white.withValues(alpha: ra * .85),
        );
        canvas.drawCircle(
          pos,
          rr * .65,
          Paint()..color = v.category.color.withValues(alpha: ra * .32),
        );
      }

      final bob =
          reduced ? 0.0 : math.sin(elapsed * 2.0 + v.index * 1.15) * 1.4;
      final depthScale = (.76 + .24 * v.z).clamp(.76, 1.0);
      final pinSize = (radius * .19).clamp(22.0, 33.0) * depthScale;
      final pinAnchor = Offset(pos.dx, pos.dy - lift + bob);
      _drawChibiPin(
        canvas: canvas,
        anchor: pinAnchor,
        size: pinSize,
        color: v.category.color,
        categoryKey: v.spot.categoryKey,
        sx: sx,
        sy: sy,
        alpha: alpha,
      );

      if (v.z > 0.20 && alpha > 0.15) {
        labelItems.add((pinAnchor, v.category.color, v.spot.city, alpha));
      }
    }

    // 9. Busur lintasan orbit bagian depan
    _drawOrbitArc(canvas, orbitPhase, front: true);

    // 10. Label nama lokasi pada pin (sinkron di Canvas, hindari tabrakan teks)
    _drawPinLabels(canvas, size, labelItems);
  }

  void _drawPinLabels(
    Canvas canvas,
    Size size,
    List<(Offset anchor, Color color, String label, double alpha)> items,
  ) {
    if (items.isEmpty) return;
    final fontSize = (radius * .066).clamp(9.5, 11.5);
    final placed = <Rect>[];
    // Prioritaskan pin yang paling depan (urutan belakang -> depan ada di list, jadi balik)
    for (final item in items.reversed) {
      final (anchor, color, label, alpha) = item;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            color: ink.withValues(alpha: alpha),
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      const dotSize = 6.0;
      const padH = 7.0;
      const padV = 3.5;
      const gap = 5.0;
      final pillW = padH + dotSize + gap + tp.width + padH;
      final pillH = math.max(tp.height, dotSize) + padV * 2;
      final left = (anchor.dx - pillW * .5).clamp(4.0, math.max(4.0, size.width - pillW - 4.0));
      final top = (anchor.dy + 3.0).clamp(4.0, math.max(4.0, size.height - pillH - 4.0));
      final rect = Rect.fromLTWH(left, top, pillW, pillH);

      if (placed.any((r) => r.overlaps(rect.inflate(3.0)))) continue;
      placed.add(rect);

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(99));
      canvas.drawRRect(
        rrect.shift(const Offset(0, 2)),
        Paint()..color = const Color(0xFF040A1C).withValues(alpha: .28 * alpha),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = Colors.white.withValues(alpha: .92 * alpha),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: .96 * alpha),
      );
      canvas.drawCircle(
        Offset(left + padH + dotSize * .5, top + pillH * .5),
        dotSize * .5,
        Paint()..color = color.withValues(alpha: alpha),
      );
      tp.paint(
        canvas,
        Offset(left + padH + dotSize + gap, top + (pillH - tp.height) * .5),
      );
    }
  }

  void _drawChibiPin({
    required Canvas canvas,
    required Offset anchor,
    required double size,
    required Color color,
    required String categoryKey,
    required double sx,
    required double sy,
    required double alpha,
  }) {
    final h = size * 1.16;
    final r = size * .46;
    final cy = -h + size * .48;

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(sx, sy);

    // Bayangan lembut di permukaan bumi
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -1.0), width: size * .42, height: 4.0),
      Paint()..color = const Color(0xFF06102E).withValues(alpha: .32 * alpha),
    );

    final pin = Path()
      ..moveTo(0, -1.5)
      ..quadraticBezierTo(-r * .92, cy + r * .52, -r, cy)
      ..arcToPoint(
        Offset(r, cy),
        radius: Radius.circular(r),
        largeArc: true,
      )
      ..quadraticBezierTo(r * .92, cy + r * .52, 0, -1.5)
      ..close();

    final light = Color.lerp(color, Colors.white, .28)!.withValues(alpha: alpha);
    final mid = color.withValues(alpha: alpha);
    final dark = Color.lerp(color, const Color(0xFF0E183B), .24)!.withValues(alpha: alpha);
    canvas.drawPath(
      pin,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, mid, dark],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromLTWH(-r, -h, r * 2, h)),
    );

    canvas.drawPath(
      pin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size * .068).clamp(1.5, 2.2)
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: .94 * alpha),
    );

    // Kilau kapsul kecil di kiri atas pin
    canvas.save();
    canvas.translate(-r * .36, cy - r * .36);
    canvas.rotate(-.48);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * .42, height: r * .20),
      Paint()..color = Colors.white.withValues(alpha: .42 * alpha),
    );
    canvas.restore();

    // Simbol kategori sederhana di tengah pin (sinkron di Canvas)
    _drawCategorySymbol(canvas, Offset(0, cy), r * .48, categoryKey, alpha);

    canvas.restore();
  }

  void _drawCategorySymbol(
    Canvas canvas,
    Offset c,
    double sr,
    String key,
    double alpha,
  ) {
    final whiteStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (sr * .28).clamp(1.3, 2.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: .96 * alpha);
    final whiteFill = Paint()
      ..color = Colors.white.withValues(alpha: .96 * alpha);

    switch (key) {
      case 'kuliner':
        // Mangkuk sederhana
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(0, sr * .05), width: sr * 1.6, height: sr * 1.4),
          0,
          math.pi,
          true,
          whiteFill,
        );
        canvas.drawLine(
          c.translate(-sr * .85, sr * .05),
          c.translate(sr * .85, sr * .05),
          whiteStroke,
        );
      case 'kafe':
        // Cangkir kopi
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromCenter(center: c.translate(-sr * .06, sr * .12), width: sr * 1.15, height: sr * 1.1),
            bottomLeft: Radius.circular(sr * .45),
            bottomRight: Radius.circular(sr * .45),
          ),
          whiteFill,
        );
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(sr * .62, sr * .08), width: sr * .55, height: sr * .55),
          -math.pi / 2,
          math.pi,
          false,
          whiteStroke,
        );
      case 'destinasi':
        // Puncak gunung
        final m = Path()
          ..moveTo(c.dx - sr * .85, c.dy + sr * .62)
          ..lineTo(c.dx - sr * .15, c.dy - sr * .55)
          ..lineTo(c.dx + sr * .25, c.dy + sr * .15)
          ..lineTo(c.dx + sr * .50, c.dy - sr * .18)
          ..lineTo(c.dx + sr * .90, c.dy + sr * .62)
          ..close();
        canvas.drawPath(m, whiteFill);
      case 'olahraga':
        // Bola / cincin olahraga
        canvas.drawCircle(c, sr * .78, whiteStroke);
        canvas.drawCircle(c, sr * .24, whiteFill);
      case 'belanja':
        // Tas belanja
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c.translate(0, sr * .18), width: sr * 1.25, height: sr * 1.1),
            Radius.circular(sr * .22),
          ),
          whiteFill,
        );
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(0, -sr * .35), width: sr * .72, height: sr * .65),
          math.pi,
          math.pi,
          false,
          whiteStroke,
        );
      case 'menginap':
        // Rumah kecil
        final h = Path()
          ..moveTo(c.dx - sr * .78, c.dy - sr * .05)
          ..lineTo(c.dx, c.dy - sr * .78)
          ..lineTo(c.dx + sr * .78, c.dy - sr * .05)
          ..lineTo(c.dx + sr * .56, c.dy - sr * .05)
          ..lineTo(c.dx + sr * .56, c.dy + sr * .68)
          ..lineTo(c.dx - sr * .56, c.dy + sr * .68)
          ..lineTo(c.dx - sr * .56, c.dy - sr * .05)
          ..close();
        canvas.drawPath(h, whiteFill);
      default:
        // Bintang/aktivitas (4 sudut)
        final star = Path()
          ..moveTo(c.dx, c.dy - sr * .88)
          ..quadraticBezierTo(c.dx + sr * .22, c.dy - sr * .22, c.dx + sr * .88, c.dy)
          ..quadraticBezierTo(c.dx + sr * .22, c.dy + sr * .22, c.dx, c.dy + sr * .88)
          ..quadraticBezierTo(c.dx - sr * .22, c.dy + sr * .22, c.dx - sr * .88, c.dy)
          ..quadraticBezierTo(c.dx - sr * .22, c.dy - sr * .22, c.dx, c.dy - sr * .88)
          ..close();
        canvas.drawPath(star, whiteFill);
    }
  }

  void _drawOrbitArc(Canvas canvas, double orbitPhase, {required bool front}) {
    final rx = radius * 1.28;
    final ry = radius * .36;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.28);
    final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    final startAngle = front ? 0.0 : math.pi;
    canvas.drawArc(
      rect,
      startAngle,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF8BE8FF).withValues(alpha: front ? .28 : .14),
    );
    final ang = orbitPhase * math.pi * 2;
    final inFront = math.sin(ang) >= 0;
    if (inFront == front) {
      final ox = math.cos(ang) * rx;
      final oy = math.sin(ang) * ry;
      canvas.drawCircle(
        Offset(ox, oy),
        5.5,
        Paint()..color = const Color(0x557CEBFF),
      );
      canvas.drawCircle(
        Offset(ox, oy),
        2.6,
        Paint()..color = const Color(0xFFFFF6CC),
      );
    }
    canvas.restore();
  }

  void _drawGraticule(Canvas canvas, double lonRad) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: .075);

    final cl = math.cos(lonRad), sl = math.sin(lonRad);
    final cp = math.cos(centerLatRad), sp = math.sin(centerLatRad);
    final ct = math.cos(tiltRad), st = math.sin(tiltRad);

    Offset? proj(double latDeg, double lonDeg) {
      final phi = latDeg * math.pi / 180.0;
      final lam = lonDeg * math.pi / 180.0;
      final cphi = math.cos(phi);
      final ux = cphi * math.sin(lam);
      final uy = math.sin(phi);
      final uz = cphi * math.cos(lam);
      final x1 = ux * cl - uz * sl;
      final z1 = ux * sl + uz * cl;
      final y2 = uy * cp - z1 * sp;
      final z2 = uy * sp + z1 * cp;
      if (z2 < 0) return null;
      final x = x1 * ct - y2 * st;
      final y = x1 * st + y2 * ct;
      return Offset(center.dx + x * radius, center.dy - y * radius);
    }

    for (final lat in const [-45.0, -23.5, 0.0, 23.5, 45.0]) {
      final path = Path();
      var open = false;
      for (var lon = -180.0; lon <= 180.0; lon += 6.0) {
        final p = proj(lat, lon);
        if (p == null) {
          open = false;
        } else if (!open) {
          path.moveTo(p.dx, p.dy);
          open = true;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    for (var lon = -180.0; lon < 180.0; lon += 30.0) {
      final path = Path();
      var open = false;
      for (var lat = -75.0; lat <= 75.0; lat += 6.0) {
        final p = proj(lat, lon);
        if (p == null) {
          open = false;
        } else if (!open) {
          path.moveTo(p.dx, p.dy);
          open = true;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawChibiClouds(Canvas canvas, double lonRad, double cloudShiftRad) {
    final cl = math.cos(lonRad - cloudShiftRad);
    final sl = math.sin(lonRad - cloudShiftRad);
    final cp = math.cos(centerLatRad), sp = math.sin(centerLatRad);
    final ct = math.cos(tiltRad), st = math.sin(tiltRad);

    for (final (latDeg, lonDeg, sc) in _clouds) {
      final phi = latDeg * math.pi / 180.0;
      final lam = lonDeg * math.pi / 180.0;
      final cphi = math.cos(phi);
      final ux = cphi * math.sin(lam);
      final uy = math.sin(phi);
      final uz = cphi * math.cos(lam);

      final x1 = ux * cl - uz * sl;
      final z1 = ux * sl + uz * cl;
      final y2 = uy * cp - z1 * sp;
      final z2 = uy * sp + z1 * cp;
      if (z2 <= 0.14) continue;

      final x = x1 * ct - y2 * st;
      final y = x1 * st + y2 * ct;
      final k = (radius / 165.0) * sc * (.65 + .35 * z2);

      final shadowPos = Offset(
        center.dx + x * radius + 3 * k,
        center.dy - y * radius + 5 * k,
      );
      final cloudPos = Offset(
        center.dx + x * radius * 1.03,
        center.dy - y * radius * 1.03,
      );

      canvas.drawOval(
        Rect.fromCenter(center: shadowPos, width: 38 * k, height: 14 * k),
        Paint()..color = const Color(0x24071642),
      );

      canvas.save();
      canvas.translate(cloudPos.dx, cloudPos.dy);
      canvas.scale(k);
      canvas.drawPath(
        _unitCloudPath,
        Paint()..color = Colors.white.withValues(alpha: (.82 * z2).clamp(.25, .86)),
      );
      canvas.restore();
    }
  }

  Path _buildVisibleLandPath(double lonRad) {
    final total = Path();
    final cl = math.cos(lonRad), sl = math.sin(lonRad);
    final cp = math.cos(centerLatRad), sp = math.sin(centerLatRad);
    final ct = math.cos(tiltRad), st = math.sin(tiltRad);

    for (final ring in unitRings) {
      final n = ring.length;
      if (n < 3) continue;

      var anyFront = false;
      var allFront = true;
      final pts = List<_ProjPt>.filled(n, const _ProjPt(0, 0, 0));

      for (var i = 0; i < n; i++) {
        final (ux, uy, uz) = ring[i];
        final x1 = ux * cl - uz * sl;
        final z1 = ux * sl + uz * cl;
        final y2 = uy * cp - z1 * sp;
        final z2 = uy * sp + z1 * cp;
        final x = x1 * ct - y2 * st;
        final y = x1 * st + y2 * ct;
        pts[i] = _ProjPt(x, y, z2);
        if (z2 > 0) {
          anyFront = true;
        } else {
          allFront = false;
        }
      }

      if (!anyFront) continue;

      if (allFront) {
        _appendSmoothClosedRing(total, [
          for (final p in pts)
            Offset(center.dx + p.x * radius, center.dy - p.y * radius),
        ]);
        continue;
      }

      final chains = <_HorizonChain>[];
      var startIdx = 0;
      for (var i = 0; i < n; i++) {
        if (pts[i].z <= 0) {
          startIdx = i;
          break;
        }
      }

      List<Offset>? current;
      double enterAngle = 0;

      for (var step = 0; step < n; step++) {
        final a = pts[(startIdx + step) % n];
        final b = pts[(startIdx + step + 1) % n];
        final aIn = a.z > 0;
        final bIn = b.z > 0;

        if (!aIn && bIn) {
          final hit = _horizonHit(a, b);
          enterAngle = hit.$3;
          current = [
            Offset(center.dx + hit.$1 * radius, center.dy - hit.$2 * radius),
            Offset(center.dx + b.x * radius, center.dy - b.y * radius),
          ];
        } else if (aIn && bIn) {
          current?.add(Offset(center.dx + b.x * radius, center.dy - b.y * radius));
        } else if (aIn && !bIn) {
          final hit = _horizonHit(a, b);
          if (current != null) {
            current.add(
              Offset(center.dx + hit.$1 * radius, center.dy - hit.$2 * radius),
            );
            chains.add(
              _HorizonChain(
                points: current,
                enterAngle: enterAngle,
                exitAngle: hit.$3,
              ),
            );
            current = null;
          }
        }
      }

      if (chains.isEmpty) continue;

      final visited = List<bool>.filled(chains.length, false);
      for (var i = 0; i < chains.length; i++) {
        if (visited[i]) continue;
        final loopPts = <Offset>[];
        var curr = i;
        var guard = 0;
        while (!visited[curr] && guard < chains.length + 2) {
          visited[curr] = true;
          guard++;
          final ch = chains[curr];
          loopPts.addAll(ch.points);

          var bestNext = i;
          var bestDelta = double.infinity;
          for (var j = 0; j < chains.length; j++) {
            if (visited[j] && j != i) continue;
            var d = (chains[j].enterAngle - ch.exitAngle) % (math.pi * 2);
            if (d < 0) d += math.pi * 2;
            // Izinkan celah balik kecil (< ~9°) agar lekukan pantai di tepi horizon
            // tidak memutar 355° mengelilingi seluruh bola Bumi menjadi hijau penuh.
            if (d > math.pi * 1.95) d -= math.pi * 2;
            final pick = (bestDelta < 0 || d < 0)
                ? d.abs() < bestDelta.abs()
                : d < bestDelta;
            if (pick) {
              bestDelta = d;
              bestNext = j;
            }
          }

          final steps = (bestDelta.abs() / 0.11).ceil().clamp(1, 64);
          for (var s = 1; s < steps; s++) {
            final ang = ch.exitAngle + bestDelta * (s / steps);
            loopPts.add(
              Offset(
                center.dx + math.cos(ang) * radius * 1.004,
                center.dy - math.sin(ang) * radius * 1.004,
              ),
            );
          }
          curr = bestNext;
          if (curr == i) break;
        }

        if (loopPts.length >= 3 && _isValidLoopArea(loopPts)) {
          total.moveTo(loopPts.first.dx, loopPts.first.dy);
          for (var k = 1; k < loopPts.length; k++) {
            total.lineTo(loopPts[k].dx, loopPts[k].dy);
          }
          total.close();
        }
      }
    }
    return total;
  }

  bool _isValidLoopArea(List<Offset> pts) {
    var s = 0.0;
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % n];
      final x1 = a.dx - center.dx;
      final y1 = center.dy - a.dy;
      final x2 = b.dx - center.dx;
      final y2 = center.dy - b.dy;
      s += x1 * y2 - x2 * y1;
    }
    final normArea = (0.5 * s) / (radius * radius);
    return normArea > -0.05 && normArea < 2.2;
  }

  (double, double, double) _horizonHit(_ProjPt a, _ProjPt b) {
    final denom = a.z - b.z;
    final t = denom.abs() < 1e-9 ? 0.5 : (a.z / denom).clamp(0.0, 1.0);
    var hx = a.x + (b.x - a.x) * t;
    var hy = a.y + (b.y - a.y) * t;
    final len = math.sqrt(hx * hx + hy * hy);
    if (len > 1e-9) {
      hx /= len;
      hy /= len;
    } else {
      hx = 1.0;
      hy = 0.0;
    }
    var ang = math.atan2(hy, hx);
    if (ang < 0) ang += math.pi * 2;
    return (hx, hy, ang);
  }

  void _appendSmoothClosedRing(Path path, List<Offset> pts) {
    final n = pts.length;
    if (n < 3) return;
    final start = Offset(
      (pts[n - 1].dx + pts[0].dx) * .5,
      (pts[n - 1].dy + pts[0].dy) * .5,
    );
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final curr = pts[i];
      final next = pts[(i + 1) % n];
      final mid = Offset((curr.dx + next.dx) * .5, (curr.dy + next.dy) * .5);
      path.quadraticBezierTo(curr.dx, curr.dy, mid.dx, mid.dy);
    }
    path.close();
  }

  @override
  bool shouldRepaint(_ChibiEarthPainter old) =>
      old.radius != radius ||
      old.center != center ||
      old.reduced != reduced ||
      !identical(old.motion, motion);
}

class _HorizonChain {
  const _HorizonChain({
    required this.points,
    required this.enterAngle,
    required this.exitAngle,
  });

  final List<Offset> points;
  final double enterAngle, exitAngle;
}
