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

class ProfileView extends StatelessWidget {
  final int userId;

  /// [showAppBar] dimatikan saat dipakai sebagai tab (RootNav punya konteks sendiri).
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
      appBar: showAppBar || isMe
          ? AppBar(
              title: Text(isMe ? 'Profil Saya' : (ctrl.profile?.name ?? 'Profil')),
              automaticallyImplyLeading: showAppBar,
              actions: [
                if (isMe)
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Keluar',
                    onPressed: () => _logout(context),
                  ),
              ],
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: ctrl.load,
        child: _buildBody(context, ctrl),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileController ctrl) {
    if (ctrl.loading) return const LoadingView();
    if (ctrl.error != null) {
      return ErrorView(message: ctrl.error!, onRetry: ctrl.load);
    }
    final profile = ctrl.profile;
    if (profile == null) {
      return const EmptyView(title: 'Profil tidak ditemukan');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Avatar(name: profile.name, photoUrl: profile.photo, size: 88),
              const SizedBox(height: 12),
              Text(
                profile.name,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  profile.bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text2),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purpleBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${profile.posts.length} postingan',
                  style: const TextStyle(
                      color: AppColors.purple, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (profile.posts.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyView(
              icon: Icons.photo_library_outlined,
              title: 'Belum ada postingan',
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
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
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: NetworkPhoto(
                          url: post.photo,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
