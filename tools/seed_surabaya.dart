// Isi Spots dengan 10 spot asli di Surabaya, diunggah oleh 6 akun warga.
//
//   dart run tools/seed_surabaya.dart
//
// Script mencari foto publik di Wikimedia Commons, lalu menulis
// supabase/seed/surabaya.sql. Salin isinya ke Supabase SQL Editor, Run.
// Aman diulang. Akun-akun ini tidak bisa dipakai login (tanpa password).
import 'dart:convert';
import 'dart:io';

class Person {
  const Person(this.n, this.username, this.name, this.bio, this.streak);
  final int n, streak;
  final String username, name, bio;
  String get id => 'a5b0c000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
}

const people = [
  Person(1, 'nadiamakan', 'Nadia Putri', 'kalau lapar, tanya aku 🍜 sby', 41),
  Person(2, 'dimas.jalan', 'Dimas Arya', 'suka bangunan tua & jalan kaki', 17),
  Person(
    3,
    'rara.sby',
    'Rara Ayu',
    'anak tunjungan. belanja dulu, mikir belakangan',
    9,
  ),
  Person(
    4,
    'bayulari',
    'Bayu Pratama',
    '5K tiap sore, persebaya tiap minggu',
    63,
  ),
  Person(5, 'sekarwulan', 'Sekar Wulan', 'ngajak ponakan keliling kota', 5),
  Person(6, 'fajarngopi', 'Fajar', 'nongkrong itu ibadah', 120),
];

// [pemilik, hari lalu] untuk tiap spot sesuai urutan di bawah.
const owners = [
  [1, 2],
  [1, 9],
  [6, 1],
  [2, 14],
  [2, 6],
  [4, 3],
  [5, 11],
  [5, 4],
  [3, 8],
  [3, 18],
];

const comments = [
  'sambalnya pedes beneran wkwk',
  'besok ke sini ah',
  'baru tau ada ini',
  'fotonya bikin pengen',
  'langganan dari SMA 😭',
  'parkirnya gampang ga?',
  'minggu lalu ke sini, rame bgt',
  'wajib nyoba',
];

class Place {
  const Place(
    this.title,
    this.category,
    this.lat,
    this.lng,
    this.story,
    this.queries,
  );
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
    for (final p
        in (pages.toList()
          ..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int)))) {
      final info = (p['imageinfo'] as List).first as Map;
      if (info['mime'] != 'image/jpeg') continue;
      final meta = (info['extmetadata'] as Map?) ?? {};
      String plain(String k) => ((meta[k] as Map?)?['value'] as String? ?? '')
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

Future<void> main() async {
  final ids = people.map((p) => "'${p.id}'").join(', ');
  final out = StringBuffer()
    ..writeln('-- Spot Surabaya + 6 akun warga. Aman dijalankan ulang.')
    ..writeln('do \$\$')
    ..writeln('declare pid uuid; posts uuid[] := array[]::uuid[];')
    ..writeln('begin');
  for (final p in people) {
    out
      ..writeln(
        "  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)",
      )
      ..writeln(
        "  values ('00000000-0000-0000-0000-000000000000', '${p.id}', 'authenticated', 'authenticated', '${p.username}@seed.spots.local', '', '{\"provider\":\"email\",\"providers\":[\"email\"]}', jsonb_build_object('display_name', ${sql(p.name)}), now() - interval '${30 + p.n * 7} days', now())",
      )
      ..writeln('  on conflict (id) do nothing;')
      ..writeln(
        "  update public.profiles set username = ${sql(p.username)}, display_name = ${sql(p.name)}, bio = ${sql(p.bio)}, streak = ${p.streak}, best_streak = ${p.streak}, streak_day = current_date, created_at = now() - interval '${30 + p.n * 7} days' where id = '${p.id}';",
      );
  }
  out.writeln('  delete from public.posts where owner_id in ($ids);');
  for (final (n, place) in places.indexed) {
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
    final owner = people[owners[n][0] - 1];
    final ago = owners[n][1];
    stdout.writeln(
      'ok   ${place.title} (${pics.length} foto) oleh @${owner.username}',
    );
    out
      ..writeln(
        '  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)',
      )
      ..writeln(
        "  values ('${owner.id}', ${sql(place.title)}, 'Surabaya', ${sql(place.category)}, ${sql(story)}, ${place.lat}, ${place.lng}, now() - interval '$ago days ${n * 3 + 2} hours')",
      )
      ..writeln('  returning id into pid;')
      ..writeln('  posts := posts || pid;');
    for (final (i, p) in pics.indexed) {
      out.writeln(
        "  insert into public.post_media (post_id, position, storage_path, media_type) values (pid, $i, ${sql(p['url']!)}, 'image');",
      );
    }
    // Reaksi dari akun lain supaya terlihat hidup.
    for (final fan in people) {
      if (fan == owner) continue;
      final k = (fan.n * 7 + n * 3) % 10;
      if (k < 7)
        out.writeln(
          "  insert into public.reactions (user_id, post_id, kind) values ('${fan.id}', pid, 'like') on conflict do nothing;",
        );
      if (k < 3)
        out.writeln(
          "  insert into public.reactions (user_id, post_id, kind) values ('${fan.id}', pid, 'save') on conflict do nothing;",
        );
      if (k < 5)
        out.writeln(
          "  insert into public.ratings (user_id, post_id, score) values ('${fan.id}', pid, ${k < 4 ? 5 : 4}) on conflict do nothing;",
        );
      if (k == 1 || k == 4) {
        out.writeln(
          "  insert into public.comments (post_id, user_id, body, created_at) values (pid, '${fan.id}', ${sql(comments[(n + fan.n) % comments.length])}, now() - interval '${ago * 20 + fan.n} hours');",
        );
      }
    }
  }
  for (final a in people) {
    for (final b in people) {
      if (a != b && (a.n + b.n) % 3 != 0) {
        out.writeln(
          "  insert into public.follows (follower_id, following_id) values ('${a.id}', '${b.id}') on conflict do nothing;",
        );
      }
    }
  }
  out
    ..writeln('end')
    ..writeln('\$\$;');
  final file = File('supabase/seed/surabaya.sql');
  await file.parent.create(recursive: true);
  await file.writeAsString(out.toString());
  client.close();
  stdout.writeln(
    '\nSelesai: ${file.path}. Salin isinya ke Supabase SQL Editor lalu Run.',
  );
}
