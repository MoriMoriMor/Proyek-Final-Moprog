import 'package:flutter_test/flutter_test.dart';
import 'package:spots/share.dart';
import 'package:spots/ui/mascots.dart';
import 'package:spots/ui/theme.dart';

void main() {
  test('tautan bagikan bisa dibaca kembali', () {
    final spot = parseIncoming(Uri.parse('https://spots.app/s/abc-123'));
    expect(spot?.kind, 's');
    expect(spot?.value, 'abc-123');
    expect(parseIncoming(Uri.parse('https://spots.app/t/toko9'))?.kind, 't');
    expect(
      parseIncoming(Uri.parse('https://x.dev/?invite=AB12CD'))?.value,
      'AB12CD',
    );
    expect(parseIncoming(Uri.parse('https://spots.app/')), isNull);
  });

  test('kode undangan pendek dan stabil', () {
    expect(inviteCode('1a2b3c4d-0000-0000-0000-000000000000'), '1A2B3C');
    expect(inviteCode('ab'), 'ABXXXX');
  });

  test('tujuh kategori, masing-masing punya maskot dan petunjuk', () {
    expect(spotCategories.length, 7);
    expect(spotCategories.every((c) => c.hint.isNotEmpty), isTrue);
    expect(spotCategories.map((c) => c.mascot).toSet().length, 7);
    expect(categoryOf('lainnya').key, 'belanja');
    expect(MascotKind.forCategory('olahraga'), MascotKind.bobi);
  });
}
