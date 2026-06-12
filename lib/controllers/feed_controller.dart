import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../services/api_client.dart';
import '../services/post_api.dart';

/// Controller feed: memuat daftar postingan dengan paginasi + pull-to-refresh.
class FeedController extends ChangeNotifier {
  final PostApi _postApi;

  FeedController(this._postApi);

  final List<PostCard> posts = [];
  bool loading = false; // muat awal
  bool loadingMore = false; // muat halaman berikutnya
  String? error;
  int _page = 1;
  bool _hasMore = true;

  bool get isEmpty => posts.isEmpty && !loading;

  /// Muat halaman pertama (sekaligus untuk pull-to-refresh).
  Future<void> refresh() async {
    loading = posts.isEmpty;
    error = null;
    _page = 1;
    _hasMore = true;
    notifyListeners();
    try {
      final result = await _postApi.feed(page: 1);
      posts
        ..clear()
        ..addAll(result.data);
      _hasMore = result.hasMore;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Gagal memuat feed.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Muat halaman berikutnya saat scroll mendekati bawah.
  Future<void> loadMore() async {
    if (loadingMore || !_hasMore || loading) return;
    loadingMore = true;
    notifyListeners();
    try {
      final result = await _postApi.feed(page: _page + 1);
      _page += 1;
      posts.addAll(result.data);
      _hasMore = result.hasMore;
    } catch (_) {
      // diamkan; baris "muat lagi" akan tampil ulang saat scroll
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  bool get hasMore => _hasMore;

  /// Hapus dari list secara lokal setelah delete sukses (tanpa refetch).
  void removeLocal(int id) {
    posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
