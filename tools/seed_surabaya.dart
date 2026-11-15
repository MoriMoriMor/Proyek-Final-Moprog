// Isi 10 spot asli di Surabaya untuk akun kamu sendiri.
//
//   dart run tools/seed_surabaya.dart rara
//
// "rara" = username Spots kamu. Script mencari foto publik di Wikimedia
// Commons, lalu menulis supabase/seed/surabaya.sql. Buka file itu,
// salin ke Supabase SQL Editor, Run. Aman diulang.
import 'dart:convert';
import 'dart:io';

class Place {
  const Place(this.title, this.category, this.lat, this.lng, this.story,
      this.queries);
  final String title, category, story;
  final double lat, lng;
  final List<String> queries;
}

const places = [
  Place(
    'Rawon Setan Mbak Endang',
    'kuliner',
    -7.26140,
    112.73860,
    'Rawonnya hitam pekat, dagingnya empuk, sambalnya jangan diremehkan. '
        'Paling enak datang malam, sekalian lihat antreannya yang nggak ada habisnya. '
        'Tambah telur asin sama kerupuk udang, wajib.',
    ['Rawon Setan Surabaya', 'rawon Surabaya', 'rawon'],
  ),
  Place(
    'Sate Klopo Ondomohen',
    'kuliner',
    -7.25850,
    112.74710,
    'Satenya dibalur kelapa parut sebelum dibakar, jadi gurih dan agak garing di luar. '
        'Asapnya kecium dari ujung jalan. Pesan campur sapi + ayam biar nggak bingung.',
    ['Sate Klopo Ondomohen', 'sate klopo', 'sate Surabaya'],
  ),
  Place(
    'Taman Bungkul',
    'kafe',
    -7.29130,
    112.73980,
    'Tempat nongkrong sejuta umat. Sore-sore duduk di bawah pohon, jajan di sentra PKL '
        'belakang, terus jalan muter taman. Minggu pagi rame banget sama yang olahraga.',
    ['Taman Bungkul', 'Bungkul park Surabaya'],
  ),
  Place(
    'Tugu Pahlawan',
    'destinasi',
    -7.24580,
    112.73780,
    'Ikonnya Surabaya. Di bawah tanahnya ada Museum 10 Nopember, isinya lumayan bikin '
        'merinding. Datang pas sore biar foto tugunya kena cahaya hangat.',
    ['Tugu Pahlawan Surabaya', 'Heroes Monument Surabaya'],
  ),
  Place(
    'House of Sampoerna',
    'destinasi',
    -7.23100,
    112.73420,
    'Bangunan kolonialnya cakep dari luar sampai dalam. Masuk museumnya gratis, '
        'dan dari lantai atas bisa lihat proses linting kretek. Kawasan kota lamanya enak buat jalan kaki.',
    ['House of Sampoerna', 'House of Sampoerna Surabaya'],
  ),
  Place(
    'Gelora Bung Tomo',
    'olahraga',
    -7.22450,
    112.62300,
    'Kandangnya Persebaya. Kalau lagi nggak ada pertandingan, area luarnya sering dipakai '
        'lari sore sama sepedaan. Pas ada laga, suasananya beda level.',
    ['Gelora Bung Tomo', 'Gelora Bung Tomo Stadium'],
  ),
  Place(
    'Monumen Kapal Selam',
    'aktivitas',
    -7.26530,
    112.75020,
    'Kapal selam beneran yang bisa dimasukin, dari ruang torpedo sampai ruang kemudi. '
        'Sempit, panas, tapi seru. Cocok buat bawa adik atau ponakan.',
    ['Monumen Kapal Selam', 'KRI Pasopati Surabaya'],
  ),
  Place(
    'Kebun Binatang Surabaya',
    'aktivitas',
    -7.29590,
    112.73650,
    'Klasik, tapi tetap asik buat jalan pagi. Sapa komodonya, terus foto di patung '
        'Suro dan Boyo di depan. Datang lebih awal biar belum terlalu terik.',
    ['Kebun Binatang Surabaya', 'Surabaya Zoo'],
  ),
  Place(
    'Pasar Atom',
    'belanja',
    -7.24000,
    112.74280,
    'Surganya kain, jajanan, sama barang serba ada. Lantai bawah buat camilan, '
        'lantai atas buat bahan baju. Siap-siap nawar dan siap-siap nyasar.',
    ['Pasar Atom Surabaya', 'Pasar Atom', 'Tunjungan Plaza'],
  ),
  Place(
    'Hotel Majapahit',
    'menginap',
    -7.26040,
    112.73920,
    'Hotel bersejarah di Jalan Tunjungan, tempat insiden perobekan bendera tahun 1945. '
        'Taman dalamnya tenang banget, kayak lupa lagi di tengah kota. Malamnya tinggal jalan ke Tunjungan.',
    ['Hotel Majapahit Surabaya', 'Hotel Majapahit', 'Hotel Yamato Surabaya'],
  ),
];

