import 'dart:async';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';

import 'market.dart';
import 'spot.dart';
import 'spots_repository.dart';
import 'ui/widgets.dart' show memoryImages;

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
      SpotComment(
        author: 'Rara',
        userId: 'u-Rara',
        username: 'rara.jalan',
        body: 'Kuahnya juara, wajib nambah kerupuk. @bimo.ngopi ayo balik!',
      ),
      SpotComment(
        author: 'Bimo',
        userId: 'u-Bimo',
        username: 'bimo.ngopi',
        body: 'Datang sebelum jam 7 biar kebagian.',
      ),
    ],
    'd2': const [
      SpotComment(
        author: 'Nadia',
        userId: 'u-Nadia',
        username: 'nadia.naik',
        body: 'Spot fotonya cakep!',
      ),
    ],
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
    _row(
      'd7',
      'Raka',
      'Skatepark Kolong Layang',
      'Bandung',
      'olahraga',
      'Rampnya mulus, sore-sore ramai anak skate. Gratis dan ada lampu sampai malam.',
      -6.899,
      107.605,
      88,
      31,
      4.6,
      2,
    ),
    _row(
      'd8',
      'Tasya',
      'Workshop Tanah Liat Pojok',
      'Bandung',
      'aktivitas',
      'Dua jam bikin mangkuk sendiri, hasilnya dibakar dan bisa diambil minggu depan.',
      -6.874,
      107.62,
      143,
      97,
      4.8,
      2,
    ),
    _row(
      'd9',
      'Bimo',
      'Thrift Gang Kenanga',
      'Bandung',
      'belanja',
      'Jaket denim 50 ribuan, kemeja vintage numpuk. Datang pagi biar kebagian.',
      -6.93,
      107.64,
      176,
      120,
      4.5,
      2,
    ),
    _row(
      'd10',
      'Nadia',
      'Glamping Lembah Kabut',
      'Lembang',
      'menginap',
      'Tenda hangat menghadap lembah, sarapan diantar. Bintangnya jelas kalau cerah.',
      -6.815,
      107.62,
      231,
      188,
      4.9,
      3,
    ),
    // Orang lain mendokumentasikan tempat yang sama dengan d1 dan d10.
    _row(
      'd11',
      'Gilang',
      'Mie Kocok Mang Ujang',
      'Bandung',
      'kuliner',
      'Datang jam 7 pagi, masih sepi. Porsi jumbo wajib tambah kikil.',
      -6.9141,
      107.6091,
      212,
      77,
      4.9,
      3,
      place: 'p-d1',
      days: 2,
    ),
    _row(
      'd12',
      'Sekar',
      'Mie Kocok Mang Ujang',
      'Bandung',
      'kuliner',
      'Kuahnya gurih, sambalnya nendang. Parkir agak susah.',
      -6.9139,
      107.6089,
      54,
      12,
      4.6,
      2,
      place: 'p-d1',
      days: 9,
    ),
    _row(
      'd13',
      'Tasya',
      'Mie Kocok Mang Ujang',
      'Bandung',
      'kuliner',
      'Langganan dari SMA. Rasanya masih sama.',
      -6.914,
      107.609,
      19,
      4,
      4.5,
      1,
      place: 'p-d1',
      days: 30,
    ),
    _row(
      'd14',
      'Raka',
      'Glamping Lembah Kabut',
      'Lembang',
      'menginap',
      'Bangun subuh, kabutnya turun ke lembah. Bawa jaket tebal.',
      -6.8151,
      107.6201,
      340,
      120,
      4.8,
      3,
      place: 'p-d10',
      days: 1,
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
    int media, {
    String? place,
    int? days,
  }) => {
    'id': id,
    'place_id': place ?? 'p-$id',
    'created_at': DateTime.now()
        .subtract(Duration(days: days ?? (likes % 17) + 3))
        .toIso8601String(),
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

  static const _storeOf = {
    'd1': 's1',
    'd2': 's2',
    'd4': 's3',
    'd5': 's5',
    'd6': 's4',
    'd8': 's7',
    'd9': 's6',
  };

  final _stores = <Store>[
    const Store(
      id: 's1',
      ownerId: 'u-Rara',
      name: 'Mie Kocok Mang Ujang',
      category: 'kuliner',
      address: 'Jl. Banceuy No. 8, Bandung',
      lat: -6.914,
      lng: 107.609,
      contact: '0812-2000-1111',
      description: 'Mie kocok kaldu sapi sejak 1987.',
      onlineOrders: true,
      pickup: true,
      delivery: true,
      deliveryFee: 10000,
      paymentInfo: 'Transfer BCA 1234567890 a.n. Ujang',
    ),
    const Store(
      id: 's2',
      ownerId: 'demo-user',
      name: 'Kopi Teras Hujan',
      category: 'kafe',
      address: 'Jl. Dago Atas No. 21, Bandung',
      lat: -6.887,
      lng: 107.615,
      contact: '0813-4000-2222',
      description: 'Kopi susu gula aren dan roti bakar.',
      onlineOrders: true,
      pickup: true,
      delivery: false,
      paymentInfo: 'QRIS di kasir atau transfer BRI 0987654321',
    ),
    const Store(
      id: 's3',
      ownerId: 'u-Gilang',
      name: 'Sate Maranggi Bu Eem',
      category: 'kuliner',
      address: 'Jl. Raya Cibungur, Purwakarta',
      lat: -6.556,
      lng: 107.443,
      contact: '0815-1000-3333',
      description: 'Sate sapi bumbu kecap, sambal oncom.',
      onlineOrders: true,
      pickup: true,
      delivery: true,
      deliveryFee: 15000,
      paymentInfo: 'Transfer Mandiri 1122334455',
    ),
    const Store(
      id: 's6',
      ownerId: 'u-Bimo',
      name: 'Thrift Gang Kenanga',
      category: 'belanja',
      address: 'Gg. Kenanga No. 12, Bandung',
      lat: -6.93,
      lng: 107.64,
      contact: '0812-8800-6666',
      description: 'Baju bekas pilihan, sudah dicuci dan disetrika.',
      onlineOrders: true,
      pickup: true,
      delivery: true,
      deliveryFee: 9000,
      paymentInfo: 'Transfer BSI 7788990011',
    ),
    const Store(
      id: 's7',
      ownerId: 'u-Tasya',
      name: 'Workshop Tanah Liat Pojok',
      category: 'aktivitas',
      address: 'Jl. Bukit Dago No. 7, Bandung',
      lat: -6.874,
      lng: 107.62,
      contact: '0813-7700-7777',
      description: 'Kelas keramik 2 jam, alat disediakan.',
    ),
    const Store(
      id: 's4',
      ownerId: 'u-Dimas',
      name: 'Suvenir Batu Nona',
      category: 'belanja',
      address: 'Pantai Batu Nona, Lombok Utara',
      lat: -8.39,
      lng: 116.04,
      contact: '0817-9000-4444',
      description: 'Kain tenun dan gelang kerang buatan warga.',
    ),
    const Store(
      id: 's5',
      ownerId: 'u-Sekar',
      name: 'Rumah Seduh Pojok',
      category: 'kafe',
      address: 'Jl. Kemang Raya No. 3, Jakarta',
      lat: -6.262,
      lng: 106.81,
      contact: '0811-7000-5555',
      description: 'Biji kopi lokal sangrai sendiri.',
      onlineOrders: true,
      pickup: true,
      delivery: true,
      deliveryFee: 12000,
      paymentInfo: 'Transfer BNI 5566778899',
    ),
  ];

  final _products = <Product>[
    const Product(
      id: 'p1',
      storeId: 's1',
      name: 'Mie Kocok Spesial',
      price: 28000,
      stock: 12,
      description: 'Kikil, bakso, tauge.',
      imagePath: 'demo:kuliner:p1',
    ),
    const Product(
      id: 'p2',
      storeId: 's1',
      name: 'Mie Kocok Biasa',
      price: 22000,
      stock: 20,
      imagePath: 'demo:kuliner:p2',
    ),
    const Product(
      id: 'p3',
      storeId: 's1',
      name: 'Kerupuk Kulit',
      price: 8000,
      stock: 2,
      imagePath: 'demo:kuliner:p3',
    ),
    const Product(
      id: 'p4',
      storeId: 's2',
      name: 'Es Kopi Susu Aren',
      price: 22000,
      stock: 30,
      imagePath: 'demo:kafe:p4',
    ),
    const Product(
      id: 'p5',
      storeId: 's2',
      name: 'Roti Bakar Keju',
      price: 18000,
      stock: 15,
      imagePath: 'demo:kafe:p5',
    ),
    const Product(
      id: 'p6',
      storeId: 's2',
      name: 'Teh Rempah Panas',
      price: 15000,
      stock: 0,
      imagePath: 'demo:kafe:p6',
    ),
    const Product(
      id: 'p7',
      storeId: 's3',
      name: 'Sate Maranggi 10 tusuk',
      price: 45000,
      stock: 25,
      imagePath: 'demo:kuliner:p7',
    ),
    const Product(
      id: 'p8',
      storeId: 's3',
      name: 'Sambal Oncom Botol',
      price: 25000,
      stock: 8,
      imagePath: 'demo:kuliner:p8',
    ),
    const Product(
      id: 'p9',
      storeId: 's4',
      name: 'Kain Tenun Sasak',
      price: 175000,
      stock: 5,
      imagePath: 'demo:belanja:p9',
    ),
    const Product(
      id: 'p10',
      storeId: 's4',
      name: 'Gelang Kerang',
      price: 15000,
      stock: 40,
      imagePath: 'demo:belanja:p10',
    ),
    const Product(
      id: 'p11',
      storeId: 's5',
      name: 'Biji Kopi Gayo 200 g',
      price: 85000,
      stock: 10,
      imagePath: 'demo:kafe:p11',
    ),
    const Product(
      id: 'p12',
      storeId: 's5',
      name: 'Cold Brew 1 L',
      price: 70000,
      stock: 6,
      imagePath: 'demo:kafe:p12',
    ),
    const Product(
      id: 'p13',
      storeId: 's6',
      name: 'Jaket Denim Vintage',
      price: 85000,
      stock: 3,
      imagePath: 'demo:belanja:p13',
    ),
    const Product(
      id: 'p14',
      storeId: 's6',
      name: 'Kemeja Flanel',
      price: 55000,
      stock: 7,
      imagePath: 'demo:belanja:p14',
    ),
    const Product(
      id: 'p15',
      storeId: 's7',
      name: 'Kelas Keramik 2 Jam',
      price: 150000,
      stock: 8,
      imagePath: 'demo:aktivitas:p15',
    ),
  ];

  final _orders = <Map<String, dynamic>>[
    {
      'id': 'o1',
      'store_id': 's2',
      'buyer_id': 'u-Rara',
      'buyer': 'Rara',
      'status': 'menunggu',
      'payment_status': 'belum',
      'fulfillment': 'ambil',
      'address': '',
      'note': 'Gula aren dikit ya',
      'shipping_fee': 0,
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 7))
          .toIso8601String(),
      'items': [
        {
          'product_id': 'p4',
          'name': 'Es Kopi Susu Aren',
          'unit_price': 22000,
          'qty': 2,
        },
        {
          'product_id': 'p5',
          'name': 'Roti Bakar Keju',
          'unit_price': 18000,
          'qty': 1,
        },
      ],
    },
    {
      'id': 'o2',
      'store_id': 's2',
      'buyer_id': 'u-Bimo',
      'buyer': 'Bimo',
      'status': 'diterima',
      'payment_status': 'menunggu_konfirmasi',
      'fulfillment': 'ambil',
      'address': '',
      'note': '',
      'shipping_fee': 0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
      'items': [
        {
          'product_id': 'p4',
          'name': 'Es Kopi Susu Aren',
          'unit_price': 22000,
          'qty': 1,
        },
      ],
    },
  ];

  final _applications = <StoreApplication>[
    StoreApplication(
      id: 'a1',
      storeName: 'Bakso Gunung Pak Kumis',
      category: 'kuliner',
      address: 'Jl. Cihampelas No. 40, Bandung',
      lat: -6.893,
      lng: 107.604,
      contact: '0812-3456-7000',
      relation: 'pemilik',
      note: 'Buka 10.00-21.00, bisa bungkus.',
      status: 'menunggu',
      applicantName: 'Gilang',
      applicantId: 'u-Gilang',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    StoreApplication(
      id: 'a2',
      storeName: 'Oleh-oleh Curug Cikaso',
      category: 'belanja',
      address: 'Desa Ciniti, Sukabumi',
      lat: -7.35,
      lng: 106.62,
      contact: '0857-1111-2222',
      relation: 'pengelola',
      status: 'menunggu',
      applicantName: 'Nadia',
      applicantId: 'u-Nadia',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

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
    _ensureMe();
    _auth.add(null);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _user = 'demo-user';
    _name = 'Kamu';
    _ensureMe();
    _auth.add(null);
  }

  @override
  Future<bool> signUp(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _user = 'demo-user';
    _name = name;
    _ensureMe();
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
    String? user,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final q = (query ?? '').toLowerCase();
    final blocked = _user == null
        ? const <String>{}
        : (_demoBlocks[_user!] ?? const <String>{});
    final found = <Spot>[];
    for (final row in _rows) {
      final id = row['id'] as String;
      if (blocked.contains(row['owner_id'])) continue;
      if (category != null && row['category'] != category) continue;
      if (q.isNotEmpty &&
          !'${row['title']} ${row['city']}'.toLowerCase().contains(q)) {
        continue;
      }
      if (mode == 'saved' && !_saves.contains(id)) continue;
      if (mode == 'mine' && row['owner_id'] != _user) continue;
      if (mode == 'user' && row['owner_id'] != user) continue;
      if (mode == 'place' && row['place_id'] != user) continue;
      if (mode == 'tagged' && !(_tags[id] ?? const {}).contains(user)) continue;
      if (mode == 'following' &&
          !_follows.contains('$_user>${row['owner_id']}')) {
        continue;
      }
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
          'store_id': row['store_id'] ?? _storeOf[id],
          'author_username': _profiles[row['owner_id']]?.username ?? '',
          'author_avatar': _profiles[row['owner_id']]?.avatarPath,
          'rating': _blend((row['rating'] as num?)?.toDouble(), mine),
        }),
      );
    }
    if (mode == 'popular') {
      found.sort((a, b) => b.viralScore().compareTo(a.viralScore()));
    }
    if (mode == 'place') {
      found.sort((a, b) => b.engagement.compareTo(a.engagement));
    }
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
  Future<Spot?> spotById(String id) async {
    final all = await feed(mode: 'popular');
    for (final spot in all) {
      if (spot.id == id) return spot;
    }
    return null;
  }

  @override
  Future<List<SpotComment>> comments(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final blocked = _user == null
        ? const <String>{}
        : (_demoBlocks[_user!] ?? const <String>{});
    return [
      for (final c in _comments[postId] ?? const <SpotComment>[])
        if (!blocked.contains(c.userId)) c,
    ];
  }

  @override
  Future<void> addComment(String postId, String body) async {
    if (_user == null) throw StateError('Masuk dulu untuk berkomentar.');
    (_comments[postId] ??= []).insert(
      0,
      SpotComment(
        id: 'c${DateTime.now().microsecondsSinceEpoch}',
        author: _name,
        body: body.trim(),
        userId: _user!,
        username: _profiles[_user]?.username ?? '',
        avatar: _profiles[_user]?.avatarPath,
      ),
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {
    if (_user == null) throw StateError('Masuk dulu ya.');
    for (final list in _comments.values) {
      list.removeWhere((c) => c.id == commentId && c.userId == _user);
    }
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
    String? storeId,
    String? placeId,
    List<String> tags = const [],
  }) async {
    if (_user == null) throw StateError('Masuk dulu untuk membagikan spot.');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final id = 'n${_rows.length}';
    final place = placeId ?? 'p-$id';
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
      'store_id': storeId,
      'place_id': place,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (tags.isNotEmpty) _tags[id] = tags.toSet();
  }

  @override
  Future<List<Place>> nearbyPlaces(
    double lat,
    double lng, {
    String? query,
  }) async {
    await _wait();
    final q = (query ?? '').toLowerCase();
    final byPlace = <String, List<Map<String, dynamic>>>{};
    for (final row in _rows) {
      byPlace.putIfAbsent(row['place_id'] as String, () => []).add(row);
    }
    final out = <Place>[];
    for (final MapEntry(key: id, value: rows) in byPlace.entries) {
      final first = rows.last;
      final meters =
          _km(lat, lng, first['lat'] as double, first['lng'] as double) * 1000;
      if (meters > 300) continue;
      if (q.isNotEmpty && !'${first['title']}'.toLowerCase().contains(q)) {
        continue;
      }
      rows.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
      out.add(
        Place(
          id: id,
          name: first['title'] as String,
          category: first['category'] as String,
          city: first['city'] as String,
          lat: first['lat'] as double,
          lng: first['lng'] as double,
          distanceM: meters,
          posts: rows.length,
          people: rows.map((r) => r['owner_id']).toSet().length,
          cover: ((rows.first['media'] as List).first as Map)['path'] as String,
        ),
      );
    }
    out.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    return out;
  }

  @override
  Future<List<Spot>> placeSpots(String placeId) =>
      feed(mode: 'place', user: placeId);

  @override
  Future<void> updateSpot(
    String spotId, {
    required String title,
    required String story,
  }) async {
    await _wait();
    final row = _rows.firstWhere((r) => r['id'] == spotId);
    if (row['owner_id'] != _user) throw StateError('Bukan spot kamu.');
    row['title'] = title.trim();
    row['story'] = story.trim();
  }

  @override
  Future<void> deleteSpot(Spot spot) async {
    await _wait();
    if (spot.ownerId != _user) throw StateError('Bukan spot kamu.');
    _rows.removeWhere((r) => r['id'] == spot.id);
  }

  // ---------- Marketplace demo ----------

  String _me() {
    final id = _user;
    if (id == null) throw StateError('Masuk dulu ya.');
    return id;
  }

  Future<void> _wait([int ms = 350]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  @override
  String productImageUrl(String path) => path;

  @override
  Future<List<Store>> stores({String? query, String? category}) async {
    await _wait();
    final q = (query ?? '').toLowerCase();
    return _stores
        .where((s) => s.active)
        .where((s) => category == null || s.category == category)
        .where(
          (s) =>
              q.isEmpty || '${s.name} ${s.address}'.toLowerCase().contains(q),
        )
        .toList()
      ..sort((a, b) => (b.onlineOrders ? 1 : 0) - (a.onlineOrders ? 1 : 0));
  }

  @override
  Future<List<Store>> storesNear(double lat, double lng) async => _stores
      .where((s) => (s.lat - lat).abs() < .02 && (s.lng - lng).abs() < .02)
      .toList();

  @override
  Future<Store?> store(String id) async {
    await _wait(200);
    for (final s in _stores) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<List<Product>> products(String storeId) async {
    await _wait();
    final mine = _stores.any((s) => s.id == storeId && s.ownerId == _user);
    return _products
        .where((p) => p.storeId == storeId && (p.active || mine))
        .toList();
  }

  @override
  Future<List<Product>> featuredProducts() async {
    await _wait();
    return [
      for (final p in _products)
        if (p.active && p.stock > 0)
          Product(
            id: p.id,
            storeId: p.storeId,
            name: p.name,
            price: p.price,
            stock: p.stock,
            imagePath: p.imagePath,
            storeName: _stores.firstWhere((s) => s.id == p.storeId).name,
          ),
    ];
  }

  @override
  Future<Store?> myStore() async {
    final me = _user;
    if (me == null) return null;
    for (final s in _stores) {
      if (s.ownerId == me) return s;
    }
    return null;
  }

  @override
  Future<void> updateStore(Store store) async {
    await _wait();
    if (store.onlineOrders && !store.pickup && !store.delivery) {
      throw StateError('Pilih minimal ambil atau kirim.');
    }
    final i = _stores.indexWhere((s) => s.id == store.id && s.ownerId == _me());
    if (i < 0) throw StateError('Bukan tokomu.');
    _stores[i] = store;
  }

  @override
  Future<void> saveProduct({
    required String storeId,
    String? id,
    required String name,
    required String description,
    required int price,
    required int stock,
    required bool active,
    XFile? image,
  }) async {
    _me();
    await _wait();
    final old = id == null ? null : _products.firstWhere((p) => p.id == id);
    final product = Product(
      id: id ?? 'p${_products.length + 1}x',
      storeId: storeId,
      name: name.trim(),
      description: description.trim(),
      price: price,
      stock: stock,
      active: active,
      imagePath: old?.imagePath ?? 'demo:kafe:${name.hashCode}',
    );
    if (old == null) {
      _products.add(product);
    } else {
      _products[_products.indexOf(old)] = product;
    }
  }

  @override
  Future<void> deleteProduct(String id) async =>
      _products.removeWhere((p) => p.id == id);

  final _mine = <StoreApplication>[];

  @override
  Future<List<StoreApplication>> myApplications() async => List.of(_mine);

  @override
  Future<void> applyStore({
    required String name,
    required String category,
    required String address,
    required double lat,
    required double lng,
    required String contact,
    required String relation,
    required String note,
    String? postId,
  }) async {
    _me();
    await _wait(700);
    if (_mine.any((a) => a.status == 'menunggu')) {
      throw StateError('Masih ada pengajuan yang menunggu.');
    }
    _mine.insert(
      0,
      StoreApplication(
        id: 'm${_mine.length}',
        storeName: name.trim(),
        category: category,
        address: address.trim(),
        lat: lat,
        lng: lng,
        contact: contact.trim(),
        relation: relation,
        note: note.trim(),
        status: 'menunggu',
        applicantName: _name,
        applicantId: _me(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> isAdmin() async => _user != null;

  @override
  Future<List<StoreApplication>> pendingApplications() async {
    await _wait();
    return [
      ..._applications,
      ..._mine,
    ].where((a) => a.status == 'menunggu').toList();
  }

  @override
  Future<void> reviewApplication(
    String id,
    bool approve, [
    String? reason,
  ]) async {
    await _wait();
    final list = _applications.any((a) => a.id == id) ? _applications : _mine;
    final i = list.indexWhere((a) => a.id == id);
    final app = list[i];
    if (app.applicantId == _me()) {
      throw StateError('Tidak bisa meninjau pengajuan sendiri.');
    }
    if (!approve && (reason ?? '').trim().length < 3) {
      throw StateError('Tulis alasan penolakan.');
    }
    list[i] = StoreApplication(
      id: app.id,
      storeName: app.storeName,
      category: app.category,
      address: app.address,
      lat: app.lat,
      lng: app.lng,
      contact: app.contact,
      relation: app.relation,
      status: approve ? 'disetujui' : 'ditolak',
      rejectReason: approve ? null : reason,
      createdAt: app.createdAt,
    );
    if (approve) {
      _stores.add(
        Store(
          id: 's${_stores.length + 1}',
          ownerId: app.applicantId,
          name: app.storeName,
          category: app.category,
          address: app.address,
          lat: app.lat,
          lng: app.lng,
          contact: app.contact,
        ),
      );
    }
  }

  @override
  Future<String> placeOrder({
    required Cart cart,
    required String fulfillment,
    required String address,
    required String note,
  }) async {
    final me = _me();
    await _wait(800);
    for (final o in _orders) {
      if (o['request_key'] == cart.requestKey) return o['id'] as String;
    }
    final shop = cart.store!;
    final fresh = _stores.firstWhere((s) => s.id == shop.id);
    if (!fresh.onlineOrders) {
      throw StateError('Toko ini hanya melayani pembelian di lokasi.');
    }
    if (fresh.ownerId == me) {
      throw StateError('Tidak bisa memesan di toko sendiri.');
    }
    if (fulfillment == 'kirim' && address.trim().length < 10) {
      throw StateError('Tulis alamat pengiriman yang lengkap.');
    }
    final items = <Map<String, dynamic>>[];
    for (final line in cart.lines.values) {
      final p = _products.firstWhere((x) => x.id == line.product.id);
      if (p.stock < line.qty) {
        throw StateError('Stok ${p.name} tinggal ${p.stock}.');
      }
      if (p.price != line.product.price) {
        throw StateError('Harga ada yang berubah. Cek keranjang lagi.');
      }
      items.add({
        'product_id': p.id,
        'name': p.name,
        'unit_price': p.price,
        'qty': line.qty,
      });
    }
    final id = 'o${_orders.length + 1}';
    _orders.insert(0, {
      'id': id,
      'store_id': shop.id,
      'buyer_id': me,
      'buyer': _name,
      'request_key': cart.requestKey,
      'status': 'menunggu',
      'payment_status': 'belum',
      'fulfillment': fulfillment,
      'address': fulfillment == 'kirim' ? address.trim() : '',
      'note': note.trim(),
      'shipping_fee': fulfillment == 'kirim' ? fresh.deliveryFee : 0,
      'created_at': DateTime.now().toIso8601String(),
      'items': items,
    });
    // Toko demo menerima pesanan otomatis setelah beberapa detik.
    Future<void>.delayed(const Duration(seconds: 4), () {
      final o = _orders.firstWhere((x) => x['id'] == id);
      if (o['status'] == 'menunggu') o['status'] = 'diterima';
    });
    return id;
  }

  StoreOrder _toOrder(Map<String, dynamic> o) {
    final items = (o['items'] as List).cast<Map<String, dynamic>>();
    final subtotal = items.fold<int>(
      0,
      (sum, i) => sum + (i['unit_price'] as int) * (i['qty'] as int),
    );
    final shop = _stores.firstWhere((s) => s.id == o['store_id']);
    return StoreOrder.fromJson({
      ...o,
      'subtotal': subtotal,
      'total': subtotal + (o['shipping_fee'] as int),
      'stores': {'name': shop.name, 'payment_info': shop.paymentInfo},
      'profiles': {'display_name': o['buyer']},
      'order_items': [
        for (final (i, item) in items.indexed) {...item, 'line': i + 1},
      ],
    });
  }

  @override
  Future<List<StoreOrder>> myOrders() async {
    final me = _user;
    if (me == null) return [];
    await _wait();
    return _orders.where((o) => o['buyer_id'] == me).map(_toOrder).toList();
  }

  @override
  Future<StoreOrder> order(String id) async {
    await _wait(200);
    return _toOrder(_orders.firstWhere((o) => o['id'] == id));
  }

  @override
  Future<List<StoreOrder>> storeOrders(String storeId) async {
    await _wait();
    return _orders
        .where((o) => o['store_id'] == storeId)
        .map(_toOrder)
        .toList();
  }

  @override
  Future<void> orderAction(
    String orderId,
    String action, [
    String? reason,
  ]) async {
    _me();
    await _wait();
    final o = _orders.firstWhere((x) => x['id'] == orderId);
    final status = o['status'] as String;
    switch (action) {
      case 'accept':
        if (status != 'menunggu') {
          throw StateError('Pesanan ini sudah diproses.');
        }
        for (final item in (o['items'] as List).cast<Map<String, dynamic>>()) {
          final i = _products.indexWhere((p) => p.id == item['product_id']);
          final p = _products[i];
          final qty = item['qty'] as int;
          if (p.stock < qty) throw StateError('Stok ${p.name} tidak cukup.');
          _products[i] = Product(
            id: p.id,
            storeId: p.storeId,
            name: p.name,
            price: p.price,
            stock: p.stock - qty,
            description: p.description,
            imagePath: p.imagePath,
            active: p.active,
          );
        }
        o['status'] = 'diterima';
      case 'reject':
        if (status != 'menunggu') {
          throw StateError('Pesanan ini sudah diproses.');
        }
        if ((reason ?? '').trim().length < 3) {
          throw StateError('Tulis alasan penolakan.');
        }
        o['status'] = 'ditolak';
        o['reject_reason'] = reason!.trim();
      case 'confirm_payment':
        if (status != 'diterima') {
          throw StateError('Pembayaran belum bisa dikonfirmasi.');
        }
        o['payment_status'] = 'lunas';
        o['status'] = 'diproses';
      case 'advance':
        o['status'] = switch (status) {
          'diproses' => 'siap',
          'siap' => 'selesai',
          _ => throw StateError('Status pesanan tidak bisa dilanjutkan.'),
        };
      case 'report_payment':
        if (status != 'diterima') {
          throw StateError('Pesanan ini belum bisa dibayar.');
        }
        o['payment_status'] = 'menunggu_konfirmasi';
      default:
        if (status != 'menunggu') {
          throw StateError(
            'Pesanan yang sudah diterima toko tidak bisa dibatalkan.',
          );
        }
        o['status'] = 'dibatalkan';
    }
  }

  // ---------- Profil sosial demo ----------

  static const _demoStreaks = {
    'Rara': 9,
    'Bimo': 3,
    'Nadia': 41,
    'Gilang': 1,
    'Sekar': 16,
    'Dimas': 120,
    'Raka': 0,
    'Tasya': 5,
  };

  final _profiles = <String, UserProfile>{
    for (final (name, handle, bio) in const [
      ('Rara', 'rara.jalan', 'Kuliner pinggir jalan > resto mahal.'),
      (
        'Bimo',
        'bimo.ngopi',
        'Ngopi dulu, mikir belakangan. Thrift tiap Minggu.',
      ),
      ('Nadia', 'nadia.naik', 'Naik gunung, turun ke warung.'),
      ('Gilang', 'gilang.makan', 'Sate hunter sejak 2015.'),
      ('Sekar', 'sekar.seduh', 'Manual brew dan tanaman.'),
      ('Dimas', 'dimas.pantai', 'Ngejar sunset di pantai sepi.'),
      ('Raka', 'raka.skate', 'Skate sore, bakso malam.'),
      (
        'Tasya',
        'tasya.liat',
        'Bikin mangkuk, makan bakso pakai mangkuk sendiri.',
      ),
    ])
      'u-$name': UserProfile(
        id: 'u-$name',
        username: handle,
        displayName: name,
        bio: bio,
        streak: _demoStreaks[name] ?? 0,
        bestStreak: (_demoStreaks[name] ?? 0) + 4,
      ),
  };

  /// Pasangan "pengikut>diikuti".
  final _follows = <String>{
    'u-Rara>u-Bimo',
    'u-Bimo>u-Rara',
    'u-Nadia>u-Rara',
    'u-Dimas>u-Nadia',
    'u-Raka>u-Nadia',
    'u-Tasya>u-Bimo',
    'u-Sekar>u-Bimo',
    'u-Nadia>demo-user',
    'u-Bimo>demo-user',
  };

  final _tags = <String, Set<String>>{
    'd1': {'u-Bimo'},
    'd3': {'u-Rara', 'u-Dimas'},
    'd8': {'u-Nadia'},
  };

  void _ensureMe() {
    final handle = _name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    _profiles.putIfAbsent(
      'demo-user',
      () => UserProfile(
        id: 'demo-user',
        username: handle.length >= 3 ? handle : 'kamu.spots',
        displayName: _name,
        bio: 'Baru gabung Spots.',
      ),
    );
  }

  @override
  String? avatarUrl(String? path) => path;

  final Map<String, int> _demoXp = {};
  final Map<String, bool> _demoInviteClaimed = {};
  final Map<String, Map<String, QuestProgressItem>> _demoQuests = {};

  static const _demoBaseXp = {
    'reel': 1,
    'like': 2,
    'save': 3,
    'rate': 3,
    'comment': 5,
    'post': 30,
    'order': 20,
    'store': 25,
    'share': 5,
    'invited': 30,
    'follow': 1,
  };

  static const _demoQuestTargets = {
    'reel': (5, 20),
    'like': (3, 15),
    'save': (1, 10),
    'comment': (1, 15),
    'share': (1, 25),
  };

  @override
  Future<void> syncStreak(int streak) async {
    final me = _user;
    final p = me == null ? null : _profiles[me];
    if (p == null) return;
    _profiles[me!] = UserProfile(
      id: p.id,
      username: p.username,
      displayName: p.displayName,
      bio: p.bio,
      avatarPath: p.avatarPath,
      streak: streak,
      bestStreak: streak > p.bestStreak ? streak : p.bestStreak,
    );
  }

  @override
  Future<ServerGameState?> fetchGameState(String day) async {
    final me = _user;
    if (me == null) return null;
    final p = _profiles[me];
    final key = '$me:$day';
    return ServerGameState(
      xp: _demoXp[me] ?? 0,
      streak: p?.streak ?? 0,
      bestStreak: p?.bestStreak ?? 0,
      day: day,
      quests: Map<String, QuestProgressItem>.from(_demoQuests[key] ?? const {}),
    );
  }

  @override
  Future<GameActionResult?> recordGameAction(String action, String day) async {
    final me = _user;
    if (me == null) return null;
    final base = _demoBaseXp[action];
    if (base == null) throw ArgumentError('Aksi tidak dikenal.');
    if (action == 'invited') {
      if (_demoInviteClaimed[me] == true) {
        return GameActionResult(xp: _demoXp[me] ?? 0, gained: 0);
      }
      _demoInviteClaimed[me] = true;
      final next = (_demoXp[me] ?? 0) + base;
      _demoXp[me] = next;
      return GameActionResult(xp: next, gained: base);
    }

    var gained = base;
    String? finished;
    final rule = _demoQuestTargets[action];
    if (rule != null) {
      final key = '$me:$day';
      final quests = _demoQuests.putIfAbsent(key, () => {});
      final current = quests[action];
      if (current == null || !current.claimed) {
        final nextProgress = (current?.progress ?? 0) + 1;
        final done = nextProgress >= rule.$1;
        quests[action] = QuestProgressItem(
          key: action,
          progress: nextProgress,
          claimed: done,
        );
        if (done) {
          gained += rule.$2;
          finished = action;
        }
      }
    }
    final nextXp = (_demoXp[me] ?? 0) + gained;
    _demoXp[me] = nextXp;
    return GameActionResult(
      xp: nextXp,
      gained: gained,
      finishedQuest: finished,
    );
  }

  @override
  Future<UserProfile?> profile(String id) async {
    await _wait(200);
    return _profiles[id];
  }

  @override
  Future<UserProfile?> profileByUsername(String username) async {
    await _wait(150);
    for (final p in _profiles.values) {
      if (p.username == username.toLowerCase()) return p;
    }
    return null;
  }

  @override
  Future<UserProfile?> myProfile() async =>
      _user == null ? null : _profiles[_user];

  @override
  Future<ProfileStats> profileStats(String id) async {
    await _wait(250);
    final mine = _rows.where((r) => r['owner_id'] == id).toList();
    var likes = 0, saves = 0;
    for (final r in mine) {
      likes += (r['likes'] as int) + (_likes.contains(r['id']) ? 1 : 0);
      saves += (r['saves'] as int) + (_saves.contains(r['id']) ? 1 : 0);
    }
    return ProfileStats(
      posts: mine.length,
      followers: _follows.where((f) => f.endsWith('>$id')).length,
      following: _follows.where((f) => f.startsWith('$id>')).length,
      likes: likes,
      saves: saves,
      cities: mine
          .map((r) => (r['city'] as String).toLowerCase())
          .toSet()
          .length,
      isFollowing: _follows.contains('$_user>$id'),
    );
  }

  @override
  Future<List<UserProfile>> suggestedUsers({int limit = 8}) async {
    await _wait(250);
    return _profiles.values
        .where((p) => p.id != _user && !_follows.contains('$_user>${p.id}'))
        .take(limit)
        .toList();
  }

  @override
  Future<Set<String>> followingAmong(List<String> ids) async => {
    for (final id in ids)
      if (_follows.contains('$_user>$id')) id,
  };

  @override
  Future<List<UserProfile>> searchUsers(String query) async {
    final q = query.trim().replaceAll('@', '').toLowerCase();
    if (q.isEmpty) return [];
    return _profiles.values
        .where((p) => p.id != _user)
        .where(
          (p) =>
              p.username.contains(q) || p.displayName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<void> setFollow(String target, bool on) async {
    final me = _me();
    if (me == target) throw StateError('Tidak bisa mengikuti diri sendiri.');
    on ? _follows.add('$me>$target') : _follows.remove('$me>$target');
  }

  @override
  Future<List<UserProfile>> followList(
    String id, {
    required bool followers,
  }) async {
    await _wait(250);
    return [
      for (final f in _follows)
        if (followers ? f.endsWith('>$id') : f.startsWith('$id>'))
          ?_profiles[followers ? f.split('>').first : f.split('>').last],
    ];
  }

  @override
  Future<List<UserProfile>> taggedUsers(String postId) async => [
    for (final id in _tags[postId] ?? const <String>{}) ?_profiles[id],
  ];

  @override
  Future<void> updateProfile({
    required String displayName,
    required String username,
    required String bio,
    XFile? avatar,
  }) async {
    final me = _me();
    await _wait(500);
    final handle = username.trim().toLowerCase();
    if (!usernamePattern.hasMatch(handle)) {
      throw StateError(
        'Username 3-20 karakter: huruf kecil, angka, titik, atau _.',
      );
    }
    if (_profiles.values.any((p) => p.username == handle && p.id != me)) {
      throw StateError('Username @$handle sudah dipakai.');
    }
    var avatarPath = _profiles[me]?.avatarPath;
    if (avatar != null) {
      avatarPath = 'mem:$me:${DateTime.now().millisecondsSinceEpoch}';
      memoryImages[avatarPath] = await avatar.readAsBytes();
    }
    _name = displayName.trim();
    _profiles[me] = UserProfile(
      id: me,
      username: handle,
      displayName: _name,
      bio: bio.trim(),
      avatarPath: avatarPath,
      streak: _profiles[me]?.streak ?? 0,
      bestStreak: _profiles[me]?.bestStreak ?? 0,
    );
  }

  final List<({String reporter, String targetType, String targetId, String reason})>
  _demoReports = [];
  final Map<String, Set<String>> _demoBlocks = {};

  @override
  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final me = _me();
    final text = reason.trim();
    if (text.length < 3) throw StateError('Alasan terlalu singkat.');
    _demoReports.removeWhere(
      (r) =>
          r.reporter == me &&
          r.targetType == targetType &&
          r.targetId == targetId,
    );
    _demoReports.add((
      reporter: me,
      targetType: targetType,
      targetId: targetId,
      reason: text,
    ));
  }

  @override
  Future<void> setBlocked(String targetUserId, bool block) async {
    final me = _me();
    if (me == targetUserId) throw StateError('Tidak bisa memblokir diri sendiri.');
    final set = _demoBlocks.putIfAbsent(me, () => <String>{});
    if (block) {
      set.add(targetUserId);
    } else {
      set.remove(targetUserId);
    }
  }

  @override
  Future<bool> isBlocked(String targetUserId) async {
    final me = _user;
    if (me == null || me == targetUserId) return false;
    return _demoBlocks[me]?.contains(targetUserId) ?? false;
  }
}
