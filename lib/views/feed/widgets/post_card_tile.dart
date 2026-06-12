import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../models/post.dart';
import '../../../utils/formatters.dart';
import '../../widgets/network_photo.dart';

/// Kartu ringkasan satu postingan untuk feed/profil.
class PostCardTile extends StatelessWidget {
  final PostCard post;
  final VoidCallback onTap;

  const PostCardTile({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  NetworkPhoto(
                    url: post.photo,
                    height: 180,
                    width: double.infinity,
                  ),
                  if (post.photosCount > 1)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _badge(
                        icon: Icons.collections_outlined,
                        label: '${post.photosCount}',
                      ),
                    ),
                  if (post.rating != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: _badge(
                        icon: Icons.star_rounded,
                        label: post.rating!.toStringAsFixed(1),
                        iconColor: AppColors.star,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.text2),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.location ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.text2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'oleh ${post.author}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.text3, fontSize: 12),
                          ),
                        ),
                        if (post.totalBudget > 0)
                          Text(
                            Format.rupiah(post.totalBudget),
                            style: const TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
