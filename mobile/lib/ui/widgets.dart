import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'motion.dart';
import 'piko.dart';
import 'spot_icons.dart';
import 'theme.dart';

/// Permukaan kaca buram (frosted glass) ala iOS untuk bilah apung dan lencana.
/// Otomatis menjadi lebih pekat tanpa blur saat mode reduced motion aktif.
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.sigma = 18,
    this.padding,
    this.dark = false,
    this.fill,
    this.borderColor,
    this.shadows = surfaceShadow,
  });

  final Widget child;
  final double radius, sigma;
  final EdgeInsetsGeometry? padding;
  final bool dark;
  final Color? fill, borderColor;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final reduced = calm(context);
    final bg =
        fill ??
        (dark
            ? (reduced ? const Color(0xEB15204A) : darkGlassFill)
            : (reduced ? Colors.white.withValues(alpha: .96) : glassFill));
    final rim = borderColor ?? (dark ? darkGlassBorder : glassBorder);
    final r = BorderRadius.circular(radius);
    Widget box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: r,
        border: Border.all(color: rim, width: 1.2),
      ),
      child: child,
    );
    if (!reduced && sigma > 0) {
      box = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: box,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: shadows),
      child: ClipRRect(borderRadius: r, child: box),
    );
  }
}

/// Animasi pemuatan bersih hanya dengan tulisan "spots." dan garis progres halus.
class SpotsLogoLoader extends StatefulWidget {
  const SpotsLogoLoader({super.key, this.compact = false});
  final bool compact;

  @override
  State<SpotsLogoLoader> createState() => _SpotsLogoLoaderState();
}

class _SpotsLogoLoaderState extends State<SpotsLogoLoader>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context) || !TickerMode.valuesOf(context).enabled) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.compact ? 30.0 : 38.0;
    return RepaintBoundary(
      child: Semantics(
        label: 'Memuat Spots',
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final v = Curves.easeInOutSine.transform(controller.value);
            final barX = calm(context) ? 0.0 : (v * 2 - 1) * .74;
            final dotScale = calm(context) ? 1.0 : .9 + v * .22;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'spots',
                      style: display(fontSize, color: ink, height: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 3,
                        bottom: fontSize * .18,
                      ),
                      child: Transform.scale(
                        scale: dotScale,
                        child: Container(
                          width: fontSize * .24,
                          height: fontSize * .24,
                          decoration: const BoxDecoration(
                            color: coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: 88,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: blue.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment(barX, 0),
                  child: Container(
                    width: 36,
                    height: 3.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(colors: [piko, coral]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Label kategori berbentuk stiker kaca buram yang rapi di atas foto.
class CategorySticker extends StatelessWidget {
  const CategorySticker(this.category, {super.key, this.tilt = -.02});
  final SpotCategory category;
  final double tilt;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: tilt,
    child: FrostedSurface(
      radius: 15,
      sigma: 14,
      fill: glassStrong,
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpotIcon(category.glyph, size: 17, accent: category.color),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: ink,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Pilihan kategori yang bisa digulir ke samping.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.selected,
    required this.onSelected,
    this.includeAll = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool includeAll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final items = [if (includeAll) allCategory, ...spotCategories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 6),
              child: _CategoryChip(
                item: item,
                active: selected == item.key,
                onTap: () => onSelected(item.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.item,
    required this.active,
    required this.onTap,
  });
  final SpotCategory item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: active,
    button: true,
    label: item.label,
    child: Bouncy(
      onTap: onTap,
      child: AnimatedContainer(
        duration: motionTime(context, motionPage),
        curve: motionCurve,
        padding: const EdgeInsets.fromLTRB(12, 11, 16, 11),
        decoration: BoxDecoration(
          color: active ? blue : glassStrong,
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF62A2FF), Color(0xFF3B76F6)],
                )
              : null,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? Colors.white.withValues(alpha: .42) : glassBorder,
            width: 1.3,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x2E3B76F6),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : surfaceShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpotIcon(
              item.glyph,
              size: 20,
              color: active ? Colors.white : ink,
              accent: active ? Colors.white : piko,
              tint: !active,
            ),
            const SizedBox(width: 7),
            Text(
              item.label,
              style: TextStyle(
                fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                fontSize: 14,
                color: active ? Colors.white : ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Petunjuk singkat isi kategori yang sedang dipilih.
class CategoryHint extends StatelessWidget {
  const CategoryHint(this.category, {super.key});
  final String? category;
  @override
  Widget build(BuildContext context) {
    final hint = category == null ? '' : categoryOf(category!).hint;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: hint.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              key: ValueKey(hint),
              padding: const EdgeInsets.only(top: 8),
              child: Text(hint, style: small.copyWith(fontSize: 12.5)),
            ),
    );
  }
}

/// Gambar yang hanya ada di memori (dipakai mode demo), dengan kunci `mem:...`.
final memoryImages = <String, Uint8List>{};

/// Ukuran foto tetap selama dimuat, dengan resolusi sesuai layar.
class SpotImage extends StatelessWidget {
  const SpotImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
  });
  final String url;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth ? constraints.maxWidth : 640.0;
      final decodeWidth = (width * MediaQuery.devicePixelRatioOf(context))
          .round()
          .clamp(64, 1600);
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: decodeWidth,
        fit: fit,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, synchronous) {
          if (synchronous) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: pale),
              AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: motionTime(context, motionPage),
                curve: motionCurve,
                child: child,
              ),
            ],
          );
        },
        errorBuilder: (_, _, _) => fallback,
      );
    },
  );
}

