import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../services/post_api.dart';
import '../widgets/avatar.dart';
import '../widgets/network_photo.dart';
import '../widgets/state_views.dart';
import '../post/post_detail_view.dart';
import 'edit_profile_view.dart';
import 'package:flutter/services.dart';

class ProfileView extends StatelessWidget {
  final int userId;
  final bool showAppBar;

  const ProfileView({super.key, required this.userId, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ProfileController(ctx.read<PostApi>(), userId)..load(),
      child: _ProfileBody(userId: userId, showAppBar: showAppBar),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final int userId;
  final bool showAppBar;
  
  const _ProfileBody({required this.userId, required this.showAppBar});

  Future<void> _logout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await context.read<AuthController>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();
    final isMe = context.watch<AuthController>().user?.id == userId;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(isMe ? 'Profil Saya' : (ctrl.profile?.name ?? 'Profil')),
              elevation: 0,
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: ctrl.load,
        child: _buildBody(context, ctrl, isMe),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileController ctrl, bool isMe) {
    if (ctrl.loading) return const LoadingView();
    if (ctrl.error != null) {
      return ErrorView(message: ctrl.error!, onRetry: ctrl.load);
    }
    final profile = ctrl.profile;
    if (profile == null) {
      return const EmptyView(title: 'Profil tidak ditemukan');
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // 1. Header Profil: Avatar dan Info 
        Row(
          children: [
            Avatar(name: profile.name, photoUrl: profile.photo, size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.name.toLowerCase().replaceAll(' ', '')}',
                    style: const TextStyle(color: AppColors.text2, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // 2. Statistik "Jejak"
        Center(
          child: Column(
            children: [
              Text(
                '${profile.posts.length}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Jejak',
                style: TextStyle(color: AppColors.text2, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. Tombol Aksi (Edit & Bagikan)
        if (isMe) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // Menuju ke halaman Edit Profil
                    final updated = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileView(),
                      ),
                    );
                    
                    // Jika profil berhasil diedit (kembali dengan nilai true), refresh data profil
                    if (updated == true && context.mounted) {
                       ctrl.load();
                    }
                  }, 
                  style: OutlinedButton.styleFrom( 
                    foregroundColor: AppColors.text2,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Edit Profil'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // 1. Tentukan link profil yang akan dibagikan
                    // Anda bisa mengubah URL ini sesuai dengan format routing web Anda
                    final profileLink = 'https://tripmo-jade.vercel.app/profile/${profile.id}';
                    
                    // 2. Salin link tersebut ke clipboard perangkat
                    await Clipboard.setData(ClipboardData(text: profileLink));
                    
                    // 3. Tampilkan dialog sukses persis seperti alert di web
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF222222), // Warna gelap khas aplikasi
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: const Text(
                            'tripmo-jade.vercel.app says', 
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Link profil berhasil disalin!', 
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }
                  }, 
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text2,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Bagikan Profil'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // Garis Pembatas
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),

        // 4. Grid Postingan (Foto Persegi)
        if (profile.posts.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyView(
              icon: Icons.photo_library_outlined,
              title: 'Belum ada jejak perjalanan',
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0, // Rasio 1:1 agar foto menjadi kotak sempurna
            ),
            itemCount: profile.posts.length,
            itemBuilder: (context, i) {
              final post = profile.posts[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailView(postId: post.id),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: NetworkPhoto(
                    url: post.photo,
                    width: double.infinity,
                    fit: BoxFit.cover, // Memotong foto agar proporsional mengisi kotak
                  ),
                ),
              );
            },
          ),
          
        const SizedBox(height: 48),

        // 5. Tombol Keluar di paling bawah
        if (isMe)
          OutlinedButton(
            onPressed: () => _logout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text2,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Keluar dari Tripmo'),
          ),
          
        const SizedBox(height: 32),
      ],
    );
  }
}