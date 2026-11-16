import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'market.dart';

import 'spot.dart';

/// Halaman tujuan link konfirmasi email. Daftarkan juga di Supabase:
/// Authentication → URL Configuration → Redirect URLs.
const confirmUrl = String.fromEnvironment(
  'CONFIRM_URL',
  defaultValue: 'https://morimorimor.github.io/Proyek-Final-Moprog/confirm/',
);

class SpotsRepository {
  SpotsRepository(this._client);
  final SupabaseClient? _client;
  SupabaseClient get client => _client!;

  bool get isDemo => false;
  String? get userId => client.auth.currentUser?.id;
  String get email => client.auth.currentUser?.email ?? '';
  String get displayName {
    final user = client.auth.currentUser;
    final name = user?.userMetadata?['display_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name;
    final mail = user?.email ?? '';
    return mail.contains('@') ? mail.split('@').first : 'Traveler';
  }

  Stream<void> get authChanges => client.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email.trim(), password: password);

  /// Mengembalikan `false` jika akun perlu dikonfirmasi lewat email.
  Future<bool> signUp(String name, String email, String password) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': name.trim()},
      emailRedirectTo: confirmUrl,
    );
    return response.session != null;
  }

  /// Alamat yang membuka aplikasi lagi setelah login Google di browser.
  /// Daftarkan juga di Supabase: Authentication → URL Configuration.
  static const authCallback = 'io.spots.app://login-callback';

  Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb
          ? Uri.base.replace(fragment: '', query: '').toString()
          : authCallback,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => client.auth.signOut();
  String publicMediaUrl(String path) =>
      path.startsWith('https://upload.wikimedia.org/')
      ? path
      : client.storage.from('spot-media').getPublicUrl(path);

  Future<List<Spot>> feed({
    double? lat,
    double? lng,
    String mode = 'near',
    String? category,
    String? query,
    String? user,
  }) async {
    final rows = await client.rpc(
      'feed_spots',
      params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_mode': mode,
        'p_category': category,
        'p_query': query,
        'p_limit': 40,
        'p_user': ?user,
      },
    ) as List;
    return rows
        .map((row) => Spot.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// Satu spot untuk tautan yang dibagikan. Angka interaksi dimuat ulang
  /// saat halaman detail dibuka dari feed.
  Future<Spot?> spotById(String id) async {
    final row = await client
        .from('posts')
        .select(
          'id, owner_id, title, city, category, story, lat, lng, store_id, '
          'place_id, created_at, '
          'profiles(display_name, username, avatar_path), '
          'post_media(storage_path, media_type, position)',
        )
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final media =
        ((row['post_media'] as List?) ?? const [])
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList()
          ..sort(
            (a, b) => ((a['position'] as num?) ?? 0).compareTo(
              (b['position'] as num?) ?? 0,
            ),
          );
    return Spot.fromJson({
      ...row,
      'author': (row['profiles'] as Map?)?['display_name'] ?? 'Traveler',
      'author_username': (row['profiles'] as Map?)?['username'],
      'author_avatar': (row['profiles'] as Map?)?['avatar_path'],
      'media': [
        for (final m in media)
          {'path': m['storage_path'], 'type': m['media_type']},
      ],
    });
  }

  Future<List<SpotComment>> comments(String postId) async {
    final rows = await client
        .from('comments')
        .select('id,body,user_id,profiles(display_name,username,avatar_path)')
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(SpotComment.fromJson).toList();
  }

  Future<void> deleteComment(String commentId) async {
    if (userId == null) throw StateError('Masuk dulu ya.');
    await client.from('comments').delete().eq('id', commentId);
  }

  /// Semua dokumentasi di satu tempat, dari yang paling viral.
  Future<List<Spot>> placeSpots(String placeId) =>
      feed(mode: 'place', user: placeId);

  /// Tempat terdaftar di sekitar titik, untuk dipilih saat membuat spot.
  Future<List<Place>> nearbyPlaces(
    double lat,
    double lng, {
    String? query,
  }) async {
    final rows = await client.rpc(
      'nearby_places',
      params: {'p_lat': lat, 'p_lng': lng, 'p_radius_m': 300, 'p_query': query},
    ) as List;
    return rows
        .map((row) => Place.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> updateSpot(
    String spotId, {
    required String title,
    required String story,
  }) async {
    if (userId == null) throw StateError('Masuk dulu ya.');
    await client
        .from('posts')
        .update({'title': title.trim(), 'story': story.trim()})
        .eq('id', spotId);
  }

  /// Hapus spot milik sendiri beserta file fotonya.
  Future<void> deleteSpot(Spot spot) async {
    if (userId == null || spot.ownerId != userId) {
      throw StateError('Hanya pemilik yang bisa menghapus spot ini.');
    }
    final files = [
      for (final m in spot.media)
        if (!m.path.startsWith('http')) m.path,
    ];
    await client.from('posts').delete().eq('id', spot.id);
    if (files.isNotEmpty) {
      try {
        await client.storage.from('spot-media').remove(files);
      } catch (_) {}
    }
  }

  Future<void> addComment(String postId, String body) async {
    final id = userId;
    if (id == null) throw StateError('Masuk dulu untuk berkomentar.');
    await client.from('comments').insert({
      'post_id': postId,
      'user_id': id,
      'body': body.trim(),
    });
  }

  Future<void> setReaction(String postId, String kind, bool on) async {
    final id = userId;
    if (id == null) throw StateError('Masuk dulu untuk menyimpan tempat.');
    if (!on) {
      await client
          .from('reactions')
          .delete()
          .eq('user_id', id)
          .eq('post_id', postId)
          .eq('kind', kind);
    } else {
      await client.from('reactions').upsert({
        'user_id': id,
        'post_id': postId,
        'kind': kind,
      }, ignoreDuplicates: true);
    }
  }

  Future<void> rate(String postId, int score) async {
    final id = userId;
    if (id == null) throw StateError('Masuk dulu untuk memberi rating.');
    await client.from('ratings').upsert({
      'user_id': id,
      'post_id': postId,
      'score': score,
    });
  }

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
    final id = userId;
    if (id == null) throw StateError('Masuk dulu untuk membagikan spot.');
    if (files.isEmpty || files.length > 5) {
      throw StateError('Pilih 1 sampai 5 foto atau video.');
    }
    final place =
        placeId ??
        (await client
                .from('places')
                .insert({
                  'name': title.trim(),
                  'category': category,
                  'city': city.trim(),
                  'lat': lat,
                  'lng': lng,
                  'created_by': id,
                })
                .select('id')
                .single())['id']
            as String;
    final post = await client
        .from('posts')
        .insert({
          'owner_id': id,
          'title': title.trim(),
          'city': city.trim(),
          'category': category,
          'story': story.trim(),
          'lat': lat,
          'lng': lng,
          'store_id': ?storeId,
          'place_id': place,
        })
        .select('id')
        .single();
    final postId = post['id'] as String;
    final uploaded = <String>[];
    try {
      var total = 0;
      for (var index = 0; index < files.length; index++) {
        final file = files[index];
        final name = file.name.toLowerCase();
        final video = RegExp(r'\.(mp4|mov|webm)$').hasMatch(name);
        final extension = name.split('.').last;
        final allowed = video
            ? const ['mp4', 'mov', 'webm']
            : const ['jpg', 'jpeg', 'png', 'webp', 'heic'];
        if (!allowed.contains(extension)) {
          throw StateError('Format media tidak didukung.');
        }
        final size = await file.length();
        total += size;
        if (size > (video ? 40000000 : 8000000) || total > 80000000) {
          throw StateError('Batas foto 8 MB, video 40 MB, total 80 MB.');
        }
        final bytes = await file.readAsBytes();
        final path = '$id/$postId/$index.$extension';
        final contentType = switch (extension) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          'heic' => 'image/heic',
          'mp4' => 'video/mp4',
          'mov' => 'video/quicktime',
          _ => 'video/webm',
        };
        await client.storage
            .from('spot-media')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: contentType),
            );
        uploaded.add(path);
        await client.from('post_media').insert({
          'post_id': postId,
          'position': index,
          'storage_path': path,
          'media_type': video ? 'video' : 'image',
        });
      }
      if (tags.isNotEmpty) {
        await client.from('post_tags').insert([
          for (final user in tags.toSet()) {'post_id': postId, 'user_id': user},
        ]);
      }
    } catch (_) {
      try {
        if (uploaded.isNotEmpty) {
          await client.storage.from('spot-media').remove(uploaded);
        }
      } catch (_) {}
      try {
        await client.from('posts').delete().eq('id', postId);
      } catch (_) {}
      rethrow;
    }
  }

  // ---------- Marketplace ----------

  String _need() {
    final id = userId;
    if (id == null) throw StateError('Masuk dulu ya.');
    return id;
  }

  Future<List<Store>> stores({String? query, String? category}) async {
    var request = client.from('stores').select().eq('active', true);
    if (category != null) request = request.eq('category', category);
    final q = query?.trim() ?? '';
    if (q.isNotEmpty) {
      request = request.or('name.ilike.%$q%,address.ilike.%$q%');
    }
    final rows = await request
        .order('online_orders', ascending: false)
        .order('created_at', ascending: false)
        .limit(40);
    return rows.map(Store.fromJson).toList();
  }

  Future<List<Store>> storesNear(double lat, double lng) async {
    final rows = await client
        .from('stores')
        .select()
        .eq('active', true)
        .gte('lat', lat - .02)
        .lte('lat', lat + .02)
        .gte('lng', lng - .02)
        .lte('lng', lng + .02)
        .limit(20);
    return rows.map(Store.fromJson).toList();
  }

  Future<Store?> store(String id) async {
    final row = await client.from('stores').select().eq('id', id).maybeSingle();
    return row == null ? null : Store.fromJson(row);
  }

  Future<List<Product>> products(String storeId) async {
    final rows = await client
        .from('products')
        .select()
        .eq('store_id', storeId)
        .order('active', ascending: false)
        .order('name');
    return rows.map(Product.fromJson).toList();
  }

  Future<List<Product>> featuredProducts() async {
    final rows = await client
        .from('products')
        .select('*, stores!inner(name, online_orders, active)')
        .eq('active', true)
        .eq('stores.active', true)
        .gt('stock', 0)
        .order('created_at', ascending: false)
        .limit(12);
    return rows.map(Product.fromJson).toList();
  }

  String productImageUrl(String path) => publicMediaUrl(path);

  Future<Store?> myStore() async {
    final id = userId;
    if (id == null) return null;
    final row = await client
        .from('stores')
        .select()
        .eq('owner_id', id)
        .order('created_at')
        .limit(1)
        .maybeSingle();
    return row == null ? null : Store.fromJson(row);
  }

  Future<void> updateStore(Store store) =>
      client.from('stores').update(store.settings()).eq('id', store.id);

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
    final owner = _need();
    String? imagePath;
    if (image != null) {
      final extension = image.name.split('.').last.toLowerCase();
      if (!const ['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        throw StateError('Foto produk harus JPG, PNG, atau WEBP.');
      }
      final bytes = await image.readAsBytes();
      if (bytes.length > 8000000) {
        throw StateError('Foto produk maksimal 8 MB.');
      }
      imagePath = '$owner/products/${newRequestKey()}.$extension';
      await client.storage
          .from('spot-media')
          .uploadBinary(
            imagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: extension == 'jpg'
                  ? 'image/jpeg'
                  : 'image/$extension',
            ),
          );
    }
    final values = {
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'stock': stock,
      'active': active,
      'image_path': ?imagePath,
    };
    if (id == null) {
      await client.from('products').insert({...values, 'store_id': storeId});
    } else {
      await client.from('products').update(values).eq('id', id);
    }
  }

  Future<void> deleteProduct(String id) =>
      client.from('products').delete().eq('id', id);

  Future<List<StoreApplication>> myApplications() async {
    final id = userId;
    if (id == null) return [];
    final rows = await client
        .from('store_applications')
        .select()
        .eq('applicant_id', id)
        .order('created_at', ascending: false)
        .limit(10);
    return rows.map(StoreApplication.fromJson).toList();
  }

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
    _need();
    await client.from('store_applications').insert({
      'store_name': name.trim(),
      'category': category,
      'address': address.trim(),
      'lat': lat,
      'lng': lng,
      'contact': contact.trim(),
      'relation': relation,
      'note': note.trim(),
      'post_id': ?postId,
    });
  }

  Future<bool> isAdmin() async {
    final id = userId;
    if (id == null) return false;
    final row = await client
        .from('app_admins')
        .select('user_id')
        .eq('user_id', id)
        .maybeSingle();
    return row != null;
  }

  Future<List<StoreApplication>> pendingApplications() async {
    final rows = await client
        .from('store_applications')
        .select(
          '*, profiles!store_applications_applicant_id_fkey(display_name)',
        )
        .eq('status', 'menunggu')
        .order('created_at')
        .limit(50);
    return rows.map(StoreApplication.fromJson).toList();
  }

  Future<void> reviewApplication(String id, bool approve, [String? reason]) =>
      client.rpc(
        'review_store_application',
        params: {'p_application': id, 'p_approve': approve, 'p_reason': reason},
      );

  /// Mengembalikan id pesanan. Total dihitung ulang oleh database.
  Future<String> placeOrder({
    required Cart cart,
    required String fulfillment,
    required String address,
    required String note,
  }) async {
    _need();
    final shop = cart.store;
    if (shop == null || cart.lines.isEmpty) {
      throw StateError('Keranjang kosong.');
    }
    final fee = fulfillment == 'kirim' ? shop.deliveryFee : 0;
    final id = await client.rpc(
      'place_order',
      params: {
        'p_store': shop.id,
        'p_items': [
          for (final line in cart.lines.values)
            {'product_id': line.product.id, 'qty': line.qty},
        ],
        'p_fulfillment': fulfillment,
        'p_request_key': cart.requestKey,
        'p_address': address,
        'p_note': note,
        'p_expected_total': cart.subtotal + fee,
      },
    );
    return id as String;
  }

  static const _orderColumns =
      '*, stores(name, payment_info), order_items(*), '
      'profiles!orders_buyer_id_fkey(display_name)';

  Future<List<StoreOrder>> myOrders() async {
    final id = userId;
    if (id == null) return [];
    final rows = await client
        .from('orders')
        .select(_orderColumns)
        .eq('buyer_id', id)
        .order('created_at', ascending: false)
        .limit(30);
    return rows.map(StoreOrder.fromJson).toList();
  }

  Future<StoreOrder> order(String id) async {
    final row = await client
        .from('orders')
        .select(_orderColumns)
        .eq('id', id)
        .single();
    return StoreOrder.fromJson(row);
  }

  Future<List<StoreOrder>> storeOrders(String storeId) async {
    final rows = await client
        .from('orders')
        .select(_orderColumns)
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(StoreOrder.fromJson).toList();
  }

  /// Aksi pesanan: accept, reject, confirm_payment, advance, report_payment, cancel.
  Future<void> orderAction(String orderId, String action, [String? reason]) {
    final function = switch (action) {
      'accept' => 'accept_order',
      'reject' => 'reject_order',
      'confirm_payment' => 'confirm_payment',
      'advance' => 'advance_order',
      'report_payment' => 'report_payment',
      _ => 'cancel_order',
    };
    return client.rpc(
      function,
      params: {'p_order': orderId, if (action == 'reject') 'p_reason': reason},
    );
  }

  // ---------- Profil sosial ----------

  /// Alamat gambar profil; null jika belum ada foto.
  String? avatarUrl(String? path) =>
      path == null || path.isEmpty ? null : publicMediaUrl(path);

  static const _profileColumns =
      'id, username, display_name, bio, avatar_path, streak, best_streak';

  /// Menyimpan streak supaya tampil di profil untuk orang lain.
  Future<void> syncStreak(int streak) async {
    if (userId == null) return;
    await client.rpc('sync_streak', params: {'p_streak': streak});
  }

  Future<UserProfile?> profile(String id) async {
    final row = await client
        .from('profiles')
        .select(_profileColumns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : UserProfile.fromJson(row);
  }

  Future<UserProfile?> profileByUsername(String username) async {
    final row = await client
        .from('profiles')
        .select(_profileColumns)
        .eq('username', username.toLowerCase())
        .maybeSingle();
    return row == null ? null : UserProfile.fromJson(row);
  }

  Future<UserProfile?> myProfile() async {
    final id = userId;
    return id == null ? null : profile(id);
  }

  Future<ProfileStats> profileStats(String id) async {
    final rows =
        await client.rpc('profile_stats', params: {'p_user': id}) as List;
    return rows.isEmpty
        ? const ProfileStats()
        : ProfileStats.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  /// Orang yang belum diikuti, untuk "Saran teman".
  Future<List<UserProfile>> suggestedUsers({int limit = 8}) async {
    final me = userId;
    final skip = <String>{?me};
    if (me != null) {
      final rows = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', me);
      skip.addAll(rows.map((r) => r['following_id'] as String));
    }
    final rows = await client
        .from('profiles')
        .select(_profileColumns)
        .order('created_at', ascending: false)
        .limit(limit + skip.length);
    return rows
        .map(UserProfile.fromJson)
        .where((p) => !skip.contains(p.id))
        .take(limit)
        .toList();
  }

  /// Apakah akun yang sedang masuk mengikuti [ids].
  Future<Set<String>> followingAmong(List<String> ids) async {
    final me = userId;
    if (me == null || ids.isEmpty) return {};
    final rows = await client
        .from('follows')
        .select('following_id')
        .eq('follower_id', me)
        .inFilter('following_id', ids);
    return rows.map((r) => r['following_id'] as String).toSet();
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    final q = query.trim().replaceAll('@', '');
    if (q.isEmpty) return [];
    final rows = await client
        .from('profiles')
        .select(_profileColumns)
        .or('username.ilike.%$q%,display_name.ilike.%$q%')
        .limit(12);
    return rows.map(UserProfile.fromJson).where((p) => p.id != userId).toList();
  }

  Future<void> setFollow(String target, bool on) async {
    final me = _need();
    if (on) {
      await client.from('follows').upsert({
        'follower_id': me,
        'following_id': target,
      }, ignoreDuplicates: true);
    } else {
      await client
          .from('follows')
          .delete()
          .eq('follower_id', me)
          .eq('following_id', target);
    }
  }

  /// [followers] true untuk daftar pengikut, false untuk yang diikuti.
  Future<List<UserProfile>> followList(
    String id, {
    required bool followers,
  }) async {
    final rows = await client
        .from('follows')
        .select(
          followers
              ? 'profiles!follows_follower_id_fkey($_profileColumns)'
              : 'profiles!follows_following_id_fkey($_profileColumns)',
        )
        .eq(followers ? 'following_id' : 'follower_id', id)
        .order('created_at', ascending: false)
        .limit(100);
    return [
      for (final row in rows)
        if (row['profiles'] != null)
          UserProfile.fromJson(
            Map<String, dynamic>.from(row['profiles'] as Map),
          ),
    ];
  }

  Future<List<UserProfile>> taggedUsers(String postId) async {
    final rows = await client
        .from('post_tags')
        .select('profiles($_profileColumns)')
        .eq('post_id', postId);
    return [
      for (final row in rows)
        if (row['profiles'] != null)
          UserProfile.fromJson(
            Map<String, dynamic>.from(row['profiles'] as Map),
          ),
    ];
  }

  Future<void> updateProfile({
    required String displayName,
    required String username,
    required String bio,
    XFile? avatar,
  }) async {
    final me = _need();
    final handle = username.trim().toLowerCase();
    if (!usernamePattern.hasMatch(handle)) {
      throw StateError(
        'Username 3-20 karakter: huruf kecil, angka, titik, atau _.',
      );
    }
    if (displayName.trim().length < 2) {
      throw StateError('Nama minimal 2 huruf.');
    }
    String? avatarPath;
    if (avatar != null) {
      final extension = avatar.name.split('.').last.toLowerCase();
      if (!const ['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        throw StateError('Foto profil harus JPG, PNG, atau WEBP.');
      }
      final bytes = await avatar.readAsBytes();
      if (bytes.length > 5000000) {
        throw StateError('Foto profil maksimal 5 MB.');
      }
      avatarPath = '$me/avatar/${newRequestKey()}.$extension';
      await client.storage
          .from('spot-media')
          .uploadBinary(
            avatarPath,
            bytes,
            fileOptions: FileOptions(
              contentType: extension == 'jpg'
                  ? 'image/jpeg'
                  : 'image/$extension',
            ),
          );
    }
    try {
      await client
          .from('profiles')
          .update({
            'display_name': displayName.trim(),
            'username': handle,
            'bio': bio.trim(),
            'avatar_path': ?avatarPath,
          })
          .eq('id', me);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw StateError('Username @$handle sudah dipakai.');
      }
      rethrow;
    }
  }
}
