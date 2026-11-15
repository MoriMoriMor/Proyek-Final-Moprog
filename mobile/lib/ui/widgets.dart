import 'dart:ui';

import 'package:flutter/material.dart';

import 'motion.dart';
import 'piko.dart';
import 'spot_icons.dart';
import 'theme.dart';

/// Label kategori berbentuk stiker yang sedikit miring.
class CategorySticker extends StatelessWidget {
  const CategorySticker(this.category, {super.key, this.tilt = -.05});
  final SpotCategory category;
  final double tilt;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: tilt,
    child: Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 11, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink, width: 2),
        boxShadow: const [BoxShadow(color: ink, offset: Offset(2, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpotIcon(category.glyph, size: 17, accent: category.color),
          const SizedBox(width: 4),
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
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.fromLTRB(10, 9, 15, 9),
        decoration: BoxDecoration(
          color: active ? item.color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? edgeOf(item.color) : line,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: active ? edgeOf(item.color) : line,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpotIcon(
              item.glyph,
              size: 22,
              color: active ? Colors.white : ink,
              accent: active ? edgeOf(item.color) : item.color,
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
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

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = 38});
  final String name;
  final double size;

  static const _tones = [piko, coral, mint, caramel, grape, tomato];

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();
    final tone = _tones[name.hashCode.abs() % _tones.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(size * .38),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [BoxShadow(color: edgeOf(tone), offset: const Offset(0, 3))],
      ),
      child: Text(
        letter,
        style: display(size * .46, color: Colors.white, height: 1),
      ),
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
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              color: dark
                  ? ink.withValues(alpha: .35)
                  : Colors.white.withValues(alpha: .82),
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
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
    child: Row(
      children: [
        Expanded(child: Text(text, style: display(26))),
        ?trailing,
      ],
    ),
  );
}

void message(BuildContext context, String value) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
