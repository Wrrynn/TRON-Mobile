import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../services/api_client.dart';
import '../services/post_api.dart';

/// Controller untuk satu halaman detail postingan (load, rating, hapus).
class PostDetailController extends ChangeNotifier {
  final PostApi _postApi;
  final int postId;

  PostDetailController(this._postApi, this.postId);

  PostDetail? post;
  bool loading = true;
  String? error;

  bool submittingRating = false;
  int? myRating; // rating sementara yang dipilih user di sesi ini

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      post = await _postApi.detail(postId);
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Gagal memuat detail postingan.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Kirim rating 1–5, lalu muat ulang agar rata-rata terbarui.
  Future<String?> rate(int score) async {
    submittingRating = true;
    myRating = score;
    notifyListeners();
    try {
      await _postApi.rate(postId, score);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal mengirim rating.';
    } finally {
      submittingRating = false;
      notifyListeners();
    }
  }

  /// Hapus postingan (hanya pemilik). Mengembalikan pesan error atau null jika sukses.
  Future<String?> delete() async {
    try {
      await _postApi.delete(postId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal menghapus postingan.';
    }
  }
}
