import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../controllers/map_home_controller.dart';
import '../../../models/post.dart';
import '../../../utils/formatters.dart';
import '../../widgets/network_photo.dart';

/// Isi panel Cari: destinasi trending + kotak pencarian + hasil + insight budget.
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
        // Kotak pencarian glass.
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search_rounded, color: AppColors.text2, size: 20),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: _setQuery,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Cari lokasi, destinasi, penulis...',
                    hintStyle: TextStyle(color: AppColors.text3),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _controller.clear();
                    _setQuery('');
                  },
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.text2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_query.trim().isEmpty) ...[
          const _PanelHeading(icon: Icons.local_fire_department_rounded, text: 'Destinasi Trending'),
          const SizedBox(height: 12),
          ..._buildTrending(ctrl),
        ] else ...[
          _PanelHeading(
              icon: Icons.travel_explore_rounded,
              text: '${results.length} hasil untuk "$_query"'),
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
            ...results.map((p) => _ResultTile(
                  post: p,
                  onTap: () => widget.onOpenPost(p.id),
                )),
        ],
      ],
    );
  }

  List<Widget> _buildTrending(MapHomeController ctrl) {
    final items = ctrl.trending();
    if (items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Text('Belum ada data trending.',
                style: TextStyle(color: AppColors.text3)),
          ),
        ),
      ];
    }
    return [
      for (var i = 0; i < items.length; i++)
        _TrendingTile(
          rank: i + 1,
          item: items[i],
          onTap: () {
            _controller.text = items[i].location;
            _setQuery(items[i].location);
          },
        ),
    ];
  }
}

class _PanelHeading extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PanelHeading({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.purple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _TrendingTile extends StatelessWidget {
  final int rank;
  final TrendingItem item;
  final VoidCallback onTap;
  const _TrendingTile({required this.rank, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? AppColors.purpleBg : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$rank',
                      style: TextStyle(
                          color: rank <= 3 ? AppColors.purple : AppColors.text2,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                if (item.avgRating != null) ...[
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                  const SizedBox(width: 3),
                  Text(item.avgRating!.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.text2, fontSize: 12)),
                  const SizedBox(width: 10),
                ],
                Text('${item.count} jejak',
                    style: const TextStyle(color: AppColors.text3, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final PostCard post;
  final VoidCallback onTap;
  const _ResultTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: NetworkPhoto(url: post.photo, width: 52, height: 52),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(post.location ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.text3, fontSize: 12)),
                    ],
                  ),
                ),
                if (post.rating != null) ...[
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                  const SizedBox(width: 3),
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
