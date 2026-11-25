import 'package:flutter/material.dart';

import 'mascots.dart';
import 'spot_icons.dart';

// Warna inti Spots. Biru, coral, dan kuning diambil dari logo.
const ink = Color(0xFF192553);
const blue = Color(0xFF4056BD);
const piko = Color(0xFF4068EC);
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

const lime = Color(0xFF8FD43A);
const sky = Color(0xFF3BB4E8);

const discoveryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFDCE8FF), Color(0xFFF3F7FF), Color(0xFFFCFBF8)],
  stops: [0, .58, 1],
);
const skyGlassGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFD6E6FF), Color(0xFFEEF4FF), Color(0xFFFFFFFF)],
  stops: [0, .52, 1],
);
const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F7BFF), piko, blue],
);
const marketGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFEFE2), Color(0xFFFFF8F2), pale],
);
const glassFill = Color(0xC9FFFFFF);
const glassStrong = Color(0xE3FFFFFF);
const glassBorder = Color(0xB8FFFFFF);
const darkGlassFill = Color(0xBD15204A);
const darkGlassBorder = Color(0x38FFFFFF);
const surfaceShadow = [
  BoxShadow(color: Color(0x10192553), blurRadius: 28, offset: Offset(0, 10)),
  BoxShadow(color: Color(0x06192553), blurRadius: 6, offset: Offset(0, 2)),
];

Color foregroundOn(Color color) {
  final luminance = color.computeLuminance();
  final whiteContrast = 1.05 / (luminance + .05);
  final inkContrast = (luminance + .05) / (ink.computeLuminance() + .05);
  if (whiteContrast >= 4.5) return Colors.white;
  return inkContrast >= 4.5 ? ink : Colors.black;
}

class SpotCategory {
  const SpotCategory(
    this.key,
    this.label,
    this.color,
    this.glyph,
    this.mascot, [
    this.hint = '',
  ]);
  final String? key;
  final String label;
  final Color color;
  final Glyph glyph;
  final MascotKind mascot;

  /// Contoh tempat, supaya orang tidak ragu memilih kategori.
  final String hint;
}

const allCategory = SpotCategory(
  null,
  'Semua',
  piko,
  Glyph.sparkle,
  MascotKind.piko,
);

/// Tujuh kategori besar. Kunci `kafe` dan `destinasi` dipertahankan
/// supaya data lama tetap cocok; labelnya yang berubah.
const spotCategories = [
  SpotCategory(
    'kuliner',
    'Kuliner',
    tomato,
    Glyph.bowl,
    MascotKind.mimi,
    'Resto, warung, jajanan, street food',
  ),
  SpotCategory(
    'kafe',
    'Nongkrong',
    caramel,
    Glyph.cup,
    MascotKind.jojo,
    'Kafe, taman, rooftop, spot sunset',
  ),
  SpotCategory(
    'destinasi',
    'Wisata',
    mint,
    Glyph.mountain,
    MascotKind.gugu,
    'Alam, pantai, museum, seni & budaya',
  ),
  SpotCategory(
    'olahraga',
    'Olahraga',
    lime,
    Glyph.ball,
    MascotKind.bobi,
    'Lapangan, skatepark, jogging track, gym',
  ),
  SpotCategory(
    'aktivitas',
    'Aktivitas',
    grape,
    Glyph.ticket,
    MascotKind.tika,
    'Workshop, karaoke, arcade, kelas seru',
  ),
  SpotCategory(
    'belanja',
    'Belanja',
    yellow,
    Glyph.bag,
    MascotKind.tote,
    'Thrift, pasar, toko lokal, oleh-oleh',
  ),
  SpotCategory(
    'menginap',
    'Menginap',
    sky,
    Glyph.house,
    MascotKind.rumi,
    'Glamping, villa, homestay unik',
  ),
];

SpotCategory categoryOf(String key) => spotCategories.firstWhere(
  (item) => item.key == (key == 'lainnya' ? 'belanja' : key),
  orElse: () => spotCategories[2],
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
    appBarTheme: const AppBarTheme(
      backgroundColor: pale,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(fontFamily: fontBody, color: Colors.white),
    ),
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
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w600),
      labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w700),
      floatingLabelStyle: const TextStyle(
        color: blue,
        fontWeight: FontWeight.w800,
      ),
      counterStyle: const TextStyle(color: muted, fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: blue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
