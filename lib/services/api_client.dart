import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:typed_data'; 
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_storage.dart';

/// Error API yang membawa pesan ramah untuk ditampilkan ke user.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors; // error validasi Laravel (422)

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

/// Klien HTTP low-level: menyisipkan header (Accept JSON + Bearer token),
/// menyatukan URL, dan menerjemahkan error menjadi [ApiException].
class ApiClient {
  final AuthStorage _storage;
  final http.Client _http;

  ApiClient(this._storage, {http.Client? client})
      : _http = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('${AppConfig.baseUrl}$path').replace(queryParameters: q);
  }

  Map<String, String> _headers({bool json = true}) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (_storage.hasToken) 'Authorization': 'Bearer ${_storage.token}',
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _send(() => _http
        .get(_uri(path, query), headers: _headers())
        .timeout(AppConfig.requestTimeout));
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    return _send(() => _http
        .post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}))
        .timeout(AppConfig.requestTimeout));
  }

  Future<dynamic> delete(String path) async {
    return _send(() => _http
        .delete(_uri(path), headers: _headers())
        .timeout(AppConfig.requestTimeout));
  }

  /// Multipart untuk upload (mis. membuat postingan dengan foto).
  /// [files] = daftar path lokal yang akan dikirim sebagai `photos[]`.
  Future<dynamic> multipart(
    String path, {
    required Map<String, String> fields,
    List<String> filePaths = const [],
    String fileField = 'photos[]',
  }) async {
    return _send(() async {
      final req = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields);
      for (final p in filePaths) {
        req.files.add(await http.MultipartFile.fromPath(fileField, p));
      }
      final streamed = await req.send().timeout(AppConfig.requestTimeout);
      return http.Response.fromStream(streamed);
    });
  }

  /// Jalankan request, lalu validasi status & parse JSON.
  Future<dynamic> _send(Future<http.Response> Function() run) async {
    final http.Response res;
    try {
      res = await run();
    } catch (e) {
      // PERBAIKAN: Cetak error asli ke terminal agar kita tahu penyebab pastinya
      debugPrint('ERROR ASLI API CLIENT: $e');
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi.');
    }

    final dynamic decoded = res.body.isEmpty ? null : _tryDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    // Format error standar Laravel.
    String message = 'Terjadi kesalahan (${res.statusCode}).';
    Map<String, dynamic>? errors;
    if (decoded is Map) {
      if (decoded['message'] is String) message = decoded['message'];
      if (decoded['errors'] is Map) {
        errors = Map<String, dynamic>.from(decoded['errors']);
        // ambil pesan validasi pertama agar lebih jelas
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
    }
    if (res.statusCode == 401) message = 'Sesi berakhir, silakan login lagi.';

    throw ApiException(message, statusCode: res.statusCode, errors: errors);
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
