import 'dart:async';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';

import 'market.dart';
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

  static const _storeOf = {
    'd1': 's1',
    'd2': 's2',
    'd4': 's3',
    'd5': 's5',
    'd6': 's4',
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
      id: 's4',
      ownerId: 'u-Dimas',
      name: 'Suvenir Batu Nona',
      category: 'destinasi',
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
      imagePath: 'demo:destinasi:p9',
    ),
    const Product(
      id: 'p10',
      storeId: 's4',
      name: 'Gelang Kerang',
      price: 15000,
      stock: 40,
      imagePath: 'demo:destinasi:p10',
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
      category: 'destinasi',
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
          'store_id': row['store_id'] ?? _storeOf[id],
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
    String? storeId,
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
      'store_id': storeId,
    });
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
}
