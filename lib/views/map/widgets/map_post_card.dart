import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../models/post.dart';
import '../../../utils/formatters.dart';
import '../../widgets/glass.dart';
import '../../widgets/network_photo.dart';

/// Kartu ringkas mengambang di atas peta saat sebuah marker dipilih.
class MapPostCard extends StatelessWidget {
  final PostCard post;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const MapPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: const BorderRadius.all(Radius.circular(20)),
      opacity: 0.6,
      shadow: Glass.floatingShadow,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: NetworkPhoto(url: post.photo, width: 64, height: 64),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.text2),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          post.location ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.text2, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (post.rating != null) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.star),
                        const SizedBox(width: 3),
                        Text(
                          post.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (post.totalBudget > 0)
                        Flexible(
                          child: Text(
                            Format.rupiah(post.totalBudget),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.text2),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
