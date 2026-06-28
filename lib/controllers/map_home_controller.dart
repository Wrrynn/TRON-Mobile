import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/post.dart';
import '../services/api_client.dart';
import '../services/geocoding_service.dart';
import '../services/post_api.dart';

/// Postingan yang sudah punya koordinat → bisa ditandai di peta.
class MappedPost {
  final PostCard post;
  final LatLng point;
  const MappedPost(this.post, this.point);
}

/// Controller untuk dashboard peta (home). Memuat feed dari Laravel,
/// meng-geocode lokasi menjadi marker, dan menghitung fitur smart secara lokal.
class MapHomeController extends ChangeNotifier {
  final PostApi _postApi;
  final GeocodingService _geo;

  MapHomeController(this._postApi, this._geo);

  static const int _maxPages = 5; // batasi agar tidak menarik seluruh DB

  final List<PostCard> posts = [];
  final List<MappedPost> mapped = [];
  bool loading = true;
  bool geocoding = false;
  String? error;

  bool get isEmpty => posts.isEmpty && !loading;

  /// Muat feed (beberapa halaman) lalu geocode lokasi → marker peta.
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      posts.clear();
      mapped.clear();
      var page = 1;
      var hasMore = true;
      while (hasMore && page <= _maxPages) {
        final res = await _postApi.feed(page: page);
        posts.addAll(res.data);
        hasMore = res.hasMore;
        page++;
      }
      loading = false;
      notifyListeners();
      await _geocodeAll();
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
    } catch (_) {
      error = 'Gagal memuat peta perjalanan.';
      loading = false;
      notifyListeners();
    }
  }

  /// Geocode lokasi unik → tempatkan marker (progresif agar muncul bertahap).
  Future<void> _geocodeAll() async {
    geocoding = true;
    notifyListeners();

    final byLocation = <String, LatLng?>{};
    for (final p in posts) {
      final key = (p.location ?? '').trim().toLowerCase();
      if (key.isEmpty || byLocation.containsKey(key)) continue;
      byLocation[key] = await _geo.locate(p.location);
    }

    mapped.clear();
    for (final p in posts) {
      final key = (p.location ?? '').trim().toLowerCase();
      final point = byLocation[key];
      if (point != null) mapped.add(MappedPost(p, point));
    }

    geocoding = false;
    notifyListeners();
  }

  /// Pusat peta awal: rata-rata posisi marker, atau default Pulau Jawa.
  LatLng get initialCenter {
    if (mapped.isEmpty) return GeocodingService.defaultCenter;
    final lat = mapped.map((m) => m.point.latitude).reduce((a, b) => a + b) / mapped.length;
    final lng = mapped.map((m) => m.point.longitude).reduce((a, b) => a + b) / mapped.length;
    return LatLng(lat, lng);
  }

  /// Jejak Terpopuler — mengurutkan postingan berdasarkan rating tertinggi.
  List<PostCard> popularPosts({int limit = 5}) {
    // Buat salinan list agar tidak mengubah urutan asli pada feed
    final sorted = List<PostCard>.from(posts);
    
    sorted.sort((a, b) {
      // 1. Pengurutan Utama: Berdasarkan rating (descending / terbesar ke terkecil)
      final ratingA = a.rating ?? 0;
      final ratingB = b.rating ?? 0;
      final ratingCompare = ratingB.compareTo(ratingA);
      
      // Jika ratingnya berbeda, gunakan urutan rating ini
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      
      // 2. Pengurutan Sekunder (Tie-breaker): Jika rating SAMA, urutkan berdasarkan ID terbaru
      return a.id.compareTo(b.id);
    });
    
    return sorted.take(limit).toList();
  }

  /// Pencarian sederhana berdasarkan judul / lokasi / penulis.
  List<PostCard> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return posts.where((p) {
      return p.title.toLowerCase().contains(q) ||
          (p.location ?? '').toLowerCase().contains(q) ||
          p.author.toLowerCase().contains(q);
    }).toList();
  }
}
