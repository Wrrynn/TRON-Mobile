import 'package:flutter/foundation.dart';

import '../models/destination.dart';
import '../models/post.dart';
import '../services/api_client.dart';
import '../services/post_api.dart';

/// Controller form pembuatan postingan baru (termasuk foto & destinasi).
class CreatePostController extends ChangeNotifier {
  final PostApi _postApi;

  CreatePostController(this._postApi);

  final List<String> photoPaths = []; // path file lokal terpilih
  final List<Destination> destinations = [];
  bool submitting = false;
  String? error;

  void addPhoto(String path) {
    photoPaths.add(path);
    notifyListeners();
  }

  void removePhoto(int index) {
    photoPaths.removeAt(index);
    notifyListeners();
  }

  void addDestination(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    destinations.add(Destination(name: trimmed));
    notifyListeners();
  }

  void removeDestination(int index) {
    destinations.removeAt(index);
    notifyListeners();
  }

  /// Submit ke API. Mengembalikan PostDetail bila sukses, null bila gagal
  /// (pesan tersimpan di [error]).
  Future<PostDetail?> submit({
    required String title,
    String? location,
    String? story,
    int totalBudget = 0,
    String? travelDate,
  }) async {
    submitting = true;
    error = null;
    notifyListeners();
    try {
      final post = await _postApi.create(
        title: title,
        location: location,
        story: story,
        totalBudget: totalBudget,
        travelDate: travelDate,
        destinations: destinations,
        photoPaths: photoPaths,
      );
      return post;
    } on ApiException catch (e) {
      error = e.message;
      return null;
    } catch (_) {
      error = 'Gagal membuat postingan.';
      return null;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}
