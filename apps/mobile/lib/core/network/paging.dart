import '../errors/app_failure.dart';
import '../errors/result.dart';
import 'json.dart';

/// A page of a server-paged list: `{rows, total, counts?}` (`routes/students.ts`, `billingViews.ts`).
/// [counts] feed filter-chip badges; the server computes them.
class Paged<T> {
  const Paged({required this.rows, required this.total, this.counts = const {}});

  factory Paged.fromJson(
    String endpoint,
    Object? body,
    T Function(Map<String, dynamic> json) parseRow,
  ) {
    final map = asJsonObject(endpoint, body);
    return parseResponse(endpoint, map, (_) {
      final counts = map['counts'];
      return Paged<T>(
        rows: [
          for (final row in asJsonList(endpoint, map['rows']))
            parseRow(row as Map<String, dynamic>),
        ],
        total: (map['total']! as num).toInt(),
        counts: counts is Map
            ? {for (final e in counts.entries) '${e.key}': (e.value as num).toInt()}
            : const {},
      );
    });
  }

  final List<T> rows;
  final int total;
  final Map<String, int> counts;
}

/// Everything a paged list screen renders (§10.5).
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.total = 0,
    this.counts = const {},
    this.nextPage = 1,
    this.loading = false,
    this.failure,
    this.loadedOnce = false,
  });

  final List<T> items;
  final int total;
  final Map<String, int> counts;
  final int nextPage;
  final bool loading;

  /// The last load's failure; items already loaded stay visible.
  final AppFailure? failure;
  final bool loadedOnce;

  bool get hasMore => !loadedOnce || items.length < total;
  bool get isEmpty => loadedOnce && items.isEmpty;

  PagedState<T> copyWith({
    List<T>? items,
    int? total,
    Map<String, int>? counts,
    int? nextPage,
    bool? loading,
    AppFailure? failure,
    bool clearFailure = false,
    bool? loadedOnce,
  }) => PagedState<T>(
    items: items ?? this.items,
    total: total ?? this.total,
    counts: counts ?? this.counts,
    nextPage: nextPage ?? this.nextPage,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    loadedOnce: loadedOnce ?? this.loadedOnce,
  );
}

typedef PageFetcher<T> = Future<AppResult<Paged<T>>> Function(int page, int pageSize);

/// Infinite-scroll paging over a [PageFetcher]: page size 20, one load at a time, pull-to-refresh
/// restarts from page 1. Pure state transitions, so a feature's Riverpod notifier just holds the
/// state and forwards `refresh`/`loadMore`.
class PagedLoader<T> {
  PagedLoader(this._fetch, {this.pageSize = 20});

  final PageFetcher<T> _fetch;
  final int pageSize;

  Future<PagedState<T>> refresh(PagedState<T> current, void Function(PagedState<T>) emit) =>
      _load(PagedState<T>(counts: current.counts), 1, emit, replace: true);

  Future<PagedState<T>> loadMore(PagedState<T> current, void Function(PagedState<T>) emit) async {
    if (current.loading || !current.hasMore) return current;
    return _load(current, current.nextPage, emit, replace: false);
  }

  Future<PagedState<T>> _load(
    PagedState<T> base,
    int page,
    void Function(PagedState<T>) emit, {
    required bool replace,
  }) async {
    emit(base.copyWith(loading: true, clearFailure: true));
    final result = await _fetch(page, pageSize);
    final next = switch (result) {
      Ok(:final value) => base.copyWith(
        items: replace ? value.rows : [...base.items, ...value.rows],
        total: value.total,
        counts: value.counts,
        nextPage: page + 1,
        loading: false,
        loadedOnce: true,
        clearFailure: true,
      ),
      Err(:final failure) => base.copyWith(loading: false, failure: failure),
    };
    emit(next);
    return next;
  }
}
