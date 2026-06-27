import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import 'profile_view.dart'; // Memanggil file desain baru kita

/// Halaman penuh Profil (dibuka dari bottom-bar peta, di-push seperti Buat Postingan).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user;

    // Jika pengguna belum login, tampilkan layar peringatan kosong
    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(
          child: Text(
            'Tidak ada sesi pengguna.',
            style: TextStyle(color: AppColors.text2),
          ),
        ),
      );
    }

    // Jika pengguna sudah login, langsung arahkan ke ProfileView baru
    // Kita set showAppBar: true karena layar ini dipanggil sebagai halaman terpisah
    return ProfileView(
      userId: me.id,
      showAppBar: true, 
    );
  }
}