import 'destination.dart';
import 'user.dart';

/// Ringkasan postingan untuk feed/profil — sesuai transformer `postCard()` di Laravel.
class PostCard {
  final int id;
  final String title;
  final String? location;
  final String? travelDate;
  final int totalBudget;
  final String author;
  final int authorId;
  final String? photo; // URL absolut (Cloudinary / storage) atau null
  final int photosCount;
  final double? rating;

  const PostCard({
    required this.id,
    required this.title,
    this.location,
    this.travelDate,
    required this.totalBudget,
    required this.author,
    required this.authorId,
    this.photo,
    required this.photosCount,
    this.rating,
  });

  factory PostCard.fromJson(Map<String, dynamic> json) {
    return PostCard(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      location: json['location'] as String?,
      travelDate: json['travel_date'] as String?,
      totalBudget: _toInt(json['total_budget']),
      author: (json['author'] ?? 'Unknown') as String,
      authorId: _toInt(json['author_id']),
      photo: json['photo'] as String?,
      photosCount: _toInt(json['photos_count']),
      rating: _toDouble(json['rating']),
    );
  }
}

/// Detail lengkap postingan — sesuai transformer `postDetail()` di Laravel.
class PostDetail {
  final int id;
  final String title;
  final String? location;
  final String? story;
  final String? travelDate;
  final int totalBudget;
  final List<Destination> destinations;
  final User author;
  final List<String> photos; // daftar URL absolut
  final double? rating;

  const PostDetail({
    required this.id,
    required this.title,
    this.location,
    this.story,
    this.travelDate,
    required this.totalBudget,
    required this.destinations,
    required this.author,
    required this.photos,
    this.rating,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    final destsRaw = json['destinations'];
    final dests = (destsRaw is List)
        ? destsRaw
            .whereType<Map>()
            .map((e) => Destination.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Destination>[];

    final photosRaw = json['photos'];
    final photos = (photosRaw is List)
        ? photosRaw.map((e) => e.toString()).toList()
        : <String>[];

    return PostDetail(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      location: json['location'] as String?,
      story: json['story'] as String?,
      travelDate: json['travel_date'] as String?,
      totalBudget: _toInt(json['total_budget']),
      destinations: dests,
      author: User.fromJson(Map<String, dynamic>.from(json['author'] as Map)),
      photos: photos,
      rating: _toDouble(json['rating']),
    );
  }
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
