import 'package:flutter/material.dart';

import 'spot_icons.dart';

// Warna inti Spots. Biru, coral, dan kuning diambil dari logo.
const ink = Color(0xFF192553);
const blue = Color(0xFF4056BD);
const piko = Color(0xFF416CF4);
const pale = Color(0xFFF3F5FC);
const coral = Color(0xFFF27B8E);
const yellow = Color(0xFFF4C65F);
const muted = Color(0xFF64718E);
const line = Color(0xFFE2E6F5);
const mint = Color(0xFF2CC197);
const tomato = Color(0xFFFF6A4D);
const caramel = Color(0xFFF2A23A);
const grape = Color(0xFF8B6CF3);
const danger = Color(0xFFD9475E);

/// Warna tepi bawah untuk tombol "chunky".
Color edgeOf(Color color) => Color.lerp(color, ink, .28)!;

class SpotCategory {
  const SpotCategory(this.key, this.label, this.color, this.glyph);
  final String? key;
  final String label;
  final Color color;
  final Glyph glyph;
}

const allCategory = SpotCategory(null, 'Semua', piko, Glyph.sparkle);
const spotCategories = [
  SpotCategory('kuliner', 'Kuliner', tomato, Glyph.bowl),
  SpotCategory('kafe', 'Kafe', caramel, Glyph.cup),
  SpotCategory('destinasi', 'Destinasi', mint, Glyph.mountain),
];

SpotCategory categoryOf(String key) => spotCategories.firstWhere(
  (item) => item.key == key,
  orElse: () => spotCategories.last,
);

const fontBody = 'Nunito';
const fontDisplay = 'Bagel';

TextStyle display(double size, {Color color = ink, double height = 1.02}) =>
    TextStyle(
      fontFamily: fontDisplay,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: -.2,
    );

const title = TextStyle(
  fontSize: 19,
  fontWeight: FontWeight.w900,
  color: ink,
  letterSpacing: -.3,
  height: 1.2,
);

const small = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: muted,
);

ThemeData spotsTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: fontBody,
    scaffoldBackgroundColor: pale,
    colorScheme: ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      secondary: coral,
      surface: Colors.white,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    splashFactory: InkSparkle.splashFactory,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: const TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: line,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: piko),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: pale,
      hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w600),
      labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w700),
      floatingLabelStyle: const TextStyle(
        color: blue,
        fontWeight: FontWeight.w800,
      ),
      counterStyle: const TextStyle(color: muted, fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: line, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: line, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: piko, width: 2.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
