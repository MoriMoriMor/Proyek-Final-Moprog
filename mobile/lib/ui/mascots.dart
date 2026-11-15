import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';

/// Keluarga maskot Spots. Semua digambar dengan kode supaya mata,
/// tangan, dan badan bisa bergerak sendiri-sendiri.
enum MascotKind {
  /// Piko, si blob biru. Pemandu utama.
  piko('Piko'),

  /// Mimi, mangkuk mi. Teman kategori kuliner.
  mimi('Mimi'),

  /// Jojo, gelas kopi. Teman kategori kafe.
  jojo('Jojo'),

  /// Gugu, bukit kecil berbendera. Teman kategori destinasi.
  gugu('Gugu'),

  /// Tote, tas belanja. Penjaga market.
  tote('Tote'),

  /// Pino, pin peta. Penunjuk jalan.
  pino('Pino'),

  /// Cici, bintang kilau. Muncul saat dapat XP dan misi.
  cici('Cici'),

  /// Bobi, bola tenis. Teman kategori olahraga.
  bobi('Bobi'),

  /// Tika, tiket. Teman kategori aktivitas.
  tika('Tika'),

  /// Rumi, rumah mungil. Teman kategori menginap.
  rumi('Rumi');

  const MascotKind(this.label);
  final String label;

  static MascotKind forCategory(String? category) => switch (category) {
    'kuliner' => mimi,
    'kafe' => jojo,
    'destinasi' => gugu,
    'olahraga' => bobi,
    'aktivitas' => tika,
    'belanja' || 'lainnya' => tote,
    'menginap' => rumi,
    _ => piko,
  };
}

enum MascotMood { happy, laugh, wow, sleepy, wink, love, cool }

/// Maskot yang hidup: bernapas, melirik, berkedip acak, melambai,
/// mengikuti kursor, dan melompat saat disentuh.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.kind = MascotKind.piko,
    this.size = 120,
    this.mood = MascotMood.happy,
    this.wave = false,
    this.bounce = true,
    this.interactive = true,
    this.delay = 0,
  });

  final MascotKind kind;
  final double size;
  final MascotMood mood;
  final bool wave, bounce, interactive;

  /// Geser fase gerak supaya maskot yang berdampingan tidak seirama.
  final double delay;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );
  late final hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  final random = math.Random();
  Timer? blinkTimer;
  bool blinking = false;
  Offset? pointer;

  @override
  void initState() {
    super.initState();
    idle.value = widget.delay % 1;
    scheduleBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context) || !widget.bounce) {
      idle.stop();
    } else if (!idle.isAnimating) {
      idle.repeat();
    }
  }

  void scheduleBlink() {
    blinkTimer = Timer(
      Duration(milliseconds: 1800 + random.nextInt(3200)),
      () async {
        if (!mounted) return;
        setState(() => blinking = true);
        await Future<void>.delayed(const Duration(milliseconds: 130));
        if (!mounted) return;
        setState(() => blinking = false);
        // Kadang berkedip dua kali.
        if (random.nextDouble() < .3) {
          await Future<void>.delayed(const Duration(milliseconds: 140));
          if (!mounted) return;
          setState(() => blinking = true);
          await Future<void>.delayed(const Duration(milliseconds: 110));
          if (mounted) setState(() => blinking = false);
        }
        scheduleBlink();
      },
    );
  }

  @override
  void dispose() {
    blinkTimer?.cancel();
    idle.dispose();
    hop.dispose();
    super.dispose();
  }

  void poke() {
    if (calm(context)) return;
    HapticFeedback.lightImpact();
    hop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final painter = AnimatedBuilder(
      animation: Listenable.merge([idle, hop]),
      builder: (context, _) {
        final t = idle.value;
        final h = hop.value;
        final hopping = hop.isAnimating;
        // Gerak lirikan dari gabungan dua gelombang supaya tidak terasa mekanis.
        var gaze = Offset(
          math.sin(t * math.pi * 2) * .45,
          math.sin(t * math.pi * 4 + 1) * .2 - .15,
        );
        // Sesekali menatap lurus ke depan.
        if (t > .3 && t < .7) gaze = const Offset(0, -.1);
        final p = pointer;
        if (p != null) {
          final center = Offset(widget.size / 2, widget.size * .45);
          final d = p - center;
          final len = d.distance;
          gaze = len < 1 ? Offset.zero : d / math.max(len, widget.size * .6);
        }
        return CustomPaint(
          size: Size.square(widget.size),
          painter: MascotPainter(
            kind: widget.kind,
            mood: hopping && h < .85 ? MascotMood.laugh : widget.mood,
            t: t,
            hop: h,
            blink: blinking && !hopping,
            gaze: Offset(gaze.dx.clamp(-1, 1), gaze.dy.clamp(-1, 1)),
            wave: widget.wave || (hopping && h < .8),
            still: !widget.bounce,
          ),
        );
      },
    );
    if (!widget.interactive) return ExcludeSemantics(child: painter);
    return Semantics(
      label: widget.kind.label,
      child: MouseRegion(
        onHover: (e) => setState(() => pointer = e.localPosition),
        onExit: (_) => setState(() => pointer = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: poke,
          child: painter,
        ),
      ),
    );
  }
}

