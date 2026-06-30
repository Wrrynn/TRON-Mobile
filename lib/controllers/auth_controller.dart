import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../services/auth_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Controller otentikasi global — menjadi sumber kebenaran status login
/// untuk seluruh aplikasi (dipakai AuthGate, Profile, dll).
class AuthController extends ChangeNotifier {
  final AuthApi _authApi;
  final AuthStorage _storage;

  AuthController(this._authApi, this._storage);

  AuthStatus status = AuthStatus.unknown;
  User? user;
  bool busy = false;
  String? error;

  bool get isLoggedIn => status == AuthStatus.authenticated;

  // PERBAIKAN 1: Tambahkan getter agar _authApi bisa diakses oleh controller lain
  AuthApi get api => _authApi;

  /// Dipanggil saat start: jika ada token, ambil profil user.
  Future<void> bootstrap() async {
    await _storage.load();
    if (!_storage.hasToken) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await _authApi.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      await _storage.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) {
    return _run(() => _authApi.login(email: email, password: password));
  }

  Future<bool> register(String name, String email, String password) {
    return _run(() =>
        _authApi.register(name: name, email: email, password: password));
  }

  Future<void> logout() async {
    await _authApi.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // PERBAIKAN 2: Tambahkan fungsi untuk mengupdate data user di memori lokal
  // Fungsi ini dipanggil setelah proses edit profil berhasil di server
  void updateUser(User updatedUser) {
    user = updatedUser;
    notifyListeners(); // Memicu UI (seperti halaman profil) untuk me-refresh tampilannya
  }

  Future<bool> _run(Future<AuthResult> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await action();
      user = result.user;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Terjadi kesalahan tak terduga.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}