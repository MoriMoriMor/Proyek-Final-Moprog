import 'dart:async';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';

import 'spot.dart';
import 'spots_repository.dart';

/// Data contoh di memori untuk mencoba tampilan tanpa proyek Supabase.
/// Aktif dengan `--dart-define=SPOTS_DEMO=true` atau tombol di layar setup.
class DemoSpotsRepository extends SpotsRepository {
  DemoSpotsRepository() : super(null);

  final _auth = StreamController<void>.broadcast();
  String? _user;
  String _name = 'Kamu';
  final _likes = <String>{'d3'};
  final _saves = <String>{'d2', 'd5'};
  final _ratings = <String, int>{};
  final _comments = <String, List<SpotComment>>{
    'd1': const [
      SpotComment(author: 'Rara', body: 'Kuahnya juara, wajib nambah kerupuk.'),
      SpotComment(author: 'Bimo', body: 'Datang sebelum jam 7 biar kebagian.'),
    ],
    'd2': const [SpotComment(author: 'Nadia', body: 'Spot fotonya cakep!')],
  };
  final List<Map<String, dynamic>> _rows = [
    _row(
      'd1',
      'Rara',
      'Mie Kocok Mang Ujang',
      'Bandung',
      'kuliner',
      'Kuah kaldu sapinya kental, kikilnya lembut. Antre sebentar tapi worth it.',
      -6.914,
      107.609,
      128,
      41,
      4.8,
      2,
    ),
    _row(
      'd2',
      'Bimo',
      'Kopi Teras Hujan',
      'Bandung',
      'kafe',
      'Duduk di teras kayu sambil dengar hujan. Es kopi susu gulanya pas.',
      -6.887,
      107.615,
      96,
      58,
      4.6,
      3,
    ),
    _row(
      'd3',
      'Nadia',
      'Bukit Kabut Ciwangun',
      'Bandung Barat',
      'destinasi',
      'Naik subuh, kabutnya turun pelan-pelan di atas kebun teh. Bawa jaket.',
      -6.80,
      107.56,
      211,
      133,
      4.9,
      4,
    ),
    _row(
      'd4',
      'Gilang',
      'Sate Maranggi Bu Eem',
      'Purwakarta',
      'kuliner',
      'Daging empuk, sambal oncomnya bikin nagih. Porsi besar.',
      -6.556,
      107.443,
      74,
      20,
      4.4,
      1,
    ),
    _row(
      'd5',
      'Sekar',
      'Rumah Seduh Pojok',
      'Jakarta Selatan',
      'kafe',
      'Kafe mungil penuh tanaman. Manual brew-nya serius, tempatnya tenang.',
      -6.262,
      106.81,
      63,
      37,
      4.5,
      2,
    ),
    _row(
      'd6',
      'Dimas',
      'Pantai Batu Nona',
      'Lombok',
      'destinasi',
      'Air bening, pasir putih, sepi kalau datang pagi. Sunset-nya gila.',
      -8.39,
      116.04,
      302,
      190,
      5.0,
      3,
    ),
  ];

  static Map<String, dynamic> _row(
    String id,
    String author,
    String title,
    String city,
    String category,
    String story,
    double lat,
    double lng,
    int likes,
    int saves,
    double rating,
    int media,
  ) => {
    'id': id,
    'owner_id': 'u-$author',
    'author': author,
    'title': title,
    'city': city,
    'category': category,
    'story': story,
    'lat': lat,
    'lng': lng,
    'likes': likes,
    'saves': saves,
    'rating': rating,
    'media': [
      for (var i = 0; i < media; i++)
        {'path': 'demo:$category:$id$i', 'type': 'image'},
    ],
  };

  @override
  bool get isDemo => true;
  @override
  String? get userId => _user;
  @override
  String get email => _user == null ? '' : 'demo@spots.app';
  @override
  String get displayName => _name;
  @override
  Stream<void> get authChanges => _auth.stream;
  @override
  String publicMediaUrl(String path) => path;

  @override
  Future<void> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _user = 'demo-user';
    _name = email.split('@').first;
    _auth.add(null);
  }

  @override
  Future<bool> signUp(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _user = 'demo-user';
    _name = name;
    _auth.add(null);
    return true;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _auth.add(null);
  }

  @override
  Future<List<Spot>> feed({
    double? lat,
    double? lng,
    String mode = 'near',
    String? category,
    String? query,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final q = (query ?? '').toLowerCase();
    final found = <Spot>[];
    for (final row in _rows) {
      final id = row['id'] as String;
      if (category != null && row['category'] != category) continue;
      if (q.isNotEmpty &&
          !'${row['title']} ${row['city']}'.toLowerCase().contains(q)) {
        continue;
      }
      if (mode == 'saved' && !_saves.contains(id)) continue;
      if (mode == 'mine' && row['owner_id'] != _user) continue;
      double? distance;
      if (lat != null && lng != null) {
        distance = _km(lat, lng, row['lat'] as double, row['lng'] as double);
        if (mode == 'near' && distance > 20) continue;
      }
      final mine = _ratings[id];
      found.add(
        Spot.fromJson({
          ...row,
          'likes': (row['likes'] as int) + (_likes.contains(id) ? 1 : 0),
          'saves': (row['saves'] as int) + (_saves.contains(id) ? 1 : 0),
          'comment_count': _comments[id]?.length ?? 0,
          'liked': _likes.contains(id),
          'saved': _saves.contains(id),
          'distance_km': distance,
          'rating': _blend((row['rating'] as num?)?.toDouble(), mine),
        }),
      );
    }
    if (mode == 'popular') found.sort((a, b) => b.likes.compareTo(a.likes));
    return found;
  }

  static double? _blend(double? base, int? mine) {
    if (mine == null) return base;
    if (base == null) return mine.toDouble();
    return (base * 9 + mine) / 10;
  }

  static double _km(double aLat, double aLng, double bLat, double bLng) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(bLat - aLat), dLng = rad(bLng - aLng);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(aLat)) *
            math.cos(rad(bLat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  @override
  Future<List<SpotComment>> comments(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.of(_comments[postId] ?? const []);
  }

  @override
  Future<void> addComment(String postId, String body) async {
    if (_user == null) throw StateError('Masuk dulu untuk berkomentar.');
    (_comments[postId] ??= []).insert(
      0,
      SpotComment(author: _name, body: body.trim()),
    );
  }

  @override
  Future<void> setReaction(String postId, String kind, bool on) async {
    if (_user == null) throw StateError('Masuk dulu untuk menyimpan tempat.');
    final set = kind == 'like' ? _likes : _saves;
    on ? set.add(postId) : set.remove(postId);
  }

  @override
  Future<void> rate(String postId, int score) async {
    if (_user == null) throw StateError('Masuk dulu untuk memberi rating.');
    _ratings[postId] = score;
  }

  @override
  Future<void> createSpot({
    required String title,
    required String city,
    required String category,
    required String story,
    required double lat,
    required double lng,
    required List<XFile> files,
  }) async {
    if (_user == null) throw StateError('Masuk dulu untuk membagikan spot.');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final id = 'n${_rows.length}';
    _rows.insert(0, {
      ..._row(
        id,
        _name,
        title.trim(),
        city.trim(),
        category,
        story.trim(),
        lat,
        lng,
        0,
        0,
        0,
        files.length.clamp(1, 5),
      ),
      'owner_id': _user,
      'rating': null,
    });
  }
}
