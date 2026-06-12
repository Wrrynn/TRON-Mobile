import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// Tampilan bintang rating. Jika [onRate] diisi, bintang menjadi interaktif.
class RatingStars extends StatelessWidget {
  final double value; // 0..5
  final double size;
  final int? selected; // sorotan pilihan user (mode interaktif)
  final void Function(int score)? onRate;

  const RatingStars({
    super.key,
    required this.value,
    this.size = 18,
    this.selected,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = onRate != null;
    final reference = (selected ?? value.round()).clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = interactive ? i < reference : i < value.round();
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? AppColors.star : AppColors.text3,
        );
        if (!interactive) return icon;
        return GestureDetector(
          onTap: () => onRate!(i + 1),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: icon,
          ),
        );
      }),
    );
  }
}
