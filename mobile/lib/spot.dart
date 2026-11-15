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
  });

  final String id, ownerId, author, title, city, category, story;
  final double lat, lng;
  final List<SpotMedia> media;
  final int likes, saves, comments;
  final double? distanceKm, rating;
  final bool liked, saved;

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
  );
}

class SpotComment {
  const SpotComment({required this.author, required this.body});
  final String author, body;

  factory SpotComment.fromJson(Map<String, dynamic> json) => SpotComment(
    author:
        (json['profiles'] as Map?)?['display_name'] as String? ?? 'Traveler',
    body: json['body'] as String? ?? '',
  );
}