final client = HttpClient()..userAgent = 'spots-seed/1.0 (student project)';

Future<List<Map<String, String>>> photos(List<String> queries) async {
  for (final q in queries) {
    final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'generator': 'search',
      'gsrnamespace': '6',
      'gsrlimit': '8',
      'gsrsearch': '$q filetype:bitmap',
      'prop': 'imageinfo',
      'iiprop': 'url|mime|extmetadata',
      'iiurlwidth': '1080',
    });
    final req = await client.getUrl(uri);
    final res = await req.close();
    final body = jsonDecode(await res.transform(utf8.decoder).join()) as Map;
    final pages = ((body['query'] as Map?)?['pages'] as Map?)?.values ?? [];
    final found = <Map<String, String>>[];
    for (final p in (pages.toList()
      ..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int)))) {
      final info = (p['imageinfo'] as List).first as Map;
      if (info['mime'] != 'image/jpeg') continue;
      final meta = (info['extmetadata'] as Map?) ?? {};
      String plain(String k) =>
          ((meta[k] as Map?)?['value'] as String? ?? '')
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
      found.add({
        'url': info['thumburl'] as String,
        'author': plain('Artist'),
        'license': plain('LicenseShortName'),
      });
      if (found.length == 2) break;
    }
    if (found.isNotEmpty) return found;
  }
  return [];
}

String sql(String v) => "'${v.replaceAll("'", "''")}'";

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Pakai: dart run tools/seed_surabaya.dart <username>');
    exit(64);
  }
  final username = args.first.replaceFirst('@', '').toLowerCase();
  final out = StringBuffer()
    ..writeln('-- 10 spot Surabaya untuk @$username. Aman dijalankan ulang.')
    ..writeln('do \$\$')
    ..writeln('declare me uuid; pid uuid;')
    ..writeln('begin')
    ..writeln('  select id into me from public.profiles where username = ${sql(username)};')
    ..writeln("  if me is null then raise exception 'Username @$username belum ada'; end if;");
  for (final place in places) {
    final pics = await photos(place.queries);
    if (pics.isEmpty) {
      stdout.writeln('lewati ${place.title}: foto tidak ketemu');
      continue;
    }
    final credit = pics
        .map((p) => p['author']!.isEmpty ? p['license']! : p['author']!)
        .toSet()
        .join(', ');
    final story = '${place.story}\n\nFoto: $credit (Wikimedia Commons)';
    stdout.writeln('ok   ${place.title} (${pics.length} foto)');
    out
      ..writeln('  delete from public.posts where owner_id = me and title = ${sql(place.title)};')
      ..writeln('  insert into public.posts (owner_id, title, city, category, story, lat, lng)')
      ..writeln("  values (me, ${sql(place.title)}, 'Surabaya', ${sql(place.category)}, ${sql(story)}, ${place.lat}, ${place.lng})")
      ..writeln('  returning id into pid;');
    for (final (i, p) in pics.indexed) {
      out.writeln("  insert into public.post_media (post_id, position, storage_path, media_type) values (pid, $i, ${sql(p['url']!)}, 'image');");
    }
  }
  out
    ..writeln('end')
    ..writeln('\$\$;');
  final file = File('supabase/seed/surabaya.sql');
  await file.parent.create(recursive: true);
  await file.writeAsString(out.toString());
  client.close();
  stdout.writeln('\nSelesai: ${file.path}. Salin isinya ke Supabase SQL Editor lalu Run.');
}
