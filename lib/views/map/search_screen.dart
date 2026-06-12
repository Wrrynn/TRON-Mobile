import 'package:flutter/material.dart';

import '../post/post_detail_view.dart';
import 'widgets/search_panel.dart';

/// Halaman penuh Jelajahi/Cari (dibuka dari bottom-bar peta, di-push seperti
/// Buat Postingan). Berisi destinasi trending, pencarian, dan insight budget.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jelajahi')),
      body: SearchPanel(
        onOpenPost: (id) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailView(postId: id)),
        ),
      ),
    );
  }
}
