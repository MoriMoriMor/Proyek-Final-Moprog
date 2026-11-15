import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ikon Spots digambar sendiri: garis tebal membulat dengan blok warna
/// yang sedikit bergeser, seperti cetakan sablon yang meleset.
/// `INK` dan `ACC` diganti warna saat dirender.
enum Glyph {
  home(
    '<path d="M4 11 12 4.4l8 6.6v8a1.6 1.6 0 0 1-1.6 1.6H15v-5.4H9v5.4H5.6A1.6 1.6 0 0 1 4 19z"/>',
  ),
  compass(
    '<circle cx="12" cy="12" r="8.4"/>',
    extra: '<path d="M15.3 8.7 13.4 13.4 8.7 15.3l1.9-4.7z" fill="INK" stroke="INK" stroke-width="1.4" stroke-linejoin="round"/>',
  ),
  map(
    '<path d="M3.6 6.6 9 4.6l6 2 5.4-2v12.8l-5.4 2-6-2-5.4 2z"/><path d="M9 4.6v12.8M15 6.6v12.8"/>',
    fill: '<path d="M3.6 6.6 9 4.6l6 2 5.4-2v12.8l-5.4 2-6-2-5.4 2z"/>',
  ),
  bookmark('<path d="M6.6 4.4h10.8v15.8L12 16.4l-5.4 3.8z"/>'),
  face(
    '<path d="M7.4 8.6c-.7-2.4-.4-4.3.8-4.6 1.2-.3 2.4 1.1 3.1 2.6h1.4c.7-1.5 1.9-2.9 3.1-2.6 1.2.3 1.5 2.2.8 4.6 1.7 1.3 2.8 3.2 2.8 5.5 0 4.1-3.4 6.4-7.4 6.4s-7.4-2.3-7.4-6.4c0-2.3 1.1-4.2 2.8-5.5z"/>',
    extra: '<circle cx="9.6" cy="13.4" r="1.25" fill="INK" stroke="none"/><circle cx="14.4" cy="13.4" r="1.25" fill="INK" stroke="none"/>',
  ),
  plus('<path d="M12 5v14M5 12h14"/>', fill: ''),
  heart(
    '<path d="M12 19.8s-7.6-4.5-7.6-10A4.3 4.3 0 0 1 12 7.2a4.3 4.3 0 0 1 7.6 2.6c0 5.5-7.6 10-7.6 10z"/>',
  ),
  chat(
    '<path d="M5.2 5.2h13.6a1.6 1.6 0 0 1 1.6 1.6v8.6a1.6 1.6 0 0 1-1.6 1.6h-7.4l-4.6 3.4V17H5.2a1.6 1.6 0 0 1-1.6-1.6V6.8a1.6 1.6 0 0 1 1.6-1.6z"/>',
  ),
  star(
    '<path d="m12 3.8 2.5 5.1 5.6.8-4 4 .9 5.5-5-2.6-5 2.6.9-5.5-4-4 5.6-.8z"/>',
  ),
  pin(
    '<path d="M12 21s-6.6-6-6.6-11.1a6.6 6.6 0 0 1 13.2 0C18.6 15 12 21 12 21z"/>',
    extra: '<circle cx="12" cy="9.9" r="2.3"/>',
  ),
  send(
    '<path d="M4 11.4 20.2 4l-6.6 16.2-2.6-6.3z"/><path d="M11 13.9 20.2 4"/>',
    fill: '<path d="M4 11.4 20.2 4l-6.6 16.2-2.6-6.3z"/>',
  ),
  camera(
    '<path d="M3.8 8.6A1.6 1.6 0 0 1 5.4 7h2.4l1.6-2.3h5.2L16.2 7h2.4a1.6 1.6 0 0 1 1.6 1.6v9a1.6 1.6 0 0 1-1.6 1.6H5.4a1.6 1.6 0 0 1-1.6-1.6z"/>',
    extra: '<circle cx="12" cy="13" r="3.4"/>',
  ),
  gallery(
    '<rect x="3.8" y="4.8" width="16.4" height="14.4" rx="2.4"/>',
    extra: '<path d="m4 16.2 4.6-4.6 4 4 2.5-2.5 4.9 4.9"/><circle cx="15.6" cy="9.4" r="1.5" fill="INK" stroke="none"/>',
  ),
  video(
    '<rect x="3.4" y="6.4" width="12" height="11.2" rx="2.4"/><path d="m15.4 10.6 5.2-3v8.8l-5.2-3z"/>',
    fill: '<rect x="3.4" y="6.4" width="12" height="11.2" rx="2.4"/>',
  ),
  record(
    '<rect x="3.4" y="6.4" width="12" height="11.2" rx="2.4"/><path d="m15.4 10.6 5.2-3v8.8l-5.2-3z"/>',
    fill: '<rect x="3.4" y="6.4" width="12" height="11.2" rx="2.4"/>',
    extra: '<circle cx="9.4" cy="12" r="2" fill="INK" stroke="none"/>',
  ),
  locate(
    '<circle cx="12" cy="12" r="6.4"/>',
    extra: '<path d="M12 2.8v3M12 18.2v3M2.8 12h3M18.2 12h3"/><circle cx="12" cy="12" r="2" fill="INK" stroke="none"/>',
  ),
  search(
    '<circle cx="10.6" cy="10.6" r="6.2"/>',
    extra: '<path d="m15.2 15.2 4.8 4.8"/>',
  ),
  exit(
    '<path d="M13.6 4.4H7a1.6 1.6 0 0 0-1.6 1.6v12a1.6 1.6 0 0 0 1.6 1.6h6.6"/>',
    fill: '<path d="M5.4 4.4h8.2v15.2H5.4z"/>',
    extra: '<path d="M11 12h9.4m-3-3.2 3.2 3.2-3.2 3.2"/>',
  ),
  route(
    '<path d="M12 3.4 20.6 12 12 20.6 3.4 12z"/>',
    extra: '<path d="M9.6 14.4v-2.6a1.2 1.2 0 0 1 1.2-1.2h4.2m-2.2-2.2 2.2 2.2-2.2 2.2"/>',
  ),
  close('<path d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>', fill: ''),
  back('<path d="M14.8 5.6 8.4 12l6.4 6.4"/>', fill: ''),
  bowl(
    '<path d="M3.4 11.6h17.2a8.6 8.6 0 0 1-17.2 0z"/>',
    extra: '<path d="M14.2 9.2 20 3.6M11.6 9.2l5.2-5.6"/><path d="M7.6 4.4c-1 1.2 1 2.1 0 3.6"/>',
  ),
  cup(
    '<path d="M5 8.6h11v5.4a5 5 0 0 1-5 5h-1a5 5 0 0 1-5-5z"/>',
    extra: '<path d="M16 10.2h1.4a2.3 2.3 0 0 1 0 4.6H16M8.4 3.6c-.9 1.1.9 1.8 0 3.1M12.4 3.6c-.9 1.1.9 1.8 0 3.1"/>',
  ),
  mountain(
    '<path d="M2.6 19.4 9 8.6l4 6.6 2.4-3.4 6 7.6z"/>',
    extra: '<circle cx="17.4" cy="6.4" r="2.1"/>',
  ),
  sparkle(
    '<path d="M12 3.2c.7 4.4 2.9 6.6 7.3 7.3-4.4.7-6.6 2.9-7.3 7.3-.7-4.4-2.9-6.6-7.3-7.3 4.4-.7 6.6-2.9 7.3-7.3z"/>',
    extra: '<circle cx="19" cy="18.6" r="1.4" fill="INK" stroke="none"/>',
  ),
  fire(
    '<path d="M12 20.6c-3.9 0-6.4-2.6-6.4-6 0-3.7 3.1-5.4 3.5-9.4 2.7 1.6 3.4 3.8 3.4 5.4 1-.6 1.6-1.8 1.7-3 2.4 1.8 4.2 4.2 4.2 7 0 3.4-2.5 6-6.4 6z"/>',
  ),
  pencil('<path d="M15.6 4.6a2.1 2.1 0 0 1 3 3L8.4 17.8l-4.2 1.2 1.2-4.2z"/>'),
  play('<path d="M8 5.4v13.2L18.4 12z"/>');

  const Glyph(this.outline, {this.fill, this.extra = ''});

  final String outline;
  final String? fill;
  final String extra;

  String svg(Color stroke, Color accent, {bool tint = true}) {
    final shape = fill ?? outline;
    final inkHex = _hex(stroke);
    final shadow = tint && shape.isNotEmpty
        ? '<g transform="translate(1.5 1.7)" fill="${_hex(accent)}" stroke="none">$shape</g>'
        : '';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '$shadow<g fill="none" stroke="$inkHex" stroke-width="2.1" '
        'stroke-linecap="round" stroke-linejoin="round">'
        '$outline${extra.replaceAll('INK', inkHex)}</g></svg>';
  }
}

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

class SpotIcon extends StatelessWidget {
  const SpotIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color = const Color(0xFF192553),
    this.accent = const Color(0xFFF4C65F),
    this.tint = true,
    this.label,
  });

  final Glyph glyph;
  final double size;
  final Color color, accent;
  final bool tint;
  final String? label;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    glyph.svg(color, accent, tint: tint),
    width: size,
    height: size,
    semanticsLabel: label,
    excludeFromSemantics: label == null,
  );
}
