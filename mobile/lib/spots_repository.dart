import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'spot.dart';

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
    );
    return response.session != null;
  }

  Future<void> signOut() => client.auth.signOut();
  String publicMediaUrl(String path) =>
      client.storage.from('spot-media').getPublicUrl(path);

  Future<List<Spot>> feed({
    double? lat,
    double? lng,
    String mode = 'near',
    String? category,
    String? query,
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
      },
    ) as List;
    return rows
        .map((row) => Spot.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<SpotComment>> comments(String postId) async {
    final rows = await client
        .from('comments')
        .select('body,profiles(display_name)')
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(SpotComment.fromJson).toList();
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
  }) async {
    final id = userId;
    if (id == null) throw StateError('Masuk dulu untuk membagikan spot.');
    if (files.isEmpty || files.length > 5) {
      throw StateError('Pilih 1 sampai 5 foto atau video.');
    }
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
}
