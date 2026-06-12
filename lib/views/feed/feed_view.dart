import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/feed_controller.dart';
import '../post/post_detail_view.dart';
import '../widgets/state_views.dart';
import 'widgets/post_card_tile.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Muat feed pertama kali setelah frame pertama.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feed = context.read<FeedController>();
      if (feed.posts.isEmpty) feed.refresh();
    });
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 300) {
      context.read<FeedController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tripmo'),
        titleTextStyle: const TextStyle(
          color: AppColors.purple,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: () => feed.refresh(),
        child: _buildBody(feed),
      ),
    );
  }

  Widget _buildBody(FeedController feed) {
    if (feed.loading) return const LoadingView();

    if (feed.error != null && feed.posts.isEmpty) {
      return ListView(
        // ListView agar RefreshIndicator tetap bisa ditarik
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ErrorView(message: feed.error!, onRetry: feed.refresh),
          ),
        ],
      );
    }

    if (feed.isEmpty) {
      return ListView(
        children: const [
          SizedBox(
            height: 480,
            child: EmptyView(
              icon: Icons.explore_off_outlined,
              title: 'Belum ada postingan',
              subtitle: 'Jadilah yang pertama berbagi cerita perjalanan!',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: feed.posts.length + (feed.hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= feed.posts.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final post = feed.posts[i];
        return PostCardTile(
          post: post,
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => PostDetailView(postId: post.id),
              ),
            );
            // Jika postingan dihapus dari halaman detail, segarkan feed.
            if (changed == true && mounted) feed.refresh();
          },
        );
      },
    );
  }
}
