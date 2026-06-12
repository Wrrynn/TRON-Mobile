/// Pembungkus respons paginasi `{ data: [...], meta: {...} }` dari GET /api/posts.
class Paginated<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const Paginated({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final items = (json['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => itemFromJson(Map<String, dynamic>.from(e)))
        .toList();

    final meta = (json['meta'] as Map?) ?? const {};

    return Paginated(
      data: items,
      currentPage: (meta['current_page'] ?? 1) as int,
      lastPage: (meta['last_page'] ?? 1) as int,
      total: (meta['total'] ?? items.length) as int,
    );
  }
}
