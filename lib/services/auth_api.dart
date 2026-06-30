import '../models/user.dart';
import 'api_client.dart';
import 'auth_storage.dart';

/// Hasil otentikasi: user + token.
class AuthResult {
  final User user;
  final String token;
  const AuthResult(this.user, this.token);
}

/// Endpoint auth (register/login/logout/me).
class AuthApi {
  final ApiClient _client;
  final AuthStorage _storage;

  AuthApi(this._client, this._storage);

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _client.post('/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    return _handleAuth(json);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post('/login', body: {
      'email': email,
      'password': password,
    });
    return _handleAuth(json);
  }

  /// Data user yang sedang login (butuh token).
  Future<User> me() async {
    final json = await _client.get('/user');
    return User.fromJson(Map<String, dynamic>.from(json['user'] as Map));
  }

  /// Memperbarui nama dan/atau bio pengguna menggunakan metode POST
  Future<User> updateProfile({
    required String name,
    String? bio,
  }) async {
    final bodyData = <String, String>{
      'name': name,
    };
    
    // Hanya tambahkan bio ke request jika nilainya ada
    if (bio != null && bio.isNotEmpty) {
      bodyData['bio'] = bio;
    }

    final json = await _client.post('/user/update', body: bodyData);
    
    // Mengembalikan objek User terbaru dari response backend
    return User.fromJson(Map<String, dynamic>.from(json['user'] as Map));
  }

  /// Menghapus akun secara permanen dari server dan membersihkan sesi lokal
  Future<void> deleteAccount() async {
    // Memanggil endpoint DELETE /api/user
    await _client.delete('/user');
    
    // Membersihkan token lokal agar user langsung logout
    await _storage.clear();
  }

  /// Logout di server lalu hapus token lokal.
  Future<void> logout() async {
    try {
      await _client.post('/logout');
    } catch (_) {
      // walau gagal di server, tetap bersihkan token lokal
    }
    await _storage.clear();
  }

  Future<AuthResult> _handleAuth(dynamic json) async {
    final map = Map<String, dynamic>.from(json as Map);
    final token = map['token'] as String;
    await _storage.save(token);
    final user = User.fromJson(Map<String, dynamic>.from(map['user'] as Map));
    return AuthResult(user, token);
  }
}
