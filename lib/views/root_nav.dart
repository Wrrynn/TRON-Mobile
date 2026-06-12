import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/feed_controller.dart';
import 'feed/feed_view.dart';
import 'post/create_post_view.dart';
import 'profile/profile_view.dart';

/// Kerangka utama setelah login: tab Beranda & Profil + tombol buat postingan.
class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostView()),
    );
    if (created == true && mounted) {
      setState(() => _index = 0);
      context.read<FeedController>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user;

    final tabs = [
      const FeedView(),
      if (me != null)
        ProfileView(userId: me.id, showAppBar: false)
      else
        const SizedBox.shrink(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
