import 'package:flutter/material.dart';
import 'auth_controller.dart';

class EditProfileController extends ChangeNotifier {
  final AuthController _authController;
  final nameCtrl = TextEditingController();

  bool isLoading = false;
  String? error;

  EditProfileController(this._authController) {
    // Mengisi form dengan nama pengguna saat ini
    nameCtrl.text = _authController.user?.name ?? '';
  }

  Future<bool> saveProfile() async {
    if (nameCtrl.text.trim().isEmpty) {
      error = 'Nama tidak boleh kosong';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Memanggil fungsi updateProfile dari API yang sekarang sudah bisa diakses
      final updatedUser = await _authController.api.updateProfile(
        name: nameCtrl.text.trim(),
      );
      
      // Memperbarui data pengguna di memori lokal agar UI langsung berubah
      _authController.updateUser(updatedUser);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Memanggil fungsi deleteAccount dari API backend
      await _authController.api.deleteAccount();
      
      // PERBAIKAN 3: Gunakan fungsi logout() alih-alih clearUserState()
      // Fungsi ini akan membersihkan token, mengosongkan user, dan mengembalikan status unauthenticated
      await _authController.logout();

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }
}