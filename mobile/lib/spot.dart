import 'dart:math' as math;

class SpotMedia {
  const SpotMedia({required this.path, required this.type});
  final String path;
  final String type;

  factory SpotMedia.fromJson(Map<String, dynamic> json) => SpotMedia(
    path: json['path'] as String? ?? '',
    type: json['type'] as String? ?? 'image',
  );
}

class Spot {
  const Spot({
    required this.id,
    required this.ownerId,
    required this.author,
    required this.title,
    required this.city,
    required this.category,
    required this.story,
    required this.lat,
    required this.lng,
    required this.media,
    required this.likes,
    required this.saves,
    required this.comments,
    required this.liked,
    required this.saved,
    this.distanceKm,
    this.rating,
    this.storeId,
    this.authorUsername = '',
    this.authorAvatar,
    this.createdAt,
    this.placeId,
  });

  final String id, ownerId, author, title, city, category, story;
  final double lat, lng;
  final List<SpotMedia> media;
  final int likes, saves, comments;
  final double? distanceKm, rating;
  final bool liked, saved;
  final String? storeId;
  final String authorUsername;
  final String? authorAvatar;
  final DateTime? createdAt;

  /// Tempat yang dipilih pengunggah. Beberapa spot bisa berbagi satu tempat.
  final String? placeId;

  /// Seberapa ramai spot ini: like paling berbobot, lalu simpan, komentar,
  /// dan rating.
  double get engagement =>
      likes * 3 + saves * 2 + comments * 2 + (rating ?? 0) * 2;

  /// Skor viral: keramaian dibagi umur postingan (sama seperti di database),
  /// supaya spot lama tidak menempati puncak selamanya.
  double viralScore([DateTime? now]) {
    final created = createdAt;
    final days = created == null
        ? 7.0
        : ((now ?? DateTime.now()).difference(created).inMinutes / 1440)
              .clamp(0, 3650)
              .toDouble();
    return (engagement + 1) / math.pow(days + 2, .7);
  }

  Spot copyWith({String? title, String? story}) => Spot(
    id: id,
    ownerId: ownerId,
    author: author,
    title: title ?? this.title,
    city: city,
    category: category,
    story: story ?? this.story,
    lat: lat,
    lng: lng,
    media: media,
    likes: likes,
    saves: saves,
    comments: comments,
    liked: liked,
    saved: saved,
    distanceKm: distanceKm,
    rating: rating,
    storeId: storeId,
    authorUsername: authorUsername,
    authorAvatar: authorAvatar,
    createdAt: createdAt,
    placeId: placeId,
  );

  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
    id: json['id'] as String,
    ownerId: json['owner_id'] as String,
    author: json['author'] as String? ?? 'Traveler',
    title: json['title'] as String? ?? '',
    city: json['city'] as String? ?? '',
    category: json['category'] as String? ?? 'destinasi',
    story: json['story'] as String? ?? '',
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    media: ((json['media'] as List?) ?? const [])
        .map(
          (item) => SpotMedia.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    likes: (json['likes'] as num?)?.toInt() ?? 0,
    saves: (json['saves'] as num?)?.toInt() ?? 0,
    comments: (json['comment_count'] as num?)?.toInt() ?? 0,
    liked: json['liked'] as bool? ?? false,
    saved: json['saved'] as bool? ?? false,
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    rating: (json['rating'] as num?)?.toDouble(),
    storeId: json['store_id'] as String?,
    authorUsername: json['author_username'] as String? ?? '',
    authorAvatar: json['author_avatar'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    placeId: json['place_id'] as String?,
  );
}

/// Tempat terdaftar yang bisa dipilih saat membuat spot.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.city = '',
    this.distanceM = 0,
    this.posts = 0,
    this.people = 0,
    this.cover,
  });
  final String id, name, category, city;
  final double lat, lng, distanceM;
  final int posts, people;
  final String? cover;

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? 'destinasi',
    city: json['city'] as String? ?? '',
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0,
    posts: (json['posts'] as num?)?.toInt() ?? 0,
    people: (json['people'] as num?)?.toInt() ?? 0,
    cover: json['cover'] as String?,
  );
}

class SpotComment {
  const SpotComment({
    required this.author,
    required this.body,
    this.id = '',
    this.userId = '',
    this.username = '',
    this.avatar,
  });
  final String id, author, body, userId, username;
  final String? avatar;

  factory SpotComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map?;
    return SpotComment(
      author: profile?['display_name'] as String? ?? 'Traveler',
      body: json['body'] as String? ?? '',
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: profile?['username'] as String? ?? '',
      avatar: profile?['avatar_path'] as String?,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.avatarPath,
    this.streak = 0,
    this.bestStreak = 0,
  });
  final String id, username, displayName, bio;
  final String? avatarPath;
  final int streak, bestStreak;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? 'Traveler',
    bio: json['bio'] as String? ?? '',
    avatarPath: json['avatar_path'] as String?,
    streak: (json['streak'] as num?)?.toInt() ?? 0,
    bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
  );
}

class ProfileStats {
  const ProfileStats({
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.likes = 0,
    this.saves = 0,
    this.cities = 0,
    this.isFollowing = false,
  });
  final int posts, followers, following, likes, saves, cities;
  final bool isFollowing;

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return ProfileStats(
      posts: n('posts'),
      followers: n('followers'),
      following: n('following'),
      likes: n('likes'),
      saves: n('saves'),
      cities: n('cities'),
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }
}

/// Username: huruf kecil, angka, titik, atau garis bawah; 3 sampai 20 karakter.
final usernamePattern = RegExp(r'^[a-z0-9_.]{3,20}$');
final mentionPattern = RegExp(r'@([a-z0-9_.]{3,20})');

class QuestProgressItem {
  const QuestProgressItem({
    required this.key,
    required this.progress,
    required this.claimed,
  });
  final String key;
  final int progress;
  final bool claimed;

  factory QuestProgressItem.fromJson(Map<String, dynamic> json) =>
      QuestProgressItem(
        key: json['key'] as String? ?? '',
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        claimed: json['claimed'] as bool? ?? false,
      );
}

class ServerGameState {
  const ServerGameState({
    required this.xp,
    required this.streak,
    required this.bestStreak,
    required this.day,
    required this.quests,
  });
  final int xp, streak, bestStreak;
  final String day;
  final Map<String, QuestProgressItem> quests;

  factory ServerGameState.fromJson(Map<String, dynamic> json) {
    final rawQuests = (json['quests'] as List?) ?? const [];
    final map = <String, QuestProgressItem>{};
    for (final item in rawQuests) {
      final parsed = QuestProgressItem.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (parsed.key.isNotEmpty) map[parsed.key] = parsed;
    }
    return ServerGameState(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      day: json['day'] as String? ?? '',
      quests: map,
    );
  }
}

class GameActionResult {
  const GameActionResult({
    required this.xp,
    required this.gained,
    this.finishedQuest,
  });
  final int xp, gained;
  final String? finishedQuest;

  factory GameActionResult.fromJson(Map<String, dynamic> json) =>
      GameActionResult(
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        gained: (json['gained'] as num?)?.toInt() ?? 0,
        finishedQuest: json['finished_quest'] as String?,
      );
}
