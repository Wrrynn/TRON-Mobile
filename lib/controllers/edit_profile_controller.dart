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
      // TODO: Panggil fungsi API Anda di sini untuk mengupdate nama
      // Contoh: await _api.updateProfile(name: nameCtrl.text.trim());
      
      // Simulasi delay jaringan (hapus ini saat dihubungkan ke API)
      await Future.delayed(const Duration(seconds: 1));

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
      // TODO: Panggil fungsi API Anda di sini untuk menghapus akun
      // Contoh: await _api.deleteAccount();
      
      // Simulasi delay jaringan
      await Future.delayed(const Duration(seconds: 1));

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