class VideoUnavailable extends StatelessWidget {
  const VideoUnavailable({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpotIcon(Glyph.video, color: Colors.white, size: 32, tint: false),
        SizedBox(height: 12),
        Text(
          'Video tidak tersedia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// Latar berwarna yang dicat terpisah dari konten.
class SpotsBackdrop extends StatelessWidget {
  const SpotsBackdrop({super.key, required this.child, this.market = false});
  final Widget child;
  final bool market;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .72, end: 1),
              duration: motionTime(context, const Duration(milliseconds: 900)),
              curve: motionCurve,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: market ? marketGradient : discoveryGradient,
                ),
                child: CustomPaint(painter: _BackdropLines(market)),
              ),
              builder: (_, value, child) =>
                  Opacity(opacity: value, child: child),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _BackdropLines extends CustomPainter {
  const _BackdropLines(this.market);
  final bool market;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          (market ? const Color(0xFFFFD8C2) : const Color(0xFFB7D6FF))
              .withValues(alpha: .42),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .84, 88),
          radius: size.shortestSide * .55,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * .84, 88),
      size.shortestSide * .55,
      glow,
    );
    final cloud = Paint()..color = Colors.white.withValues(alpha: .52);
    canvas.drawCircle(Offset(size.width * .18, 128), 64, cloud);
    canvas.drawCircle(Offset(size.width * .26, 136), 48, cloud);
    canvas.drawCircle(Offset(size.width * .78, 210), 58, cloud);
  }

  @override
  bool shouldRepaint(_BackdropLines old) => old.market != market;
}

class Avatar extends StatelessWidget {
  const Avatar(
    this.name, {
    super.key,
    this.size = 38,
    this.url,
    this.ring = false,
  });
  final String name;
  final double size;

  /// Alamat foto profil. Kosong berarti tampil huruf awal nama.
  final String? url;

  /// Cincin warna-warni seperti profil Spots.
  final bool ring;

  static const _tones = [piko, coral, mint, caramel, grape, tomato];

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();
    final tone = _tones[name.hashCode.abs() % _tones.length];
    final radius = BorderRadius.circular(size * .38);
    final source = url;
    final initials = Text(
      letter,
      style: display(size * .46, color: Colors.white, height: 1),
    );
    Widget face = initials;
    if (source != null && source.isNotEmpty) {
      final bytes = memoryImages[source];
      face = ClipRRect(
        borderRadius: radius,
        child: bytes != null
            ? Image.memory(bytes, width: size, height: size, fit: BoxFit.cover)
            : Image.network(
                source,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => Center(child: initials),
              ),
      );
    }
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone,
        borderRadius: radius,
        border: Border.all(color: Colors.white, width: size > 60 ? 3.5 : 2),
        boxShadow: ring
            ? null
            : [
                BoxShadow(
                  color: tone.withValues(alpha: .26),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: face,
    );
    if (!ring) return tile;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .44),
        gradient: const SweepGradient(
          colors: [Color(0xFF5B9BFF), piko, coral, Color(0xFF7CC4FF), Color(0xFF5B9BFF)],
        ),
      ),
      child: tile,
    );
  }
}

/// Tombol bulat transparan untuk diletakkan di atas foto atau peta.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.glyph,
    required this.onTap,
    required this.label,
    this.dark = false,
  });
  final Glyph glyph;
  final VoidCallback onTap;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: Bouncy(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: calm(context) ? 0 : 16,
              sigmaY: calm(context) ? 0 : 16,
            ),
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark
                    ? ink.withValues(alpha: .46)
                    : Colors.white.withValues(alpha: .82),
                border: Border.all(
                  color: dark ? darkGlassBorder : glassBorder,
                  width: 1.2,
                ),
              ),
              child: SpotIcon(
                glyph,
                size: 23,
                color: dark ? Colors.white : ink,
                tint: false,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(40),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      child: child,
    ),
  );
}

/// Kotak pesan singkat untuk galat.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEEF0),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFD2D8), width: 2),
    ),
    child: Row(
      children: [
        const Piko(size: 30, mood: PikoMood.wow, bounce: false),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF8E2C3C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Coba lagi',
              style: TextStyle(fontWeight: FontWeight.w900, color: danger),
            ),
          ),
      ],
    ),
  );
}

/// Keadaan kosong: Piko, satu kalimat, satu tombol.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.mood = PikoMood.sleepy,
    this.color = piko,
    this.kind = MascotKind.piko,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final PikoMood mood;
  final Color color;
  final MascotKind kind;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Piko(size: 120, mood: mood, kind: kind, wave: action != null),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: display(24, height: 1.1),
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            Chunky(onTap: onAction, color: color, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: title.copyWith(fontSize: 22, letterSpacing: -.6),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

void message(BuildContext context, String value) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
