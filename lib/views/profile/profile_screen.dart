import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../map/widgets/profile_panel.dart';
import '../post/post_detail_view.dart';

/// Halaman penuh Profil (dibuka dari bottom-bar peta, di-push seperti Buat Postingan).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: me == null
          ? const Center(
              child: Text('Tidak ada sesi pengguna.',
                  style: TextStyle(color: AppColors.text2)),
            )
          : ProfilePanel(
              userId: me.id,
              fallbackName: me.name,
              onOpenPost: (id) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PostDetailView(postId: id)),
              ),
              onLogout: () async {
                await context.read<AuthController>().logout();
                // Setelah logout, AuthGate menampilkan login; tutup halaman ini.
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
    );
  }
}
