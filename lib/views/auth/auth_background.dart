import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// Latar belakang halaman auth: gradient gelap + dua "glow" ungu yang
/// di-blur, memberi nuansa modern di belakang kartu kaca.
class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15131F), AppColors.bg, Color(0xFF0E1320)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -80, left: -60, child: _blob(AppColors.purple, 240)),
          Positioned(
              bottom: -100,
              right: -70,
              child: _blob(const Color(0xFF2563EB), 280)),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
