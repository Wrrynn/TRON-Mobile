import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/post_detail_controller.dart';
import '../../models/post.dart';
import '../../services/post_api.dart';
import '../../utils/formatters.dart';
import '../profile/profile_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/rating_stars.dart';
import '../widgets/route_map.dart';
import '../widgets/state_views.dart';
import 'edit_post_view.dart';

class PostDetailView extends StatelessWidget {
  final int postId;
  const PostDetailView({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          PostDetailController(ctx.read<PostApi>(), postId)..load(),
      child: const _PostDetailBody(),
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  const _PostDetailBody();

  Future<void> _confirmDelete(BuildContext context) async {
    final ctrl = context.read<PostDetailController>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Hapus postingan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    final err = await ctrl.delete();
    if (!context.mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true); // beri tahu feed untuk refresh
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _rate(BuildContext context, int score) async {
    final err = await context.read<PostDetailController>().rate(score);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Rating tersimpan. Terima kasih!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PostDetailController>();
    final currentUserId = context.watch<AuthController>().user?.id;
    final post = ctrl.post;
    final isOwner = post != null && post.author.id == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(post?.title ?? 'Detail'),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Postingan',
              onPressed: () async {
                // Navigasi ke halaman edit dan tunggu hasilnya
                final updated = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditPostView(post: post),
                  ),
                );
                
                // Jika postingan berhasil diupdate, refresh data di halaman detail ini
                if (updated == true && context.mounted) {
                  ctrl.load();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.red,
              onPressed: () => _confirmDelete(context),
            ),
          ]
        ],
      ),
      body: _buildBody(context, ctrl, post),
    );
  }

  Widget _buildBody(
      BuildContext context, PostDetailController ctrl, PostDetail? post) {
    if (ctrl.loading) return const LoadingView();
    if (ctrl.error != null) {
      return ErrorView(message: ctrl.error!, onRetry: ctrl.load);
    }
    if (post == null) {
      return const EmptyView(title: 'Postingan tidak ditemukan');
    }

    return ListView(
      children: [
        _PhotoCarousel(photos: post.photos),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: post.location ?? '-'),
              const SizedBox(height: 4),
              _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: Format.tanggal(post.travelDate)),
              if (post.totalBudget > 0) ...[
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.account_balance_wallet_outlined,
                  text: Format.rupiah(post.totalBudget),
                  color: AppColors.purple,
                ),
              ],
              const SizedBox(height: 16),
              _AuthorChip(
                author: post.author,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileView(userId: post.author.id),
                  ),
                ),
              ),
              if (post.story != null && post.story!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionTitle('Cerita'),
                const SizedBox(height: 8),
                Text(
                  post.story!,
                  style: const TextStyle(
                      color: AppColors.text, height: 1.6, fontSize: 15),
                ),
              ],
              if (post.destinations.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionTitle('Rute Destinasi'),
                const SizedBox(height: 10),
                if (post.destinations.any((d) => d.lat != null && d.lng != null)) ...[
                  RouteMap(destinations: post.destinations),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: post.destinations
                      .map((d) => Chip(
                            label: Text(d.name),
                            backgroundColor: AppColors.bg3,
                            side: const BorderSide(color: AppColors.border2),
                            avatar: const Icon(Icons.place_outlined,
                                size: 16, color: AppColors.purple),
                            labelStyle: const TextStyle(color: AppColors.text),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              _RatingSection(ctrl: ctrl, onRate: (s) => _rate(context, s)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  final List<String> photos;
  const _PhotoCarousel({required this.photos});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const NetworkPhoto(url: null, height: 260, width: double.infinity);
    }
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => NetworkPhoto(
              url: widget.photos[i],
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (widget.photos.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.purple : AppColors.text3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _RatingSection extends StatelessWidget {
  final PostDetailController ctrl;
  final void Function(int score) onRate;

  const _RatingSection({required this.ctrl, required this.onRate});

  @override
  Widget build(BuildContext context) {
    final post = ctrl.post!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                post.rating?.toStringAsFixed(1) ?? '–',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              RatingStars(value: post.rating ?? 0, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Beri rating perjalanan ini:',
              style: TextStyle(color: AppColors.text2)),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingStars(
                value: 0,
                size: 32,
                selected: ctrl.myRating,
                onRate: ctrl.submittingRating ? null : onRate,
              ),
              if (ctrl.submittingRating) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthorChip extends StatelessWidget {
  final dynamic author; // User
  final VoidCallback onTap;
  const _AuthorChip({required this.author, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.purpleBg,
              child: Icon(Icons.person, color: AppColors.purple, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author.name,
                    style: const TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w600)),
                const Text('Lihat profil',
                    style: TextStyle(color: AppColors.purple, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow({required this.icon, required this.text, this.color = AppColors.text2});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(color: color, fontSize: 14)),
        ),
      ],
    );
  }
}
