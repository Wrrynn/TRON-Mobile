import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan token Bearer secara persisten (SharedPreferences).
class AuthStorage {
  static const _tokenKey = 'tripmo_token';

  String? _cachedToken;

  /// Token yang sedang aktif (di memori) — dibaca cepat tanpa async.
  String? get token => _cachedToken;
  bool get hasToken => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// Muat token dari disk saat aplikasi start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
  }

  Future<void> save(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clear() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
