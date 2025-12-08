/// Represents the result of a paginated query from the backend,
/// allowing for the retrieval of pagination-related metadata on top of
/// the requested data
class PaginatedResult<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasNextPage;

  PaginatedResult({
    required this.items,
    this.nextCursor,
    this.hasNextPage = false,
  });

  factory PaginatedResult.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final dataList = (json['data'] as List).cast<Map<String, dynamic>>();
    final meta = json['meta'] as Map<String, dynamic>;
    final nextCursor = meta['after'] as String?;

    return PaginatedResult(
      items: dataList.map(fromJsonT).toList(),
      nextCursor: nextCursor,
      hasNextPage: (meta['has_next_page'] as bool?) ?? (nextCursor != null),
    );
  }
}
