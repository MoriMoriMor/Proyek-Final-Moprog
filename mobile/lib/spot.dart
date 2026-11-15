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
  );
}

class SpotComment {
  const SpotComment({
    required this.author,
    required this.body,
    this.userId = '',
    this.username = '',
    this.avatar,
  });
  final String author, body, userId, username;
  final String? avatar;

  factory SpotComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map?;
    return SpotComment(
      author: profile?['display_name'] as String? ?? 'Traveler',
      body: json['body'] as String? ?? '',
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