/// Menggambar satu pose maskot di kotak 120×120.
class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.kind,
    required this.mood,
    this.t = 0,
    this.hop = 0,
    this.blink = false,
    this.gaze = Offset.zero,
    this.wave = false,
    this.still = false,
  });

  final MascotKind kind;
  final MascotMood mood;
  final double t, hop;
  final bool blink, wave, still;
  final Offset gaze;

  static const ink = Color(0xFF172657);

  late final _Spec _spec = _Spec.of(kind);

  /// Warna fitur wajah: abu tua yang lembut, bukan hitam pekat.
  static const face = Color(0xFF3B3A4A);
  static const foot = Color(0xFFFF9F1C);

  Paint get line => Paint()
    ..color = face
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint fill(Color c) => Paint()..color = c;

  Color get _dark => Color.lerp(_spec.color, Colors.black, .16)!;
  Color get _light => Color.lerp(_spec.color, Colors.white, .38)!;

  /// Bentuk datar tanpa garis tepi, dengan gradasi lembut supaya terasa
  /// sedikit timbul: terang di kiri atas, lebih gelap di kanan bawah.
  void shape(Canvas canvas, Path path, Color color, {bool shade = true}) {
    canvas.drawPath(path, fill(color));
    if (!shade) return;
    final b = path.getBounds();
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      b,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .5, 1],
          colors: [
            Colors.white.withValues(alpha: .22),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: .14),
          ],
        ).createShader(b),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 120);
    final w = still ? 0.0 : t * math.pi * 2;

    // Lompatan: jongkok, melayang, lalu mendarat dengan sedikit pantulan.
    var lift = 0.0, squash = 1.0;
    if (hop > 0 && hop < 1) {
      if (hop < .18) {
        squash = 1 - math.sin(hop / .18 * math.pi) * .14;
      } else if (hop < .75) {
        final k = (hop - .18) / .57;
        lift = math.sin(k * math.pi) * 26;
        squash = 1 + math.sin(k * math.pi) * .07;
      } else {
        final k = (hop - .75) / .25;
        squash = 1 - math.sin(k * math.pi) * .1;
      }
    }
    final breathe = still ? 1.0 : 1 + math.sin(w * 2) * .025;
    final bob = still ? 0.0 : math.sin(w * 2) * 1.6;
    final sway = still ? 0.0 : math.sin(w) * .05;

    // Bayangan di tanah mengecil saat melompat.
    final shadowScale = 1 - lift / 60;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(60, 117),
        width: 64 * shadowScale,
        height: 7 * shadowScale,
      ),
      Paint()..color = ink.withValues(alpha: .13),
    );

    canvas.save();
    canvas.translate(60, 116 - lift + bob);
    canvas.rotate(sway);
    canvas.scale((2 - squash * breathe).clamp(.8, 1.2), squash * breathe);
    canvas.translate(-60, -116);

    _feet(canvas, lift);
    _behind(canvas, w);
    _arm(
      canvas,
      _spec.leftShoulder,
      .55 + math.sin(w * 2 + 1) * .12,
      left: true,
    );
    shape(canvas, _spec.body, _spec.color);
    _details(canvas, w);
    _arm(
      canvas,
      _spec.rightShoulder,
      wave
          ? -2.5 + math.sin(t * math.pi * 16) * .45
          : -.55 - math.sin(w * 2) * .12,
      left: false,
    );
    _face(canvas, w);
    canvas.restore();
  }

  void _feet(Canvas canvas, double lift) {
    if (kind == MascotKind.pino || kind == MascotKind.cici) return;
    final spread = lift > 2 ? 3.0 : 0.0;
    for (final x in [46.0 - spread, 74.0 + spread]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 115), width: 19, height: 10),
        fill(foot),
      );
    }
  }

  void _arm(
    Canvas canvas,
    Offset shoulder,
    double angle, {
    required bool left,
  }) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(angle);
    final arm = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-5.5, -2, 11, 22),
      const Radius.circular(6),
    );
    canvas.drawRRect(arm, fill(_dark));
    canvas.restore();
  }

  void _behind(Canvas canvas, double w) {
    switch (kind) {
      case MascotKind.piko:
        final wiggle = math.sin(w * 3) * .08;
        for (final (x, a) in [(44.0, -.28 - wiggle), (76.0, .28 + wiggle)]) {
          canvas.save();
          canvas.translate(x, 30);
          canvas.rotate(a);
          final ear = RRect.fromRectAndRadius(
            const Rect.fromLTWH(-8, -26, 16, 32),
            const Radius.circular(8),
          );
          canvas.drawRRect(ear, fill(_dark));
          canvas.drawRRect(ear.deflate(4), fill(const Color(0xFF82A1FF)));
          canvas.restore();
        }
      case MascotKind.jojo:
        final steam = Paint()
          ..color = ink.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round;
        for (final (x, phase) in [(48.0, 0.0), (66.0, 1.6)]) {
          final s = math.sin(w * 2 + phase) * 4;
          canvas.drawPath(
            Path()
              ..moveTo(x, 22)
              ..cubicTo(x - 7 + s, 15, x + 7 + s, 10, x + s, 2),
            steam,
          );
        }
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(96, 72), width: 22, height: 26),
          -math.pi / 2,
          math.pi,
          false,
          Paint()
            ..color = _dark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
      case MascotKind.gugu:
        canvas.drawLine(
          const Offset(60, 20),
          const Offset(60, -2),
          Paint()
            ..color = const Color(0xFF8C8A9E)
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round,
        );
        final flap = math.sin(w * 4) * 3;
        final flag = Path()
          ..moveTo(60, -2)
          ..quadraticBezierTo(72, -1 + flap, 82, 4 + flap)
          ..quadraticBezierTo(72, 9 - flap, 60, 10)
          ..close();
        shape(canvas, flag, const Color(0xFFF27B8E));
      case MascotKind.tote:
        final handle = Paint()
          ..color = _dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromLTWH(40, 26, 40, 34),
          math.pi,
          math.pi,
          false,
          handle,
        );
      default:
        break;
    }
  }

  void _details(Canvas canvas, double w) {
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    switch (kind) {
      case MascotKind.piko:
        canvas.drawArc(
          Rect.fromLTWH(26, 36, 40, 50),
          math.pi * 1.05,
          .9,
          false,
          shine,
        );
      case MascotKind.mimi:
        final noodles = Path()
          ..moveTo(18, 60)
          ..cubicTo(22, 34, 98, 34, 102, 60)
          ..close();
        shape(canvas, noodles, const Color(0xFFFFD86B));
        final squiggle = Paint()
          ..color = const Color(0xFFE5A92E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final x = 34.0 + i * 16;
          canvas.drawPath(
            Path()
              ..moveTo(x, 54)
              ..quadraticBezierTo(x + 4, 46, x + 8, 54),
            squiggle,
          );
        }
        final rim = RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, 56, 100, 13),
          const Radius.circular(7),
        );
        canvas.drawRRect(rim, fill(const Color(0xFFFF8E73)));
        final sticks = Paint()
          ..color = const Color(0xFF8A5A2B)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        final tilt = math.sin(w * 2) * 2;
        canvas.drawLine(Offset(70, 46), Offset(100 + tilt, 12), sticks);
        canvas.drawLine(Offset(78, 48), Offset(108 + tilt, 18), sticks);
      case MascotKind.jojo:
        final lid = RRect.fromRectAndRadius(
          const Rect.fromLTWH(18, 26, 84, 15),
          const Radius.circular(8),
        );
        canvas.drawRRect(lid, fill(const Color(0xFF7A4A2A)));
        final sleeve = Path()
          ..moveTo(28, 92)
          ..lineTo(92, 92)
          ..lineTo(90, 106)
          ..lineTo(30, 106)
          ..close();
        shape(canvas, sleeve, const Color(0xFFFFE7C2));
      case MascotKind.gugu:
        final snow = Path()
          ..moveTo(42, 46)
          ..lineTo(50, 30)
          ..quadraticBezierTo(60, 16, 70, 30)
          ..lineTo(78, 46)
          ..lineTo(70, 41)
          ..lineTo(64, 48)
          ..lineTo(57, 41)
          ..lineTo(50, 48)
          ..close();
        shape(canvas, snow, Colors.white);
      case MascotKind.tote:
        final swing = math.sin(w * 3) * .25;
        canvas.save();
        canvas.translate(74, 30);
        canvas.rotate(swing);
        canvas.drawLine(
          Offset.zero,
          const Offset(0, 7),
          Paint()
            ..color = _dark
            ..strokeWidth = 2.6,
        );
        final tag = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, 7, 14, 15),
          const Radius.circular(4),
        );
        canvas.drawRRect(tag, fill(const Color(0xFFF27B8E)));
        canvas.restore();
      case MascotKind.pino:
        canvas.drawArc(
          Rect.fromLTWH(26, 20, 34, 40),
          math.pi * 1.05,
          .9,
          false,
          shine,
        );
      case MascotKind.cici:
        canvas.drawCircle(
          const Offset(104, 22),
          4 + math.sin(w * 3) * 1.5,
          fill(const Color(0xFFF27B8E)),
        );
        canvas.drawCircle(
          const Offset(16, 100),
          3 + math.cos(w * 3) * 1.2,
          fill(const Color(0xFF416CF4)),
        );
      case MascotKind.bobi:
        final seam = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.4
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(14, 70), radius: 34),
          -.95,
          1.9,
          false,
          seam,
        );
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(106, 70), radius: 34),
          math.pi - .95,
          1.9,
          false,
          seam,
        );
        canvas.drawArc(
          Rect.fromLTWH(30, 34, 30, 34),
          math.pi * 1.05,
          .9,
          false,
          shine,
        );
      case MascotKind.tika:
        final dash = Paint()
          ..color = Colors.white.withValues(alpha: .7)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (var y = 40.0; y < 108; y += 9) {
          canvas.drawLine(Offset(90, y), Offset(90, y + 4), dash);
        }
        final star = Path()
          ..moveTo(98, 60)
          ..lineTo(100, 66)
          ..lineTo(106, 67)
          ..lineTo(101, 71)
          ..lineTo(103, 77)
          ..lineTo(98, 73)
          ..lineTo(93, 77)
          ..lineTo(95, 71)
          ..lineTo(90, 67)
          ..lineTo(96, 66)
          ..close();
        canvas.drawPath(star, fill(const Color(0xFFFFCE3B)));
      case MascotKind.rumi:
        final roof = Path()
          ..moveTo(8, 60)
          ..lineTo(60, 16)
          ..lineTo(112, 60)
          ..quadraticBezierTo(114, 64, 108, 64)
          ..lineTo(12, 64)
          ..quadraticBezierTo(6, 64, 8, 60)
          ..close();
        final chimney = RRect.fromRectAndRadius(
          const Rect.fromLTWH(80, 20, 13, 24),
          const Radius.circular(3),
        );
        canvas.drawRRect(chimney, fill(const Color(0xFFB9C3E6)));
        final puff = still ? 0.0 : (w / (math.pi * 2) * 3) % 1;
        canvas.drawCircle(
          Offset(87 + puff * 6, 14 - puff * 14),
          4 + puff * 4,
          Paint()..color = const Color(0xFFB9C3E6).withValues(alpha: 1 - puff),
        );
        shape(canvas, roof, const Color(0xFFF27B8E));
    }
  }

  void _face(Canvas canvas, double w) {
    final (l, r) = _spec.eyes;
    final er = _spec.eyeRadius;
    // Topeng wajah yang lebih terang di sekitar mata.
    final patch = fill(_light.withValues(alpha: .75));
    canvas.drawCircle(l, er * 1.42, patch);
    canvas.drawCircle(r, er * 1.42, patch);
    canvas.drawRect(
      Rect.fromLTRB(l.dx, l.dy - er * 1.1, r.dx, r.dy + er * 1.1),
      patch,
    );
    final blush = Paint()
      ..color = const Color(0xFFFF8E9B).withValues(alpha: .6);
    canvas.drawOval(
      Rect.fromCenter(
        center: l + Offset(-er * .9, er * 1.5),
        width: er * 1.3,
        height: er * .8,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: r + Offset(er * .9, er * 1.5),
        width: er * 1.3,
        height: er * .8,
      ),
      blush,
    );

    switch (mood) {
      case MascotMood.cool:
        final glasses = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: l, width: er * 2.8, height: er * 1.9),
              Radius.circular(er * .6),
            ),
          )
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: r, width: er * 2.8, height: er * 1.9),
              Radius.circular(er * .6),
            ),
          );
        canvas.drawPath(glasses, fill(const Color(0xFF2E2D3A)));
        canvas.drawLine(
          l + Offset(er * 1.3, -er * .3),
          r - Offset(er * 1.3, er * .3),
          Paint()
            ..color = const Color(0xFF2E2D3A)
            ..strokeWidth = 4,
        );
        final glint = Paint()
          ..color = Colors.white.withValues(alpha: .7)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        for (final e in [l, r]) {
          canvas.drawLine(
            e + Offset(-er * .8, -er * .2),
            e + Offset(-er * .3, -er * .6),
            glint,
          );
        }
      case MascotMood.laugh:
        _happyEye(canvas, l, er);
        _happyEye(canvas, r, er);
      case MascotMood.sleepy:
        _eye(canvas, l, er, big: false, side: 1, lid: .62);
        _eye(canvas, r, er, big: false, side: -1, lid: .62);
        final z = Paint()
          ..color = face.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round;
        final float = still ? 0.0 : math.sin(w * 2) * 3;
        canvas.drawPath(
          Path()
            ..moveTo(96, 18 + float)
            ..lineTo(106, 18 + float)
            ..lineTo(96, 28 + float)
            ..lineTo(106, 28 + float),
          z,
        );
      case MascotMood.wink:
        _eye(canvas, l, er, big: false, side: 1);
        _happyEye(canvas, r, er);
      case MascotMood.love:
        for (final e in [l, r]) {
          _heart(canvas, e, er * 1.15);
        }
      case MascotMood.wow:
        _eye(canvas, l, er * 1.1, big: true, side: 1);
        _eye(canvas, r, er * 1.1, big: true, side: -1);
      case MascotMood.happy:
        _eye(canvas, l, er, big: false, side: 1);
        _eye(canvas, r, er, big: false, side: -1);
    }

    final m = _spec.mouth;
    switch (mood) {
      case MascotMood.wow:
        canvas.drawOval(
          Rect.fromCenter(
            center: m + const Offset(0, 2),
            width: 11,
            height: 14,
          ),
          fill(ink),
        );
      case MascotMood.laugh || MascotMood.love:
        final open = Path()
          ..moveTo(m.dx - 11, m.dy - 3)
          ..quadraticBezierTo(m.dx, m.dy - 1, m.dx + 11, m.dy - 3)
          ..quadraticBezierTo(m.dx + 9, m.dy + 12, m.dx, m.dy + 12)
          ..quadraticBezierTo(m.dx - 9, m.dy + 12, m.dx - 11, m.dy - 3)
          ..close();
        canvas.drawPath(open, fill(face));
        canvas.drawOval(
          Rect.fromCenter(center: m + const Offset(0, 8), width: 10, height: 6),
          fill(const Color(0xFFFF6F86)),
        );
      case MascotMood.sleepy:
        canvas.drawLine(
          m - const Offset(5, 0),
          m + const Offset(5, 0),
          line..strokeWidth = 4,
        );
      case MascotMood.cool:
        canvas.drawPath(
          Path()
            ..moveTo(m.dx - 9, m.dy + 1)
            ..quadraticBezierTo(m.dx + 2, m.dy + 7, m.dx + 10, m.dy - 3),
          line..strokeWidth = 4.2,
        );
      default:
        final smile = Path()
          ..moveTo(m.dx - 8, m.dy - 2)
          ..quadraticBezierTo(m.dx, m.dy, m.dx + 8, m.dy - 2)
          ..quadraticBezierTo(m.dx + 7, m.dy + 8, m.dx, m.dy + 8)
          ..quadraticBezierTo(m.dx - 7, m.dy + 8, m.dx - 8, m.dy - 2)
          ..close();
        canvas.drawPath(smile, fill(face));
        canvas.drawOval(
          Rect.fromCenter(
            center: m + const Offset(0, 5.5),
            width: 7,
            height: 4,
          ),
          fill(const Color(0xFFFF6F86)),
        );
    }
  }

  /// Mata besar: putih bersih, pupil lonjong abu tua yang mengarah ke tengah,
  /// satu kilau besar. [lid] 0..1 menutup mata dari atas untuk ekspresi santai.
  void _eye(
    Canvas canvas,
    Offset c,
    double r, {
    required bool big,
    double side = 0,
    double lid = 0,
  }) {
    if (blink) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - r * .8, c.dy + r * .15)
          ..quadraticBezierTo(
            c.dx,
            c.dy + r * .7,
            c.dx + r * .8,
            c.dy + r * .15,
          ),
        line..strokeWidth = 4,
      );
      return;
    }
    canvas.save();
    final eye = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    canvas.clipPath(eye);
    canvas.drawCircle(c, r, fill(Colors.white));
    final pupil = c + Offset(side * r * .26, r * .1) + gaze * r * .18;
    final pw = r * (big ? .9 : 1.0), ph = r * (big ? 1.08 : 1.2);
    canvas.drawOval(
      Rect.fromCenter(center: pupil, width: pw, height: ph),
      fill(face),
    );
    canvas.drawCircle(
      pupil + Offset(-pw * .18, -ph * .22),
      pw * .22,
      fill(Colors.white),
    );
    if (lid > 0) {
      canvas.drawRect(
        Rect.fromLTRB(c.dx - r, c.dy - r, c.dx + r, c.dy - r + r * 2 * lid),
        fill(_light),
      );
      canvas.drawLine(
        Offset(c.dx - r, c.dy - r + r * 2 * lid),
        Offset(c.dx + r, c.dy - r + r * 2 * lid),
        Paint()
          ..color = _dark
          ..strokeWidth = 3,
      );
    }
    canvas.restore();
  }

  void _happyEye(Canvas canvas, Offset c, double r) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * .9, c.dy + r * .3)
        ..quadraticBezierTo(c.dx, c.dy - r * 1.1, c.dx + r * .9, c.dy + r * .3),
      line..strokeWidth = 4.4,
    );
  }

  void _heart(Canvas canvas, Offset c, double s) {
    final beat = still ? 1.0 : 1 + math.sin(t * math.pi * 12).abs() * .15;
    final h = s * beat;
    final path = Path()
      ..moveTo(c.dx, c.dy + h * .7)
      ..cubicTo(
        c.dx - h * 1.2,
        c.dy - h * .1,
        c.dx - h * .6,
        c.dy - h,
        c.dx,
        c.dy - h * .35,
      )
      ..cubicTo(
        c.dx + h * .6,
        c.dy - h,
        c.dx + h * 1.2,
        c.dy - h * .1,
        c.dx,
        c.dy + h * .7,
      )
      ..close();
    canvas.drawPath(path, fill(const Color(0xFFFF4F79)));
  }

  @override
  bool shouldRepaint(MascotPainter old) =>
      old.t != t ||
      old.hop != hop ||
      old.blink != blink ||
      old.gaze != gaze ||
      old.mood != mood ||
      old.wave != wave ||
      old.kind != kind;
}

