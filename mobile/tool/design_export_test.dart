// Ekspor aset desain Spots ke SVG (logo, ikon, maskot, Apo) untuk Figma.
//
//   cd mobile
//   flutter test tool/design_export_test.dart
//
// Hasil ada di mobile/design/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/game.dart';
import 'package:spots/ui/mascots.dart';
import 'package:spots/ui/spot_icons.dart';
import 'package:spots/ui/theme.dart';

String hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
String n(double v) {
  final s = v.toStringAsFixed(2);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

/// Canvas yang mencatat gambar sebagai elemen SVG.
class SvgCanvas implements Canvas {
  final out = StringBuffer();
  final defs = StringBuffer();
  var _m = Matrix4.identity();
  final _stack = <(Matrix4, List<String>)>[];
  var _clips = <String>[];
  var _ids = 0;
  bool _shade = false;

  String get _tf {
    final s = _m.storage;
    return 'matrix(${n(s[0])} ${n(s[1])} ${n(s[4])} ${n(s[5])} ${n(s[12])} ${n(s[13])})';
  }

  String _style(Paint p) {
    final c = p.color;
    final a = c.a;
    if (p.shader != null) {
      _shade = true;
      return 'fill="url(#shade)"';
    }
    if (p.style == PaintingStyle.stroke) {
      final cap = switch (p.strokeCap) {
        StrokeCap.round => 'round',
        StrokeCap.square => 'square',
        _ => 'butt',
      };
      final join = switch (p.strokeJoin) {
        StrokeJoin.round => 'round',
        StrokeJoin.bevel => 'bevel',
        _ => 'miter',
      };
      return 'fill="none" stroke="${hex(c)}" stroke-width="${n(p.strokeWidth)}" '
          'stroke-linecap="$cap" stroke-linejoin="$join"'
          '${a < 1 ? ' stroke-opacity="${n(a)}"' : ''}';
    }
    return 'fill="${hex(c)}"${a < 1 ? ' fill-opacity="${n(a)}"' : ''}';
  }

  void _emit(String el, Paint p) {
    if (p.color.a == 0 && p.shader == null) return;
    var s = el.replaceFirst('/>', ' transform="$_tf" ${_style(p)}/>');
    for (final c in _clips.reversed) {
      s = '<g clip-path="url(#$c)">$s</g>';
    }
    out.writeln(s);
  }

  static String pathData(Path path) {
    final b = StringBuffer();
    for (final m in path.computeMetrics()) {
      final steps = math.max(8, (m.length / .7).ceil());
      for (var i = 0; i <= steps; i++) {
        final t = m.getTangentForOffset(m.length * i / steps);
        if (t == null) continue;
        b.write(
          '${i == 0 ? 'M' : 'L'}${n(t.position.dx)} ${n(t.position.dy)}',
        );
      }
      if (m.isClosed) b.write('Z');
    }
    return b.toString();
  }

  @override
  void save() => _stack.add((_m.clone(), List.of(_clips)));
  @override
  void saveLayer(Rect? bounds, Paint paint) => save();
  @override
  void restore() {
    if (_stack.isEmpty) return;
    final (m, c) = _stack.removeLast();
    _m = m;
    _clips = c;
  }

  @override
  int getSaveCount() => _stack.length + 1;
  @override
  void translate(double dx, double dy) => _m.translateByDouble(dx, dy, 0, 1);
  @override
  void scale(double sx, [double? sy]) =>
      _m.scaleByDouble(sx, sy ?? sx, 1, 1);
  @override
  void rotate(double radians) => _m.rotateZ(radians);
  @override
  void transform(Float64List matrix4) =>
      _m.multiply(Matrix4.fromFloat64List(matrix4));

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    final id = 'c${_ids++}';
    defs.writeln(
      '<clipPath id="$id"><path d="${pathData(path)}" transform="$_tf"/></clipPath>',
    );
    _clips.add(id);
  }

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) => clipPath(Path()..addRect(rect));
  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      clipPath(Path()..addRRect(rrect));

  @override
  void drawPath(Path path, Paint paint) =>
      _emit('<path d="${pathData(path)}"/>', paint);
  @override
  void drawCircle(Offset c, double radius, Paint paint) => _emit(
    '<circle cx="${n(c.dx)}" cy="${n(c.dy)}" r="${n(radius)}"/>',
    paint,
  );
  @override
  void drawOval(Rect r, Paint paint) => _emit(
    '<ellipse cx="${n(r.center.dx)}" cy="${n(r.center.dy)}" rx="${n(r.width / 2)}" ry="${n(r.height / 2)}"/>',
    paint,
  );
  @override
  void drawRect(Rect r, Paint paint) => _emit(
    '<rect x="${n(r.left)}" y="${n(r.top)}" width="${n(r.width)}" height="${n(r.height)}"/>',
    paint,
  );
  @override
  void drawRRect(RRect r, Paint paint) => drawPath(Path()..addRRect(r), paint);
  @override
  void drawLine(Offset a, Offset b, Paint paint) => _emit(
    '<line x1="${n(a.dx)}" y1="${n(a.dy)}" x2="${n(b.dx)}" y2="${n(b.dy)}"/>',
    paint,
  );
  @override
  void drawArc(
    Rect rect,
    double start,
    double sweep,
    bool useCenter,
    Paint paint,
  ) {
    final p = Path();
    if (useCenter) p.moveTo(rect.center.dx, rect.center.dy);
    p.arcTo(rect, start, sweep, !useCenter);
    if (useCenter) p.close();
    drawPath(p, paint);
  }

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) => drawPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(inner),
    paint,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  String svg(double size) {
    final shade = _shade
        ? '<linearGradient id="shade" x1="0" y1="0" x2="1" y2="1">'
              '<stop offset="0" stop-color="#fff" stop-opacity=".22"/>'
              '<stop offset=".5" stop-color="#fff" stop-opacity="0"/>'
              '<stop offset="1" stop-color="#000" stop-opacity=".14"/>'
              '</linearGradient>'
        : '';
    return '<svg xmlns="http://www.w3.org/2000/svg" width="${n(size)}" height="${n(size)}" viewBox="0 0 ${n(size)} ${n(size)}">\n'
        '<defs>$shade$defs</defs>\n$out</svg>\n';
  }
}

