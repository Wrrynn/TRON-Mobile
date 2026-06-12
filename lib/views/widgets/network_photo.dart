import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// Gambar dari URL dengan caching + placeholder konsisten.
/// Bila [url] null/kosong, tampilkan placeholder ikon.
class NetworkPhoto extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  const NetworkPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final child = (url == null || url!.isEmpty)
        ? _placeholder(const Icon(Icons.image_outlined,
            color: AppColors.text3, size: 32))
        : CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => _placeholder(
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => _placeholder(
              const Icon(Icons.broken_image_outlined,
                  color: AppColors.text3, size: 32),
            ),
          );

    if (radius == null) return child;
    return ClipRRect(borderRadius: radius!, child: child);
  }

  Widget _placeholder(Widget center) => Container(
        width: width,
        height: height,
        color: AppColors.bg3,
        alignment: Alignment.center,
        child: center,
      );
}