class _Spec {
  const _Spec({
    required this.color,
    required this.body,
    required this.eyes,
    required this.eyeRadius,
    required this.mouth,
    required this.leftShoulder,
    required this.rightShoulder,
  });

  final Color color;
  final Path body;
  final (Offset, Offset) eyes;
  final double eyeRadius;
  final Offset mouth, leftShoulder, rightShoulder;

  static final _cache = <MascotKind, _Spec>{};

  static _Spec of(MascotKind kind) => _cache.putIfAbsent(
    kind,
    () => switch (kind) {
      MascotKind.piko => _Spec(
        color: const Color(0xFF416CF4),
        body: Path()
          ..moveTo(60, 24)
          ..cubicTo(90, 24, 104, 46, 104, 74)
          ..cubicTo(104, 100, 86, 114, 60, 114)
          ..cubicTo(34, 114, 16, 100, 16, 74)
          ..cubicTo(16, 46, 30, 24, 60, 24)
          ..close(),
        eyes: (const Offset(44, 64), const Offset(76, 64)),
        eyeRadius: 13,
        mouth: const Offset(60, 89),
        leftShoulder: const Offset(20, 78),
        rightShoulder: const Offset(100, 78),
      ),
      MascotKind.mimi => _Spec(
        color: const Color(0xFFFF6A4D),
        body: Path()
          ..moveTo(14, 64)
          ..lineTo(106, 64)
          ..cubicTo(106, 96, 86, 114, 60, 114)
          ..cubicTo(34, 114, 14, 96, 14, 64)
          ..close(),
        eyes: (const Offset(43, 84), const Offset(77, 84)),
        eyeRadius: 12,
        mouth: const Offset(60, 103),
        leftShoulder: const Offset(18, 80),
        rightShoulder: const Offset(102, 80),
      ),
      MascotKind.jojo => _Spec(
        color: const Color(0xFFF2A23A),
        body: Path()
          ..moveTo(24, 38)
          ..lineTo(96, 38)
          ..lineTo(88, 110)
          ..quadraticBezierTo(87, 115, 82, 115)
          ..lineTo(38, 115)
          ..quadraticBezierTo(33, 115, 32, 110)
          ..close(),
        eyes: (const Offset(45, 62), const Offset(75, 62)),
        eyeRadius: 12,
        mouth: const Offset(60, 82),
        leftShoulder: const Offset(26, 70),
        rightShoulder: const Offset(94, 70),
      ),
      MascotKind.gugu => _Spec(
        color: const Color(0xFF2CC197),
        body: Path()
          ..moveTo(14, 114)
          ..quadraticBezierTo(8, 114, 11, 108)
          ..lineTo(50, 30)
          ..quadraticBezierTo(60, 16, 70, 30)
          ..lineTo(109, 108)
          ..quadraticBezierTo(112, 114, 106, 114)
          ..close(),
        eyes: (const Offset(47, 76), const Offset(73, 76)),
        eyeRadius: 11.5,
        mouth: const Offset(60, 97),
        leftShoulder: const Offset(30, 84),
        rightShoulder: const Offset(90, 84),
      ),
      MascotKind.tote => _Spec(
        color: const Color(0xFFF4C65F),
        body: Path()
          ..moveTo(24, 44)
          ..lineTo(96, 44)
          ..lineTo(103, 108)
          ..quadraticBezierTo(104, 114, 98, 114)
          ..lineTo(22, 114)
          ..quadraticBezierTo(16, 114, 17, 108)
          ..close(),
        eyes: (const Offset(44, 72), const Offset(76, 72)),
        eyeRadius: 12,
        mouth: const Offset(60, 95),
        leftShoulder: const Offset(22, 76),
        rightShoulder: const Offset(98, 76),
      ),
      MascotKind.pino => _Spec(
        color: const Color(0xFFF27B8E),
        body: Path()
          ..moveTo(60, 116)
          ..cubicTo(42, 94, 18, 76, 18, 52)
          ..cubicTo(18, 28, 37, 12, 60, 12)
          ..cubicTo(83, 12, 102, 28, 102, 52)
          ..cubicTo(102, 76, 78, 94, 60, 116)
          ..close(),
        eyes: (const Offset(45, 50), const Offset(75, 50)),
        eyeRadius: 13,
        mouth: const Offset(60, 74),
        leftShoulder: const Offset(22, 60),
        rightShoulder: const Offset(98, 60),
      ),
      MascotKind.cici => _Spec(
        color: const Color(0xFFFFCE3B),
        body: Path()
          ..moveTo(60, 8)
          ..quadraticBezierTo(68, 50, 112, 60)
          ..quadraticBezierTo(68, 70, 60, 114)
          ..quadraticBezierTo(52, 70, 8, 60)
          ..quadraticBezierTo(52, 50, 60, 8)
          ..close(),
        eyes: (const Offset(50, 56), const Offset(70, 56)),
        eyeRadius: 9.5,
        mouth: const Offset(60, 72),
        leftShoulder: const Offset(30, 60),
        rightShoulder: const Offset(90, 60),
      ),
      MascotKind.bobi => _Spec(
        color: const Color(0xFFA6E04B),
        body: Path()
          ..addOval(Rect.fromCircle(center: const Offset(60, 70), radius: 44)),
        eyes: (const Offset(45, 64), const Offset(75, 64)),
        eyeRadius: 12.5,
        mouth: const Offset(60, 88),
        leftShoulder: const Offset(19, 78),
        rightShoulder: const Offset(101, 78),
      ),
      MascotKind.tika => _Spec(
        color: const Color(0xFF8B6CF3),
        body: Path()
          ..moveTo(22, 34)
          ..lineTo(98, 34)
          ..quadraticBezierTo(106, 34, 106, 42)
          ..lineTo(106, 62)
          ..arcToPoint(
            const Offset(106, 82),
            radius: const Radius.circular(10),
            clockwise: false,
          )
          ..lineTo(106, 104)
          ..quadraticBezierTo(106, 112, 98, 112)
          ..lineTo(22, 112)
          ..quadraticBezierTo(14, 112, 14, 104)
          ..lineTo(14, 82)
          ..arcToPoint(
            const Offset(14, 62),
            radius: const Radius.circular(10),
            clockwise: false,
          )
          ..lineTo(14, 42)
          ..quadraticBezierTo(14, 34, 22, 34)
          ..close(),
        eyes: (const Offset(40, 64), const Offset(68, 64)),
        eyeRadius: 12,
        mouth: const Offset(54, 88),
        leftShoulder: const Offset(16, 92),
        rightShoulder: const Offset(104, 92),
      ),
      MascotKind.rumi => _Spec(
        color: const Color(0xFF3BB4E8),
        body: Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(20, 50, 80, 64),
              const Radius.circular(12),
            ),
          ),
        eyes: (const Offset(45, 80), const Offset(75, 80)),
        eyeRadius: 11.5,
        mouth: const Offset(60, 100),
        leftShoulder: const Offset(22, 86),
        rightShoulder: const Offset(98, 86),
      ),
    },
  );
}

/// Barisan maskot yang muncul bergantian, untuk onboarding dan perayaan.
class MascotCrew extends StatelessWidget {
  const MascotCrew({
    super.key,
    this.kinds = const [
      MascotKind.mimi,
      MascotKind.jojo,
      MascotKind.piko,
      MascotKind.gugu,
      MascotKind.tote,
    ],
    this.size = 70,
    this.mood = MascotMood.happy,
  });

  final List<MascotKind> kinds;
  final double size;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (final (i, kind) in kinds.indexed)
        Rise(
          index: i,
          from: 40,
          child: Transform.translate(
            offset: Offset(0, i.isEven ? 0 : -size * .12),
            child: Mascot(
              kind: kind,
              size: kind == MascotKind.piko ? size * 1.25 : size,
              mood: kind == MascotKind.piko ? mood : MascotMood.happy,
              wave: i == kinds.length ~/ 2,
              delay: i * .17,
            ),
          ),
        ),
    ],
  );
}
