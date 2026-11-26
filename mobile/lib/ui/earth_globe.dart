import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'earth_geo.dart';
import 'motion.dart';
import 'spot_icons.dart';
import 'theme.dart';
import 'widgets.dart';

/// Data titik lokasi nyata di permukaan Bumi untuk ditampilkan pada globe 3D.
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

/// Daftar spot nyata di Indonesia (sesuai data Spots) dan kota dunia pada
/// koordinat lintang-bujur asli di daratan Natural Earth.
const List<GlobeSpotPin> kGlobeSpots = [
  // Klaster utama Indonesia — menampilkan seluruh 7 kategori & ikon asli Spots
  GlobeSpotPin(
    title: 'Rawon Setan',
    city: 'Surabaya',
    categoryKey: 'kuliner',
    lat: -7.26,
    lon: 112.74,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Kopi Teras Hujan',
    city: 'Bandung',
    categoryKey: 'kafe',
    lat: -6.89,
    lon: 107.61,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Pantai Batu Nona',
    city: 'Lombok',
    categoryKey: 'destinasi',
    lat: -8.55,
    lon: 116.30,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Rumah Seduh Pojok',
    city: 'Jakarta',
    categoryKey: 'kafe',
    lat: -6.26,
    lon: 106.81,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Workshop Gerabah',
    city: 'Yogyakarta',
    categoryKey: 'aktivitas',
    lat: -7.79,
    lon: 110.36,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Pasar Terapung',
    city: 'Banjarmasin',
    categoryKey: 'belanja',
    lat: -3.32,
    lon: 114.59,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Lari Sore Losari',
    city: 'Makassar',
    categoryKey: 'olahraga',
    lat: -5.14,
    lon: 119.41,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Bukit Cinta',
    city: 'Labuan Bajo',
    categoryKey: 'destinasi',
    lat: -8.49,
    lon: 119.89,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Danau Toba',
    city: 'Sumatera',
    categoryKey: 'destinasi',
    lat: 2.68,
    lon: 98.88,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Sate Padang Ajo',
    city: 'Padang',
    categoryKey: 'kuliner',
    lat: -0.95,
    lon: 100.36,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Kopi Rempah',
    city: 'Maluku',
    categoryKey: 'kafe',
    lat: 0.80,
    lon: 127.85,
    indonesia: true,
  ),
  GlobeSpotPin(
    title: 'Homestay Teluk',
    city: 'Papua',
    categoryKey: 'menginap',
    lat: -1.80,
    lon: 134.10,
    indonesia: true,
  ),
  // Titik spot di benua lain supaya globe 360 derajat selalu hidup saat berputar
  GlobeSpotPin(
    title: 'Kopitiam Sudut',
    city: 'Singapura',
    categoryKey: 'kafe',
    lat: 1.35,
    lon: 103.82,
  ),
  GlobeSpotPin(
    title: 'Pasar Malam',
    city: 'Bangkok',
    categoryKey: 'belanja',
    lat: 13.75,
    lon: 100.50,
  ),
  GlobeSpotPin(
    title: 'Kedai Ramen Gang',
    city: 'Tokyo',
    categoryKey: 'kuliner',
    lat: 35.68,
    lon: 139.69,
  ),
  GlobeSpotPin(
    title: 'Kafe Atap',
    city: 'Seoul',
    categoryKey: 'kafe',
    lat: 37.56,
    lon: 126.98,
  ),
  GlobeSpotPin(
    title: 'Pantai Pagi',
    city: 'Sydney',
    categoryKey: 'olahraga',
    lat: -33.87,
    lon: 151.21,
  ),
  GlobeSpotPin(
    title: 'Taman Kota',
    city: 'Melbourne',
    categoryKey: 'kafe',
    lat: -37.81,
    lon: 144.96,
  ),
  GlobeSpotPin(
    title: 'Bukit Hijau',
    city: 'Auckland',
    categoryKey: 'destinasi',
    lat: -36.85,
    lon: 174.76,
  ),
  GlobeSpotPin(
    title: 'Chai Sudut Kota',
    city: 'Mumbai',
    categoryKey: 'kuliner',
    lat: 19.08,
    lon: 72.88,
  ),
  GlobeSpotPin(
    title: 'Pasar Rempah',
    city: 'Istanbul',
    categoryKey: 'belanja',
    lat: 41.01,
    lon: 28.98,
  ),
  GlobeSpotPin(
    title: 'Gelato Alun-Alun',
    city: 'Roma',
    categoryKey: 'kuliner',
    lat: 41.90,
    lon: 12.50,
  ),
  GlobeSpotPin(
    title: 'Toko Roti Pagi',
    city: 'Paris',
    categoryKey: 'belanja',
    lat: 48.86,
    lon: 2.35,
  ),
  GlobeSpotPin(
    title: 'Taman Sungai',
    city: 'London',
    categoryKey: 'aktivitas',
    lat: 51.51,
    lon: -0.13,
  ),
  GlobeSpotPin(
    title: 'Bazar Tua',
    city: 'Kairo',
    categoryKey: 'aktivitas',
    lat: 30.04,
    lon: 31.24,
  ),
  GlobeSpotPin(
    title: 'Kopi Savana',
    city: 'Nairobi',
    categoryKey: 'kafe',
    lat: -1.29,
    lon: 36.82,
  ),
  GlobeSpotPin(
    title: 'Dermaga Senja',
    city: 'Cape Town',
    categoryKey: 'destinasi',
    lat: -33.92,
    lon: 18.42,
  ),
  GlobeSpotPin(
    title: 'Lapangan Taman',
    city: 'New York',
    categoryKey: 'olahraga',
    lat: 40.71,
    lon: -74.01,
  ),
  GlobeSpotPin(
    title: 'Kopi Bukit',
    city: 'San Francisco',
    categoryKey: 'kafe',
    lat: 37.77,
    lon: -122.42,
  ),
  GlobeSpotPin(
    title: 'Jajanan Alun-Alun',
    city: 'Mexico City',
    categoryKey: 'kuliner',
    lat: 19.43,
    lon: -99.13,
  ),
  GlobeSpotPin(
    title: 'Pantai Lari',
    city: 'Rio',
    categoryKey: 'olahraga',
    lat: -22.91,
    lon: -43.17,
  ),
  GlobeSpotPin(
    title: 'Penginapan Kota Tua',
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

  static final List<(double x, double y, double r, double speed, int tint)>
  _stars = () {
    final rng = math.Random(4207);
    return List.generate(58, (i) {
      return (
        rng.nextDouble(),
        rng.nextDouble(),
        .9 + rng.nextDouble() * 1.9,
        .5 + rng.nextDouble() * 1.5,
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
    // Gradasi angkasa luar beludru
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

    // Pendaran nebula lembut tepat di belakang panggung globe 3D
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

    // Bintang-bintang kecil berkelip halus
    const tints = [
      Color(0xFFFFFFFF),
      Color(0xFFBFE8FF),
      Color(0xFFFFF0C2),
      Color(0xFFFFD6E4),
    ];
    for (final (sx, sy, sr, sp, ti) in _stars) {
      final wave = .42 + .58 * (.5 + .5 * math.sin((phase * sp + sx) * math.pi * 2));
      canvas.drawCircle(
        Offset(sx * size.width, sy * size.height),
        sr,
        Paint()..color = tints[ti].withValues(alpha: wave * .82),
      );
    }

    // Bintang kilau empat sudut bergaya chibi
    for (final ( kx, ky, kr, kp) in _sparkles) {
      final pulse = .72 + .28 * math.sin((phase + kp) * math.pi * 2);
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

/// Proyeksi titik 3D satuan untuk globe ortografis.
class _ProjPt {
  const _ProjPt(this.x, this.y, this.z);
  final double x, y, z;
}

class _ActivePinView {
  const _ActivePinView({
    required this.index,
    required this.spot,
    required this.category,
    required this.x,
    required this.y,
    required this.z,
    required this.dropProgress,
  });

  final int index;
  final GlobeSpotPin spot;
  final SpotCategory category;
  final double x, y, z, dropProgress;
}

/// Ilustrasi Globe Bumi 3D bergaya chibi Spots berdasarkan garis pantai asli
/// Natural Earth, berputar perlahan dengan animasi pin jatuh dan tempat Spots.
class SpotsEarthGlobe extends StatefulWidget {
  const SpotsEarthGlobe({super.key, this.compact = false});
  final bool compact;

  @override
  State<SpotsEarthGlobe> createState() => _SpotsEarthGlobeState();
}

class _SpotsEarthGlobeState extends State<SpotsEarthGlobe>
    with SingleTickerProviderStateMixin {
  // Mulai tepat menghadap kepulauan Indonesia & Asia-Pasifik.
  static const double _initialLonDeg = 114.0;
  static const double _centerLatRad = -4.5 * math.pi / 180.0;
  static const double _tiltRad = 9.5 * math.pi / 180.0;
  // Kecepatan putar prograde (barat ke timur): ~72 detik per putaran penuh.
  static const double _baseDegPerSec = -5.0;

  late final Ticker _ticker;
  Duration? _lastTick;
  double _elapsedSec = 0;
  double _centerLonDeg = _initialLonDeg;
  double _dragVelocityDeg = 0;
  bool _dragging = false;
  int? _tappedPinIndex;
  double _tappedAtSec = -10;

  // Catat kapan tiap pin masuk ke belahan depan supaya langsung jatuh membal.
  final Map<int, double> _pinSpawnSec = {};

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
    // Jadwalkan hujan pin awal secara bertahap pada detik 0..1.1
    for (var i = 0; i < kGlobeSpots.length; i++) {
      _pinSpawnSec[i] = (i % 8) * 0.13;
    }
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context) || !TickerMode.valuesOf(context).enabled) {
      if (_ticker.isActive) _ticker.stop();
      _lastTick = null;
      _elapsedSec = 3.0;
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
    setState(() {
      _elapsedSec += dt;
      if (!_dragging) {
        // Peluruhan kecepatan geser (Apple velocity handoff) kembali ke rotasi lambat
        _dragVelocityDeg *= math.exp(-dt * 3.4);
        final speed = _baseDegPerSec + _dragVelocityDeg;
        _centerLonDeg = (_centerLonDeg + speed * dt) % 360.0;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  _ProjPt _project((double, double, double) u, double lonRad) {
    final (ux, uy, uz) = u;
    final cl = math.cos(lonRad), sl = math.sin(lonRad);
    final cp = math.cos(_centerLatRad), sp = math.sin(_centerLatRad);
    final ct = math.cos(_tiltRad), st = math.sin(_tiltRad);

    final x1 = ux * cl - uz * sl;
    final y1 = uy;
    final z1 = ux * sl + uz * cl;

    final x2 = x1;
    final y2 = y1 * cp - z1 * sp;
    final z2 = y1 * sp + z1 * cp;

    final x = x2 * ct - y2 * st;
    final y = x2 * st + y2 * ct;
    return _ProjPt(x, y, z2);
  }

  /// Kurva jatuh fisik bergaya chibi: meluncur dari atas -> mendarat kenyal -> membal halus.
  (double lift, double scaleX, double scaleY, double opacity, double ripple)
  _dropMotion(double ageSec, bool reduced) {
    if (reduced || ageSec >= 1.05) {
      return (0.0, 1.0, 1.0, 1.0, 0.0);
    }
    if (ageSec < 0) {
      return (44.0, .86, 1.08, 0.0, 0.0);
    }
    final u = (ageSec / 1.05).clamp(0.0, 1.0);
    final opacity = (u / 0.18).clamp(0.0, 1.0);
    if (u < 0.44) {
      // Fase meluncur turun ke koordinat kota
      final k = u / 0.44;
      final fall = 1.0 - Curves.easeInQuad.transform(k);
      return (42.0 * fall, .92 + .08 * (1 - fall), 1.08 - .08 * (1 - fall), opacity, 0.0);
    }
    if (u < 0.62) {
      // Mendarat empuk (squash) + gelombang cincin di tanah
      final k = (u - 0.44) / 0.18;
      final s = math.sin(k * math.pi);
      return (0.0, 1.0 + .22 * s, 1.0 - .20 * s, 1.0, k * .45);
    }
    if (u < 0.84) {
      // Membal ringan ke atas (follow-through)
      final k = (u - 0.62) / 0.22;
      final hop = math.sin(k * math.pi);
      return (9.0 * hop, 1.0 - .06 * hop, 1.0 + .08 * hop, 1.0, .45 + k * .40);
    }
    final k = (u - 0.84) / 0.16;
    final settle = math.sin(k * math.pi) * .04;
    return (0.0, 1.0 + settle, 1.0 - settle, 1.0, .85 + k * .15);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = calm(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final shortest = math.min(w, h);
        // Ukuran bola proporsional dengan ruang kosong di sekeliling untuk label & orbit
        final radius = (shortest * (widget.compact ? .37 : .385)).clamp(76.0, 215.0);
        final center = Offset(w * .5, h * .51);
        final lonRad = _centerLonDeg * math.pi / 180.0;

        // Kumpulkan semua pin di belahan depan & perbarui siklus jatuhnya
        final visiblePins = <_ActivePinView>[];
        // Setiap 2.6 detik satu pin utama di bagian depan melakukan animasi jatuh ulang
        final cycleBucket = (_elapsedSec / 2.6).floor();
        int? autoDropCandidate;
        var bestScore = -1.0;

        for (var i = 0; i < kGlobeSpots.length; i++) {
          final p = _project(_spotUnits[i], lonRad);
          if (p.z <= 0.13) {
            // Begitu berada di balik bumi, reset supaya jatuh segar saat terbit lagi
            _pinSpawnSec.remove(i);
            continue;
          }
          final spawn = _pinSpawnSec.putIfAbsent(i, () => _elapsedSec + 0.06);
          if (p.z > 0.52) {
            final score = ((i * 7 + cycleBucket * 3) % 13) + (kGlobeSpots[i].indonesia ? 6.0 : 0.0);
            if (score > bestScore) {
              bestScore = score;
              autoDropCandidate = i;
            }
          }
          var effectiveSpawn = spawn;
          if (_tappedPinIndex == i && (_elapsedSec - _tappedAtSec) < 1.2) {
            effectiveSpawn = _tappedAtSec;
          }
          visiblePins.add(
            _ActivePinView(
              index: i,
              spot: kGlobeSpots[i],
              category: categoryOf(kGlobeSpots[i].categoryKey),
              x: p.x,
              y: p.y,
              z: p.z,
              dropProgress: _elapsedSec - effectiveSpawn,
            ),
          );
        }

        // Pin yang terpilih pada siklus berkala menjatuhkan pin baru secara halus
        if (!reduced && autoDropCandidate != null && _elapsedSec > 2.8) {
          final cycleStart = cycleBucket * 2.6;
          final idx = visiblePins.indexWhere((v) => v.index == autoDropCandidate);
          if (idx >= 0 && (_elapsedSec - cycleStart) < 1.15) {
            final cur = visiblePins[idx];
            visiblePins[idx] = _ActivePinView(
              index: cur.index,
              spot: cur.spot,
              category: cur.category,
              x: cur.x,
              y: cur.y,
              z: cur.z,
              dropProgress: _elapsedSec - cycleStart,
            );
          }
        }

        // Urutkan dari belakang ke depan (depth sort z)
        visiblePins.sort((a, b) => a.z.compareTo(b.z));

        // Pilih hingga 11 pin ikon penuh yang tersebar merata, mengutamakan spot Indonesia
        final heroSet = <int>{};
        final heroScreenPts = <Offset>[];
        final minPinGap = (radius * .145).clamp(20.0, 29.0);
        final maxHero = radius < 100 ? 7 : 11;
        final heroOrder = [...visiblePins]..sort((a, b) {
          final ai = a.spot.indonesia ? 1 : 0;
          final bi = b.spot.indonesia ? 1 : 0;
          if (ai != bi) return bi.compareTo(ai);
          return b.z.compareTo(a.z);
        });
        for (final v in heroOrder) {
          if (v.z <= 0.24) continue;
          final pt = Offset(center.dx + v.x * radius, center.dy - v.y * radius);
          if (v.index != _tappedPinIndex &&
              heroScreenPts.any((o) => (o - pt).distance < minPinGap)) {
            continue;
          }
          heroSet.add(v.index);
          heroScreenPts.add(pt);
          if (heroSet.length >= maxHero) break;
        }

        // Pilih hingga 3 lencana tempat yang sudah mendarat (dropProgress >= 0.35)
        // pada slot luar bola yang berbeda dengan garis penunjuk halus ke pinnya.
        final calloutItems =
            <(_ActivePinView view, Offset boxRectTopLeft, double width, Offset lineTarget)>[];
        final usedSlots = <int>{};
        final usedCats = <String>{};
        final candidates = [
          ...visiblePins.where(
            (v) =>
                heroSet.contains(v.index) &&
                v.z > 0.38 &&
                (reduced || v.dropProgress >= 0.35),
          ),
        ]..sort((a, b) {
          final aTap = a.index == _tappedPinIndex ? 1 : 0;
          final bTap = b.index == _tappedPinIndex ? 1 : 0;
          if (aTap != bTap) return bTap.compareTo(aTap);
          final aIndo = a.spot.indonesia ? 1 : 0;
          final bIndo = b.spot.indonesia ? 1 : 0;
          if (aIndo != bIndo) return bIndo.compareTo(aIndo);
          return b.z.compareTo(a.z);
        });
        final maxCallouts = (shortest < 250 || radius < 92)
            ? 1
            : (shortest < 330 ? 2 : 3);
        final chipW = (w * .48).clamp(142.0, 192.0).toDouble();
        const chipH = 42.0;

        // Empat slot sudut luar di sekeliling globe: [kiri-atas, kanan-atas, kiri-bawah, kanan-bawah]
        final slotAnchors = <Offset>[
          Offset(
            (center.dx - radius * 1.02 - chipW * .55)
                .clamp(4.0, math.max(4.0, w - chipW - 4.0))
                .toDouble(),
            (center.dy - radius * .78)
                .clamp(4.0, math.max(4.0, h - chipH - 4.0))
                .toDouble(),
          ),
          Offset(
            (center.dx + radius * 1.02 - chipW * .45)
                .clamp(4.0, math.max(4.0, w - chipW - 4.0))
                .toDouble(),
            (center.dy - radius * .84)
                .clamp(4.0, math.max(4.0, h - chipH - 4.0))
                .toDouble(),
          ),
          Offset(
            (center.dx - radius * 1.02 - chipW * .55)
                .clamp(4.0, math.max(4.0, w - chipW - 4.0))
                .toDouble(),
            (center.dy + radius * .54)
                .clamp(4.0, math.max(4.0, h - chipH - 4.0))
                .toDouble(),
          ),
          Offset(
            (center.dx + radius * .96 - chipW * .38)
                .clamp(4.0, math.max(4.0, w - chipW - 4.0))
                .toDouble(),
            (center.dy + radius * .48)
                .clamp(4.0, math.max(4.0, h - chipH - 4.0))
                .toDouble(),
          ),
        ];

        for (final c in candidates) {
          if (calloutItems.isNotEmpty &&
              usedCats.contains(c.spot.categoryKey) &&
              c.index != _tappedPinIndex) {
            continue;
          }
          final pinPt = Offset(center.dx + c.x * radius, center.dy - c.y * radius);
          // Pilih slot kosong terdekat dengan posisi pin
          var bestSlot = -1;
          var bestDist = double.infinity;
          for (var s = 0; s < slotAnchors.length; s++) {
            if (usedSlots.contains(s)) continue;
            final boxCenter = slotAnchors[s] + Offset(chipW * .5, chipH * .5);
            // Hindari tumpang tindih antar kotak pada layar sempit
            final overlaps = calloutItems.any((existing) {
              return (existing.$2.dx - slotAnchors[s].dx).abs() < chipW * .88 &&
                  (existing.$2.dy - slotAnchors[s].dy).abs() < chipH + 8;
            });
            if (overlaps) continue;
            final dist = (boxCenter - pinPt).distance;
            if (dist < bestDist) {
              bestDist = dist;
              bestSlot = s;
            }
          }
          if (bestSlot < 0) continue;
          usedSlots.add(bestSlot);
          usedCats.add(c.spot.categoryKey);
          final tl = slotAnchors[bestSlot];
          final lineEnd = Offset(
            pinPt.dx.clamp(tl.dx + 14.0, tl.dx + chipW - 14.0).toDouble(),
            pinPt.dy < tl.dy ? tl.dy : (pinPt.dy > tl.dy + chipH ? tl.dy + chipH : tl.dy + chipH * .5),
          );
          calloutItems.add((c, tl, chipW, lineEnd));
          if (calloutItems.length >= maxCallouts) break;
        }

        final leaderLines =
            <(Offset fromPin, Offset toCard, Color color, double alpha)>[
              for (final item in calloutItems)
                (
                  Offset(
                    center.dx + item.$1.x * radius,
                    center.dy - item.$1.y * radius - 14,
                  ),
                  item.$4,
                  item.$1.category.color,
                  _dropMotion(item.$1.dropProgress, reduced).$4,
                ),
            ];

        final rippleData = <(Offset, Color, double)>[];
        final secondaryDots = <(Offset, Color, double)>[];
        for (final v in visiblePins) {
          final pos = Offset(center.dx + v.x * radius, center.dy - v.y * radius);
          final (_, _, _, _, ripple) = _dropMotion(v.dropProgress, reduced);
          if (ripple > 0 && ripple < 1) {
            rippleData.add((pos, v.category.color, ripple));
          }
          if (!heroSet.contains(v.index)) {
            secondaryDots.add((pos, v.category.color, v.z));
          }
        }

        return Semantics(
          label: 'Ilustrasi globe Bumi 3D Spots dengan pin lokasi tempat seru',
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dragging = true,
            onHorizontalDragUpdate: (d) {
              setState(() {
                // Manipulasi langsung 1:1 sesuai arah jari/kursor
                _centerLonDeg = (_centerLonDeg - d.delta.dx * 0.42) % 360.0;
              });
            },
            onHorizontalDragEnd: (d) {
              _dragging = false;
              _dragVelocityDeg = (-d.velocity.pixelsPerSecond.dx * 0.08).clamp(
                -95.0,
                95.0,
              );
            },
            onHorizontalDragCancel: () => _dragging = false,
            child: RepaintBoundary(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ChibiEarthPainter(
                        unitRings: _unitRings,
                        center: center,
                        radius: radius,
                        lonRad: lonRad,
                        centerLatRad: _centerLatRad,
                        tiltRad: _tiltRad,
                        cloudShiftRad: reduced ? .4 : _elapsedSec * 0.11,
                        orbitPhase: reduced ? .2 : (_elapsedSec * 0.09) % 1.0,
                        ripples: rippleData,
                        secondaryPins: secondaryDots,
                        leaderLines: leaderLines,
                      ),
                    ),
                  ),
                  // Pin 3D chibi lengkap dengan ikon asli SpotIcon
                  for (final v in visiblePins)
                    if (heroSet.contains(v.index))
                      _buildPinWidget(
                        v: v,
                        center: center,
                        radius: radius,
                        reduced: reduced,
                      ),
                  // Lencana kaca mengambang penunjuk nama tempat & kota asli Spots
                  for (final item in calloutItems)
                    _buildCalloutChip(
                      v: item.$1,
                      topLeft: item.$2,
                      chipW: item.$3,
                      reduced: reduced,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinWidget({
    required _ActivePinView v,
    required Offset center,
    required double radius,
    required bool reduced,
  }) {
    final (lift, sx, sy, opacity, _) = _dropMotion(v.dropProgress, reduced);
    final depthScale = (.76 + .28 * v.z).clamp(.76, 1.04);
    final pinSize = (radius * .22).clamp(26.0, 38.0) * depthScale;
    final anchorX = center.dx + v.x * radius;
    final anchorY = center.dy - v.y * radius;
    final floatBob = reduced
        ? 0.0
        : math.sin(_elapsedSec * 2.4 + v.index * .9) * 1.8;

    return Positioned(
      left: anchorX - pinSize * .5,
      top: anchorY - pinSize * 1.12 - lift + floatBob,
      child: Opacity(
        opacity: (opacity * (.55 + .45 * v.z)).clamp(0.0, 1.0),
        child: GestureDetector(
          onTap: () => setState(() {
            _tappedPinIndex = v.index;
            _tappedAtSec = _elapsedSec;
          }),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(sx, sy, 1.0),
            child: _ChibiMapPin(
              size: pinSize,
              color: v.category.color,
              glyph: v.category.glyph,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalloutChip({
    required _ActivePinView v,
    required Offset topLeft,
    required double chipW,
    required bool reduced,
  }) {
    final (_, _, _, opacity, _) = _dropMotion(v.dropProgress, reduced);

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: chipW,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: FrostedSurface(
            radius: 99,
            sigma: 14,
            fill: Colors.white.withValues(alpha: .92),
            padding: const EdgeInsets.fromLTRB(6, 5, 11, 5),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v.category.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: v.category.color.withValues(alpha: .38),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SpotIcon(
                    v.category.glyph,
                    size: 15,
                    color: Colors.white,
                    tint: false,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.spot.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          color: ink,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '${v.spot.city} · ${v.category.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: muted,
                          height: 1.15,
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
    );
  }
}

/// Pin peta 3D kenyal bergaya chibi dengan kilau jelly & ikon asli Spots.
class _ChibiMapPin extends StatelessWidget {
  const _ChibiMapPin({
    required this.size,
    required this.color,
    required this.glyph,
  });

  final double size;
  final Color color;
  final Glyph glyph;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.18,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(
            size: Size(size, size * 1.18),
            painter: _ChibiPinBodyPainter(color),
          ),
          Padding(
            padding: EdgeInsets.only(top: size * .20),
            child: SpotIcon(
              glyph,
              size: size * .52,
              color: Colors.white,
              tint: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChibiPinBodyPainter extends CustomPainter {
  const _ChibiPinBodyPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * .46;
    final cx = w * .5;
    final cy = w * .48;

    // Bayangan lembut di ujung pin pada daratan globe
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h - 1.5), width: w * .44, height: 4.5),
      Paint()..color = const Color(0x5506102E),
    );

    final tipY = h - 2.0;
    final pin = Path()
      ..moveTo(cx, tipY)
      ..quadraticBezierTo(cx - r * .92, cy + r * .52, cx - r, cy)
      ..arcToPoint(
        Offset(cx + r, cy),
        radius: Radius.circular(r),
        largeArc: true,
      )
      ..quadraticBezierTo(cx + r * .92, cy + r * .52, cx, tipY)
      ..close();

    // Isi gradasi kenyal 3D seperti maskot Spots
    final light = Color.lerp(color, Colors.white, .28)!;
    final dark = Color.lerp(color, const Color(0xFF0E183B), .24)!;
    canvas.drawPath(
      pin,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, color, dark],
          stops: const [0, .55, 1],
        ).createShader(Offset.zero & size),
    );

    // Garis tepi putih bersih supaya kontras di atas pulau maupun samudra
    canvas.drawPath(
      pin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * .065).clamp(1.6, 2.4)
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: .92),
    );

    // Kilau kapsul kecil di kiri atas ala mainan chibi 3D
    canvas.save();
    canvas.translate(cx - r * .36, cy - r * .38);
    canvas.rotate(-.48);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * .46, height: r * .22),
      Paint()..color = Colors.white.withValues(alpha: .46),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChibiPinBodyPainter old) => old.color != color;
}

class _ChibiEarthPainter extends CustomPainter {
  const _ChibiEarthPainter({
    required this.unitRings,
    required this.center,
    required this.radius,
    required this.lonRad,
    required this.centerLatRad,
    required this.tiltRad,
    required this.cloudShiftRad,
    required this.orbitPhase,
    required this.ripples,
    required this.secondaryPins,
    required this.leaderLines,
  });

  final List<List<(double, double, double)>> unitRings;
  final Offset center;
  final double radius, lonRad, centerLatRad, tiltRad, cloudShiftRad, orbitPhase;
  final List<(Offset, Color, double)> ripples;
  final List<(Offset, Color, double)> secondaryPins;
  final List<(Offset, Offset, Color, double)> leaderLines;

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

  @override
  void paint(Canvas canvas, Size size) {
    final sphereRect = Rect.fromCircle(center: center, radius: radius);
    final globeClip = Path()..addOval(sphereRect);

    // 1. Busur lintasan orbit bagian belakang (di balik bola Bumi)
    _drawOrbitArc(canvas, front: false);

    // 2. Pendaran atmosfer luar (Fresnel corona) dari angkasa
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

    // 3. Permukaan samudra 3D bergaya chibi jelly
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

    // 4. Garis lintang & bujur bola halus untuk menegaskan kelengkungan 3D
    _drawGraticule(canvas);

    // 5. Proyeksi seluruh benua & kepulauan nyata Natural Earth
    final landPath = _buildVisibleLandPath();

    // 5a. Dangkalan laut pirus (lagoon shelf) membulat di sekeliling pulau asli
    canvas.drawPath(
      landPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (radius * .048).clamp(4.0, 10.0)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF53EFE2).withValues(alpha: .36),
    );

    // 5b. Ketebalan timbul 3D (extrusion lip) di sisi bawah pulau & benua
    canvas.save();
    canvas.translate(0, (radius * .016).clamp(1.5, 3.6));
    final bevelPaint = Paint()..color = const Color(0xFF13684B);
    canvas.drawPath(landPath, bevelPaint);
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

    // 5c. Isi daratan hijau-mint chibi bergradasi cahaya matahari
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
    // Sedikit garis tepi sewarna supaya pulau ramping (Jawa, Bali, Sulawesi) tetap empuk
    canvas.drawPath(
      landPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (radius * .012).clamp(1.1, 2.5)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = landShader,
    );

    // 5d. Pantulan tepi atas (rim highlight) di permukaan benua seperti mainan 3D
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

    // 6. Gelombang riak cincin saat pin baru mendarat di koordinat kota
    for (final (pos, color, progress) in ripples) {
      final rr = (6.0 + progress * 22.0) * (radius / 160.0).clamp(.7, 1.2);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        pos,
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Colors.white.withValues(alpha: alpha * .85),
      );
      canvas.drawCircle(
        pos,
        rr * .65,
        Paint()..color = color.withValues(alpha: alpha * .35),
      );
    }

    // 7. Awan gembul chibi mengambang sedikit di atas permukaan beserta bayangannya
    _drawChibiClouds(canvas);

    // 8. Bayangan malam lembut di sisi kanan-bawah + pendaran atmosfer tepi bola
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

    // Kilau kapsul kaca di kiri atas bola Bumi
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

    // Cincin atmosfer tipis berkilau di sekeliling bola Bumi
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

    // 9. Pin titik chibi sekunder untuk kota-kota di kejauhan / tepi horizon
    for (final (pos, color, z) in secondaryPins) {
      final dotR = (radius * .034).clamp(3.6, 6.2) * (.7 + .3 * z);
      canvas.drawCircle(
        pos + const Offset(0, 1.5),
        dotR,
        Paint()..color = const Color(0x5506102E),
      );
      canvas.drawCircle(pos, dotR, Paint()..color = color);
      canvas.drawCircle(
        pos,
        dotR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: .92),
      );
    }

    // 10. Busur lintasan orbit bagian depan (melintas di depan globe)
    _drawOrbitArc(canvas, front: true);

    // 11. Garis penunjuk halus dari pin terpilih menuju kartu nama tempat
    for (final (fromPin, toCard, color, alpha) in leaderLines) {
      if (alpha <= 0.05) continue;
      final ctrl = Offset(
        (fromPin.dx + toCard.dx) * .5,
        math.min(fromPin.dy, toCard.dy) - 8,
      );
      final linePath = Path()
        ..moveTo(fromPin.dx, fromPin.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, toCard.dx, toCard.dy);
      canvas.drawPath(
        linePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .55 * alpha),
      );
      canvas.drawCircle(
        toCard,
        3.2,
        Paint()..color = color.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        toCard,
        3.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  void _drawOrbitArc(Canvas canvas, {required bool front}) {
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
    // Titik satelit/kilau kecil yang mengorbit pelan mengelilingi Bumi
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

  void _drawGraticule(Canvas canvas) {
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

  void _drawChibiClouds(Canvas canvas) {
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

      var puff = Path()
        ..addOval(Rect.fromCircle(center: cloudPos, radius: 11.5 * k));
      for (final part in [
        Path()
          ..addOval(
            Rect.fromCircle(
              center: cloudPos + Offset(-10 * k, 2.5 * k),
              radius: 8.5 * k,
            ),
          ),
        Path()
          ..addOval(
            Rect.fromCircle(
              center: cloudPos + Offset(10.5 * k, 2 * k),
              radius: 9.0 * k,
            ),
          ),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: cloudPos + Offset(0, 5.5 * k),
                width: 34 * k,
                height: 10 * k,
              ),
              Radius.circular(5 * k),
            ),
          ),
      ]) {
        puff = Path.combine(PathOperation.union, puff, part);
      }
      canvas.drawPath(
        puff,
        Paint()..color = Colors.white.withValues(alpha: (.82 * z2).clamp(.25, .86)),
      );
    }
  }

  /// Memotong poligon bola terhadap horizon z = 0 dengan menyambung busur
  /// melingkar berlawanan jarum jam (CCW) supaya tepi benua melengkung mulus.
  Path _buildVisibleLandPath() {
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
          for (final p in pts) Offset(center.dx + p.x * radius, center.dy - p.y * radius),
        ]);
        continue;
      }

      // Kumpulkan rantai titik yang berada di belahan depan (z > 0) dari titik masuk ke titik keluar horizon
      final chains = <_HorizonChain>[];
      // Cari indeks awal yang berada di belakang (z <= 0) supaya rantai tidak terbelah di indeks 0
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

      // Sambungkan titik keluar (exitAngle) tiap rantai ke titik masuk (enterAngle) terdekat
      // dalam arah CCW (sudut bertambah) sepanjang lingkaran horizon.
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

          // Cari rantai berikutnya berdasarkan jarak sudut CCW terkecil dari ch.exitAngle
          var bestNext = i;
          var bestDelta = double.infinity;
          for (var j = 0; j < chains.length; j++) {
            if (visited[j] && j != i) continue;
            var d = (chains[j].enterAngle - ch.exitAngle) % (math.pi * 2);
            if (d < 0) d += math.pi * 2;
            if (d < bestDelta) {
              bestDelta = d;
              bestNext = j;
            }
          }

          // Sisipkan titik-titik busur sepanjang lingkaran tepi bola Bumi
          final steps = (bestDelta / 0.11).ceil().clamp(1, 64);
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

        if (loopPts.length >= 3) {
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
      old.lonRad != lonRad ||
      old.cloudShiftRad != cloudShiftRad ||
      old.orbitPhase != orbitPhase ||
      old.radius != radius ||
      old.center != center ||
      old.ripples.length != ripples.length;
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
