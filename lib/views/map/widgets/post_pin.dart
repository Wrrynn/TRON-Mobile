import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';

/// Penanda (pin) postingan di peta — bergaya teardrop ungu dengan glow.
class PostPin extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const PostPin({super.key, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.purple : const Color(0xFF8B6BFF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: active ? 1.18 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: active ? 0.7 : 0.45),
                    blurRadius: active ? 18 : 10,
                    spreadRadius: active ? 2 : 0,
                  ),
                ],
              ),
              child: const Icon(Icons.place, color: Colors.white, size: 16),
            ),
            // Ekor pin kecil.
            Transform.translate(
              offset: const Offset(0, -4),
              child: Transform.rotate(
                angle: 0.785398, // 45°
                child: Container(width: 8, height: 8, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
