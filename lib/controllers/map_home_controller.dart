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

/// Item destinasi trending (lokasi terbanyak diposting + rata-rata rating).
class TrendingItem {
  final String location;
  final int count;
  final double? avgRating;
  const TrendingItem(this.location, this.count, this.avgRating);
}

/// Ringkasan budget pada suatu lokasi (statistik client-side seperti web app).
class BudgetInsight {
  final String location;
  final int trips;
  final int avg;
  final int min;
  final int max;
  final int q1;
  final int q3;
  const BudgetInsight({
    required this.location,
    required this.trips,
    required this.avg,
    required this.min,
    required this.max,
    required this.q1,
    required this.q3,
  });
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

  /// Destinasi trending — dikelompokkan per lokasi (meniru SmartSystemController).
  List<TrendingItem> trending({int limit = 8}) {
    final groups = <String, List<PostCard>>{};
    for (final p in posts) {
      final loc = (p.location ?? '').trim();
      if (loc.isEmpty) continue;
      groups.putIfAbsent(loc, () => []).add(p);
    }
    final items = groups.entries.map((e) {
      final ratings = e.value.map((p) => p.rating).whereType<double>().toList();
      final avg = ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length;
      return TrendingItem(e.key, e.value.length, avg);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return items.take(limit).toList();
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

  /// Statistik budget pada lokasi tertentu (meniru budgetInsight web app).
  BudgetInsight? budgetFor(String location) {
    final q = location.trim().toLowerCase();
    if (q.length < 2) return null;
    final values = posts
        .where((p) =>
            (p.location ?? '').toLowerCase().contains(q) && p.totalBudget > 0)
        .map((p) => p.totalBudget)
        .toList()
      ..sort();
    if (values.isEmpty) return null;
    final sum = values.reduce((a, b) => a + b);
    return BudgetInsight(
      location: location,
      trips: values.length,
      avg: (sum / values.length).round(),
      min: values.first,
      max: values.last,
      q1: _percentile(values, 25),
      q3: _percentile(values, 75),
    );
  }

  int _percentile(List<int> sorted, int pct) {
    final n = sorted.length;
    if (n == 0) return 0;
    if (n == 1) return sorted.first;
    final index = (pct / 100) * (n - 1);
    final lower = index.floor();
    final upper = index.ceil();
    final frac = index - lower;
    return (sorted[lower] + frac * (sorted[upper] - sorted[lower])).round();
  }
}
