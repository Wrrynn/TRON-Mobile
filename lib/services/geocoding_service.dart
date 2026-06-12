import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Satu kandidat hasil pencarian lokasi (dipakai saat memilih destinasi).
class GeoPlace {
  final String name;
  final LatLng point;
  const GeoPlace(this.name, this.point);
}

/// Mengubah nama lokasi (string) menjadi koordinat peta.
///
/// Strategi berlapis agar marker selalu muncul tanpa bergantung jaringan:
///   1. Kamus kota/destinasi populer Indonesia (instan, offline).
///   2. Cache hasil sebelumnya (SharedPreferences, persisten).
///   3. Nominatim/OpenStreetMap (sama seperti web app) sebagai fallback.
class GeocodingService {
  GeocodingService();

  static const _cacheKey = 'geocode_cache_v1';
  final Map<String, LatLng?> _memory = {};
  bool _loaded = false;

  /// Kamus koordinat destinasi populer (lowercase). Substring-match.
  static const Map<String, LatLng> _dict = {
    'jakarta': LatLng(-6.2088, 106.8456),
    'bandung': LatLng(-6.9175, 107.6191),
    'surabaya': LatLng(-7.2575, 112.7521),
    'yogyakarta': LatLng(-7.7956, 110.3695),
    'jogja': LatLng(-7.7956, 110.3695),
    'semarang': LatLng(-6.9667, 110.4167),
    'medan': LatLng(3.5952, 98.6722),
    'makassar': LatLng(-5.1477, 119.4327),
    'denpasar': LatLng(-8.6705, 115.2126),
    'bali': LatLng(-8.4095, 115.1889),
    'ubud': LatLng(-8.5069, 115.2625),
    'kuta': LatLng(-8.7215, 115.1686),
    'malang': LatLng(-7.9839, 112.6214),
    'bogor': LatLng(-6.5950, 106.8166),
    'depok': LatLng(-6.4025, 106.7942),
    'bekasi': LatLng(-6.2383, 106.9756),
    'tangerang': LatLng(-6.1781, 106.6300),
    'solo': LatLng(-7.5755, 110.8243),
    'surakarta': LatLng(-7.5755, 110.8243),
    'lembang': LatLng(-6.8118, 107.6175),
    'dago': LatLng(-6.8862, 107.6133),
    'puncak': LatLng(-6.7000, 106.9667),
    'bromo': LatLng(-7.9425, 112.9530),
    'malioboro': LatLng(-7.7926, 110.3658),
    'borobudur': LatLng(-7.6079, 110.2038),
    'prambanan': LatLng(-7.7520, 110.4915),
    'labuan bajo': LatLng(-8.4964, 119.8877),
    'lombok': LatLng(-8.6500, 116.3249),
    'raja ampat': LatLng(-0.2346, 130.5076),
    'bandar lampung': LatLng(-5.3971, 105.2668),
    'lampung': LatLng(-5.4500, 105.2667),
    'padang': LatLng(-0.9471, 100.4172),
    'palembang': LatLng(-2.9761, 104.7754),
    'pekanbaru': LatLng(0.5071, 101.4478),
    'banjarmasin': LatLng(-3.3194, 114.5908),
    'balikpapan': LatLng(-1.2379, 116.8529),
    'samarinda': LatLng(-0.5022, 117.1536),
    'manado': LatLng(1.4748, 124.8421),
    'ambon': LatLng(-3.6954, 128.1814),
    'jayapura': LatLng(-2.5337, 140.7181),
    'batu': LatLng(-7.8672, 112.5239),
    'garut': LatLng(-7.2278, 107.9087),
    'cirebon': LatLng(-6.7320, 108.5523),
    'sukabumi': LatLng(-6.9277, 106.9300),
    'magelang': LatLng(-7.4706, 110.2178),
    'banyuwangi': LatLng(-8.2192, 114.3691),
    'gunung gede': LatLng(-6.7870, 106.9810),
    'gunung rinjani': LatLng(-8.4150, 116.4575),
    'rinjani': LatLng(-8.4150, 116.4575),
    'kawah putih': LatLng(-7.1660, 107.4020),
    'tana toraja': LatLng(-2.9700, 119.8900),
    'toraja': LatLng(-2.9700, 119.8900),
  };

  /// Pusat default peta (Pulau Jawa) ketika tak ada marker.
  static const LatLng defaultCenter = LatLng(-7.2, 110.0);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          if (v is List && v.length == 2) {
            _memory[k] = LatLng((v[0] as num).toDouble(), (v[1] as num).toDouble());
          }
        });
      }
    } catch (_) {/* abaikan cache rusak */}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      _memory.forEach((k, v) {
        if (v != null) map[k] = [v.latitude, v.longitude];
      });
      await prefs.setString(_cacheKey, jsonEncode(map));
    } catch (_) {/* abaikan */}
  }

  /// Cari koordinat untuk [location]. Null jika benar-benar tak ditemukan.
  Future<LatLng?> locate(String? location) async {
    if (location == null) return null;
    final q = location.trim().toLowerCase();
    if (q.isEmpty) return null;

    await _ensureLoaded();
    if (_memory.containsKey(q)) return _memory[q];

    // 1) Kamus offline (cek apakah ada kata kunci yang cocok).
    for (final entry in _dict.entries) {
      if (q.contains(entry.key)) {
        _memory[q] = entry.value;
        return entry.value;
      }
    }

    // 2) Nominatim/OSM (sama seperti web). Dibatasi Indonesia agar relevan.
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/search'
              '?q=${Uri.encodeComponent(location)}&format=json&limit=1&countrycodes=id',
            ),
            headers: {'User-Agent': 'TripmoMobile/1.0 (flutter app)'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final point = LatLng(
            double.parse(first['lat'].toString()),
            double.parse(first['lon'].toString()),
          );
          _memory[q] = point;
          await _persist();
          return point;
        }
      }
    } catch (_) {/* offline / rate-limited → null */}

    _memory[q] = null; // tandai miss agar tak dicari ulang berkali-kali
    return null;
  }

  /// Cari beberapa kandidat lokasi (untuk pemilih destinasi saat membuat post).
  Future<List<GeoPlace>> search(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final results = <GeoPlace>[];

    // Saran instan dari kamus.
    final ql = q.toLowerCase();
    for (final e in _dict.entries) {
      if (e.key.contains(ql)) {
        results.add(GeoPlace(_titleCase(e.key), e.value));
      }
    }

    try {
      final res = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/search'
              '?q=${Uri.encodeComponent(q)}&format=json&limit=$limit&countrycodes=id',
            ),
            headers: {'User-Agent': 'TripmoMobile/1.0 (flutter app)'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        for (final item in (jsonDecode(res.body) as List)) {
          final m = item as Map<String, dynamic>;
          final name = (m['display_name'] ?? '').toString();
          results.add(GeoPlace(
            name,
            LatLng(double.parse(m['lat'].toString()),
                double.parse(m['lon'].toString())),
          ));
        }
      }
    } catch (_) {/* abaikan */}

    // Hilangkan duplikat berdasarkan nama, batasi jumlah.
    final seen = <String>{};
    return results.where((p) => seen.add(p.name.toLowerCase())).take(limit).toList();
  }

  String _titleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}
