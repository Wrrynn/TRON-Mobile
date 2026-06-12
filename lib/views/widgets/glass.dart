import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// Kumpulan komponen "glassmorphism" modern — frosted glass via [BackdropFilter].
/// Dipakai untuk panel, bottom-bar, kartu mengambang di atas peta.
///
/// Mengacu pada `public/css/glass.css` & `dashboard.css` pada web app:
/// `backdrop-filter: blur(20px) saturate(145%)` dengan latar gelap transparan.
class Glass extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius radius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  const Glass({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.55,
    this.radius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.tint,
    this.border,
    this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Tint gelap transparan + sedikit gradient agar permukaan kaca terasa.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tint ?? const Color(0xFF14141C)).withValues(alpha: opacity + 0.06),
                (tint ?? const Color(0xFF0E0E14)).withValues(alpha: opacity),
              ],
            ),
            borderRadius: radius,
            border: border ??
                Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
          ),
          child: child,
        ),
      ),
    );

    if (shadow != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
        child: content,
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: content),
      );
    }
    return content;
  }

  /// Bayangan lembut standar untuk elemen mengambang di atas peta.
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Tombol ikon bundar bergaya kaca (dipakai di bottom-bar peta).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final String? tooltip;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.tooltip,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active
              ? AppColors.purple
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 22,
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Label "pill" kaca kecil (mis. badge koordinat / kategori).
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: const BorderRadius.all(Radius.circular(100)),
      opacity: 0.5,
      blur: 14,
      padding: padding,
      child: child,
    );
  }
}
