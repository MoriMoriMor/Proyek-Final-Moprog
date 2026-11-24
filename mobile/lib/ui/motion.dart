import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

bool calm(BuildContext context) => MediaQuery.disableAnimationsOf(context);

const motionQuick = Duration(milliseconds: 140);
const motionPage = Duration(milliseconds: 280);
const motionReveal = Duration(milliseconds: 380);
const motionCurve = Cubic(.2, 0, 0, 1);
const activationKeys = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
};

Duration motionTime(BuildContext context, Duration duration) =>
    calm(context) ? Duration.zero : duration;

/// Tombol tebal dengan tepi bawah. Saat ditekan, mukanya turun menutup tepi.
class Chunky extends StatefulWidget {
  const Chunky({
    super.key,
    required this.child,
    required this.onTap,
    this.color = piko,
    this.edge,
    this.radius = 20,
    this.depth = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
    this.expand = false,
    this.label,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? edge;
  final double radius, depth;
  final EdgeInsets padding;
  final bool expand;
  final String? label;
  final Color? border;

  @override
  State<Chunky> createState() => _ChunkyState();
}

class _ChunkyState extends State<Chunky> {
  bool down = false;
  bool focused = false;

  void set(bool value) {
    if (widget.onTap != null && down != value) setState(() => down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final face = enabled ? widget.color : const Color(0xFFDDE1EE);
    final edge = enabled
        ? widget.edge ?? edgeOf(widget.color)
        : const Color(0xFFC3C8D9);
    final radius = BorderRadius.circular(widget.radius);
    final shift = down ? widget.depth : 0.0;
    return FocusableActionDetector(
      enabled: enabled,
      includeFocusSemantics: false,
      shortcuts: activationKeys,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowFocusHighlight: (value) => setState(() => focused = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        enabled: enabled,
        focusable: enabled,
        focused: focused,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => set(true),
          onTapCancel: () => set(false),
          onTapUp: (_) => set(false),
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onTap!();
                }
              : null,
          child: Stack(
            children: [
              Positioned.fill(
                top: widget.depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: edge, borderRadius: radius),
                ),
              ),
              AnimatedContainer(
                duration: motionTime(context, motionQuick),
                curve: Curves.easeOut,
                width: widget.expand ? double.infinity : null,
                margin: EdgeInsets.only(bottom: widget.depth),
                transform: Matrix4.translationValues(0, shift, 0),
                padding: widget.padding,
                foregroundDecoration: BoxDecoration(
                  borderRadius: radius,
                  border: focused ? Border.all(color: ink, width: 2) : null,
                ),
                decoration: BoxDecoration(
                  color: face,
                  gradient: enabled && widget.color == piko
                      ? brandGradient
                      : null,
                  borderRadius: radius,
                  border: widget.border == null
                      ? null
                      : Border.all(color: widget.border!, width: 2),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: enabled ? foregroundOn(face) : muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: .2,
                  ),
                  textAlign: TextAlign.center,
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: enabled ? foregroundOn(face) : muted,
                    ),
                    child: Center(
                      widthFactor: widget.expand ? null : 1,
                      heightFactor: 1,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mengecil sedikit saat ditekan, lalu memantul kembali.
class Bouncy extends StatefulWidget {
  const Bouncy({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.scale = .94,
  });

  final Widget child;
  final VoidCallback? onTap, onDoubleTap;
  final double scale;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool down = false;
  bool focused = false;
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onDoubleTap != null;
    return FocusableActionDetector(
      enabled: enabled,
      includeFocusSemantics: false,
      shortcuts: activationKeys,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowFocusHighlight: (value) => setState(() => focused = value),
      onShowHoverHighlight: (value) => setState(() => hovered = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: enabled ? true : null,
        focusable: enabled,
        focused: focused,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => down = true) : null,
          onTapCancel: enabled ? () => setState(() => down = false) : null,
          onTapUp: enabled ? (_) => setState(() => down = false) : null,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: AnimatedScale(
            scale: calm(context)
                ? 1
                : down
                ? widget.scale
                : hovered
                ? 1.015
                : 1,
            duration: motionTime(context, down ? motionQuick : motionPage),
            curve: down ? Curves.easeOut : motionCurve,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: focused ? Border.all(color: blue, width: 2) : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Muncul dari bawah dengan sedikit pantulan, bergiliran sesuai [index].
class Rise extends StatefulWidget {
  const Rise({super.key, required this.child, this.index = 0, this.from = 16});
  final Widget child;
  final int index;
  final double from;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: motionReveal,
  );
  late final curve = CurvedAnimation(parent: controller, curve: motionCurve);

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 35 * math.min(widget.index, 4));
    Future.delayed(delay, () {
      if (mounted) controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context)) controller.value = 1;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: curve,
    child: widget.child,
    builder: (context, child) => IgnorePointer(
      ignoring: controller.value < .15,
      child: Opacity(
        opacity: controller.value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - curve.value) * widget.from),
          child: child,
        ),
      ),
    ),
  );
}

/// Kotak abu yang berkilau selama data dimuat.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (context, child) => ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        final x = controller.value * 3 - 1;
        return LinearGradient(
          begin: Alignment(x - 1, -.3),
          end: Alignment(x + 1, .3),
          colors: const [
            Color(0xFFE9ECF7),
            Color(0xFFF8F9FE),
            Color(0xFFE9ECF7),
          ],
        ).createShader(bounds);
      },
      child: child,
    ),
  );
}

