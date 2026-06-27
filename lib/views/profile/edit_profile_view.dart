import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/edit_profile_controller.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => EditProfileController(ctx.read<AuthController>()),
      child: const _EditProfileBody(),
    );
  }
}

class _EditProfileBody extends StatelessWidget {
  const _EditProfileBody();

  Future<void> _confirmDelete(BuildContext context, EditProfileController ctrl) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Hapus Akun Permanen?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Semua data kamu akan hilang dan tidak bisa dikembalikan. Yakin ingin melanjutkan?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus Akun', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );

    if (yes == true && context.mounted) {
      final success = await ctrl.deleteAccount();
      if (success && context.mounted) {
        // Lakukan logout otomatis setelah akun terhapus
        await context.read<AuthController>().logout();
        Navigator.of(context).pop(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<EditProfileController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1E), // Background gelap utama
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF222222), // Warna background kartu web
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Nama
                Text(
                  'Nama',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl.nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF2A2A2A),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF7C5CFC)),
                    ),
                  ),
                ),
                
                // Pesan Error jika ada
                if (ctrl.error != null) ...[
                  const SizedBox(height: 6),
                  Text(ctrl.error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                ],

                const SizedBox(height: 20),

                // Tombol Batal dan Simpan
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.6),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Batal', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: ctrl.isLoading ? null : () async {
                          final success = await ctrl.saveProfile();
                          if (success && context.mounted) {
                            Navigator.pop(context, true); // Beri sinyal sukses untuk refresh
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C5CFC),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: ctrl.isLoading 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Simpan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                const SizedBox(height: 22),

                // Zona Berbahaya
                const Text(
                  'Zona Berbahaya',
                  style: TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Menghapus akun akan menghapus permanen seluruh postingan, foto, dan rating kamu. Tindakan ini tidak dapat dibatalkan.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _confirmDelete(context, ctrl),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFFF87171),
                      side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Hapus Akun Saya', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}