String paint(CustomPainter painter, double size) {
  final c = SvgCanvas();
  painter.paint(c, Size.square(size));
  return c.svg(size);
}

void main() {
  test('ekspor desain', () {
    final root = Directory('design')..createSync();
    void write(String path, String body) {
      final f = File('${root.path}/$path')..parent.createSync(recursive: true);
      f.writeAsStringSync(body);
    }

    for (final a in ['logo.svg', 'app_icon.svg', 'mascot.svg']) {
      write('logo/$a', File('assets/$a').readAsStringSync());
    }

    for (final g in Glyph.values) {
      write('icons/${g.name}.svg', g.svg(ink, yellow));
    }

    for (final kind in MascotKind.values) {
      for (final mood in MascotMood.values) {
        write(
          'maskot/${kind.name}/${kind.name}_${mood.name}.svg',
          paint(MascotPainter(kind: kind, mood: mood, still: true), 240),
        );
      }
      write(
        'maskot/${kind.name}/${kind.name}_lambai.svg',
        paint(
          MascotPainter(kind: kind, mood: MascotMood.happy, wave: true, still: true),
          240,
        ),
      );
    }

    for (final (i, tier) in flameTiers.indexed) {
      write(
        'apo/${i}_${tier.name.toLowerCase().replaceAll(' ', '_')}.svg',
        paint(ApoPainter(tier: tier, inner: tier.accent, t: 0), 240),
      );
    }

    final palette = {
      'ink': ink, 'blue': blue, 'coral': coral, 'yellow': yellow,
      'mint': mint, 'pale': pale, 'line': line, 'muted': muted,
    };
    final chips = StringBuffer();
    var x = 0;
    for (final e in palette.entries) {
      chips.write(
        '<g transform="translate($x 0)"><rect width="120" height="120" rx="24" fill="${hex(e.value)}" stroke="#e5e7f0" stroke-width="2"/>'
        '<text x="0" y="146" font-family="Nunito" font-weight="800" font-size="16" fill="#172657">${e.key}</text>'
        '<text x="0" y="166" font-family="Nunito" font-size="14" fill="#6b7290">${hex(e.value)}</text></g>',
      );
      x += 140;
    }
    write(
      'warna.svg',
      '<svg xmlns="http://www.w3.org/2000/svg" width="$x" height="180" viewBox="0 0 $x 180">$chips</svg>\n',
    );
  });
}
