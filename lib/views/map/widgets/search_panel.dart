import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../controllers/map_home_controller.dart';
import '../../../models/post.dart';
import '../../widgets/network_photo.dart';

/// Isi panel Cari: jejak terpopuler + kotak pencarian + hasil.
class SearchPanel extends StatefulWidget {
  final void Function(int postId) onOpenPost;

  const SearchPanel({super.key, required this.onOpenPost});

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String v) => setState(() => _query = v);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MapHomeController>();
    final results = ctrl.search(_query);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Kotak pencarian glass
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: TextField(
            controller: _controller,
            onChanged: _setQuery,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari lokasi, destinasi...',
              hintStyle: const TextStyle(color: AppColors.text3),
              border: InputBorder.none,
              // Memasukkan ikon langsung ke dalam TextField agar jaraknya presisi
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.text2, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        _setQuery('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.text2),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_query.trim().isEmpty) ...[
          // Teks Header untuk Jejak Terpopuler
          const _PanelHeading(icon: Icons.star_rounded, text: 'Jejak Terpopuler', iconColor: Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          ..._buildPopular(ctrl),
        ] else ...[
          _PanelHeading(
              icon: Icons.travel_explore_rounded,
              text: '${results.length} hasil untuk "$_query"',
              iconColor: AppColors.purple,
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('Tidak ada jejak yang cocok.',
                    style: TextStyle(color: AppColors.text3)),
              ),
            )
          else
            ...results.map((p) => _PopularPostTile(
                  post: p,
                  onTap: () => widget.onOpenPost(p.id),
                )),
        ],
      ],
    );
  }

  List<Widget> _buildPopular(MapHomeController ctrl) {
    final items = ctrl.popularPosts();
    if (items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Text('Belum ada jejak terpopuler.',
                style: TextStyle(color: AppColors.text3)),
          ),
        ),
      ];
    }
    return items.map((p) => _PopularPostTile(
      post: p,
      onTap: () => widget.onOpenPost(p.id),
    )).toList();
  }
}

class _PanelHeading extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  
  const _PanelHeading({required this.icon, required this.text, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// Desain kartu baru yang meniru layout "Jejak Terpopuler" di versi Web
class _PopularPostTile extends StatelessWidget {
  final PostCard post;
  final VoidCallback onTap;
  
  const _PopularPostTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Menyiapkan teks subtitle: "Lokasi · oleh Penulis"
    final locationText = (post.location != null && post.location!.isNotEmpty) ? post.location! : 'Lokasi tidak diketahui';
    final subtitle = '$locationText · oleh ${post.author}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.04), // Latar belakang gelap transparan
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Bagian Thumbnail Kiri (Gambar atau Ikon Pin)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: post.photo != null
                      ? NetworkPhoto(url: post.photo, width: 48, height: 48, fit: BoxFit.cover)
                      : Container(
                          width: 48,
                          height: 48,
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Center(
                            child: Icon(Icons.push_pin_rounded, color: Color(0xFFEF4444), size: 20), // Pin merah
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                
                // Bagian Teks Tengah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.text3, fontSize: 12)),
                    ],
                  ),
                ),
                
                // Bagian Rating Kanan (Bintang)
                if (post.rating != null && post.rating! > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(post.rating!.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.text2, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}