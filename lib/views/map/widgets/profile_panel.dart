import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../models/post.dart';
import '../../../services/post_api.dart';
import '../../../utils/formatters.dart';
import '../../widgets/avatar.dart';
import '../../widgets/network_photo.dart';

/// Isi panel Profil: avatar, statistik perjalanan, grid jejak, tombol keluar.
/// Memuat data lewat GET /api/users/{id} dan menghitung statistik di sisi klien
/// (meniru SmartSystemController::personalStats milik web app).
class ProfilePanel extends StatefulWidget {
  final int userId;
  final String fallbackName;
  final void Function(int postId) onOpenPost;
  final VoidCallback onLogout;

  const ProfilePanel({
    super.key,
    required this.userId,
    required this.fallbackName,
    required this.onOpenPost,
    required this.onLogout,
  });

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await context.read<PostApi>().userProfile(widget.userId);
      if (mounted) setState(() => _profile = p);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat profil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _profile == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.cloud_off_rounded, color: AppColors.text3, size: 40),
            const SizedBox(height: 12),
            Text(_error ?? 'Profil tidak ditemukan',
                style: const TextStyle(color: AppColors.text2)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    final p = _profile!;
    final handle = '@${p.name.toLowerCase().replaceAll(' ', '')}';
    final stats = _Stats.from(p.posts);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Avatar(name: p.name, photoUrl: p.photo, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(handle,
                      style: const TextStyle(
                          color: AppColors.text3, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        if (p.bio != null && p.bio!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(p.bio!, style: const TextStyle(color: AppColors.text2, height: 1.5)),
        ],
        const SizedBox(height: 20),
        // Statistik perjalanan.
        Row(
          children: [
            _StatBox(value: '${stats.totalTrips}', label: 'Jejak'),
            const SizedBox(width: 10),
            _StatBox(value: '${stats.uniqueCities}', label: 'Kota'),
            const SizedBox(width: 10),
            _StatBox(
                value: stats.avgRating == 0 ? '–' : stats.avgRating.toStringAsFixed(1),
                label: 'Rating',
                icon: Icons.star_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.purpleBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.purple, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total pengeluaran perjalanan',
                        style: TextStyle(color: AppColors.text2, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(Format.rupiah(stats.totalSpent),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              if (stats.favDestination != null)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Favorit',
                          style: TextStyle(color: AppColors.text2, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(stats.favDestination!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('Jejak Perjalanan',
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (p.posts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text('Belum ada postingan.\nKetuk + untuk mulai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text3, height: 1.5)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: p.posts.length,
            itemBuilder: (_, i) {
              final post = p.posts[i];
              return GestureDetector(
                onTap: () => widget.onOpenPost(post.id),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: NetworkPhoto(url: post.photo, width: 200, height: 200),
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Keluar dari Tripmo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text2,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
      ],
    );
  }
}

class _Stats {
  final int totalTrips;
  final int uniqueCities;
  final int totalSpent;
  final double avgRating;
  final String? favDestination;

  const _Stats({
    required this.totalTrips,
    required this.uniqueCities,
    required this.totalSpent,
    required this.avgRating,
    required this.favDestination,
  });

  factory _Stats.from(List<PostCard> posts) {
    final cities = <String>{};
    final freq = <String, int>{};
    var spent = 0;
    final ratings = <double>[];
    for (final p in posts) {
      final loc = (p.location ?? '').trim();
      if (loc.isNotEmpty) {
        cities.add(loc.toLowerCase());
        freq[loc] = (freq[loc] ?? 0) + 1;
      }
      spent += p.totalBudget;
      if (p.rating != null) ratings.add(p.rating!);
    }
    String? fav;
    var max = 0;
    freq.forEach((k, v) {
      if (v > max) {
        max = v;
        fav = k;
      }
    });
    return _Stats(
      totalTrips: posts.length,
      uniqueCities: cities.length,
      totalSpent: spent,
      avgRating: ratings.isEmpty
          ? 0
          : ratings.reduce((a, b) => a + b) / ratings.length,
      favDestination: fav,
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  const _StatBox({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  const Icon(Icons.star_rounded, size: 18, color: AppColors.star),
                  const SizedBox(width: 3),
                ],
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: AppColors.text3, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