class Bone extends StatelessWidget {
  const Bone({super.key, this.width, required this.height, this.radius = 14});
  final double? width;
  final double height, radius;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE9ECF7),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Titik-titik kecil yang menyebar dari tengah. [progress] 0..1.
class BurstPainter extends CustomPainter {
  BurstPainter(this.progress, this.colors, {this.count = 8, this.reach = 1});
  final double progress;
  final List<Color> colors;
  final int count;
  final double reach;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final distance =
        size.shortestSide * .55 * reach * Curves.easeOut.transform(progress);
    final radius = (1 - progress) * size.shortestSide * .09;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count - math.pi / 2;
      final paint = Paint()..color = colors[i % colors.length];
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      if (i.isEven) {
        canvas.drawCircle(point, radius, paint);
      } else {
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle + progress * 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: radius * 2.6,
              height: radius * 1.2,
            ),
            Radius.circular(radius),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(BurstPainter old) => old.progress != progress;
}

/// Tombol ikon yang meletup saat diaktifkan.
class PopToggle extends StatefulWidget {
  const PopToggle({
    super.key,
    required this.active,
    required this.onTap,
    required this.builder,
    required this.label,
    this.colors = const [coral, yellow, piko, mint],
    this.size = 44,
  });

  final bool active;
  final VoidCallback onTap;
  final Widget Function(bool active) builder;
  final String label;
  final List<Color> colors;
  final double size;

  @override
  State<PopToggle> createState() => _PopToggleState();
}

class _PopToggleState extends State<PopToggle>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didUpdateWidget(PopToggle old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !calm(context)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: widget.active,
    label: widget.label,
    child: Bouncy(
      scale: .8,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = controller.value;
            final pop = t == 0
                ? 1.0
                : 1 + math.sin(t * math.pi) * .35 * (1 - t * .4);
            return CustomPaint(
              painter: BurstPainter(t, widget.colors),
              child: Center(
                child: Transform.scale(
                  scale: pop,
                  child: widget.builder(widget.active),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Hujan konfeti singkat untuk momen berhasil.
class Confetti extends StatefulWidget {
  const Confetti({super.key});
  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context)) controller.value = 1;
  }

  final random = math.Random(7);
  late final pieces = List.generate(
    46,
    (i) => (
      x: random.nextDouble(),
      delay: random.nextDouble() * .35,
      speed: .7 + random.nextDouble() * .6,
      spin: random.nextDouble() * 8 - 4,
      sway: random.nextDouble() * 2 * math.pi,
      color: const [coral, yellow, piko, mint, grape, tomato][i % 6],
      round: i % 3 == 0,
    ),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(controller.value, pieces),
      ),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.pieces);
  final double t;
  final List<
    ({
      double x,
      double delay,
      double speed,
      double spin,
      double sway,
      Color color,
      bool round,
    })
  >
  pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0) continue;
      final y = -20 + local * p.speed * (size.height + 60);
      final x = p.x * size.width + math.sin(local * 6 + p.sway) * 18;
      final paint = Paint()
        ..color = p.color.withValues(alpha: 1 - math.pow(local, 4).toDouble());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * p.spin * math.pi);
      if (p.round) {
        canvas.drawCircle(Offset.zero, 4.5, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-5, -3, 10, 6),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
