import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/post_api.dart';

/// Controller halaman profil (user sendiri maupun user lain).
class ProfileController extends ChangeNotifier {
  final PostApi _postApi;
  final int userId;

  ProfileController(this._postApi, this.userId);

  UserProfile? profile;
  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _postApi.userProfile(userId);
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Gagal memuat profil.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
