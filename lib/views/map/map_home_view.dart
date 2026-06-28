import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/map_home_controller.dart';
import '../post/create_post_view.dart';
import '../post/post_detail_view.dart';
import '../profile/profile_screen.dart';
import '../widgets/glass.dart';
import 'search_screen.dart';
import 'widgets/map_post_card.dart';
import 'widgets/post_pin.dart';

/// Dashboard utama: peta full-screen + glass bottom-bar.
/// Tombol Profil & Cari membuka halaman penuh (di-push seperti Buat Postingan).
/// Meniru tampilan `dashboard/index.blade.php` pada web app.
class MapHomeView extends StatefulWidget {
  const MapHomeView({super.key});

  @override
  State<MapHomeView> createState() => _MapHomeViewState();
}

class _MapHomeViewState extends State<MapHomeView> {
  final MapController _map = MapController();
  MappedPost? _selected;
  bool _mapReady = false;

  // Tiles gelap CartoDB — sama seperti web app (dashboard.js).
  static const _tileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapHomeController>().load();
    });
  }

  void _selectMarker(MappedPost m) {
    setState(() => _selected = m);
    if (_mapReady) _map.move(m.point, _map.camera.zoom.clamp(11, 18));
  }

  /// Buka halaman penuh Profil (di-push seperti Buat Postingan).
  void _openProfile() {
    setState(() => _selected = null);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  /// Buka halaman penuh Jelajahi/Cari (di-push seperti Buat Postingan).
  void _openSearch() {
    setState(() => _selected = null);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostView()),
    );
    if (created == true && mounted) {
      context.read<MapHomeController>().load();
    }
  }

  void _openPost(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailView(postId: id)),
    ).then((changed) {
      if (changed == true && mounted) context.read<MapHomeController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MapHomeController>();

    return Scaffold(
      body: Stack(
        children: [
          // ── PETA ──
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: ctrl.initialCenter,
              initialZoom: 5.2,
              minZoom: 3,
              maxZoom: 18,
              backgroundColor: const Color(0xFF1B2533),
              onMapReady: () => setState(() => _mapReady = true),
              onTap: (_, __) => setState(() => _selected = null),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.tripmo.mobile',
                maxZoom: 19,
              ),
            ],
          ),

          // ── Gradient atas agar brand & status terbaca ──
          IgnorePointer(
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Brand chip (kiri-atas) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: const _BrandChip(),
          ),

          // ── Status geocoding / empty ──
          if (ctrl.geocoding)
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              right: 16,
              child: const GlassPill(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Menempatkan jejak...',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),

          if (ctrl.loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xCC121218),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          if (ctrl.error != null && ctrl.posts.isEmpty)
            Positioned.fill(child: _ErrorOverlay(message: ctrl.error!, onRetry: ctrl.load)),
            
          // ── Bottom bar glass ──
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 22,
            child: Center(child: _buildBottomBar()),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Glass(
          radius: const BorderRadius.all(Radius.circular(22)),
          opacity: 0.55,
          shadow: Glass.floatingShadow,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassIconButton(
                icon: Icons.person_outline_rounded,
                tooltip: 'Profil',
                onTap: _openProfile,
              ),
              const SizedBox(width: 4),
              GlassIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Cari',
                onTap: _openSearch,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Tombol buat (ungu solid mengambang).
        GestureDetector(
          onTap: _openCreate,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.purple,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: const BorderRadius.all(Radius.circular(100)),
      opacity: 0.5,
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.travel_explore_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text('Tripmo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorOverlay({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC121218),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.text3, size: 48),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text2)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
