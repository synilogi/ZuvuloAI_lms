import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/errors/result.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/paging.dart';

Map<String, dynamic> _page(int page, int pageSize, int total) => {
  'rows': [
    for (var i = (page - 1) * pageSize; i < total && i < page * pageSize; i++) {'id': 'row_$i'},
  ],
  'total': total,
  'counts': {'all': total, 'overdue': 3},
};

void main() {
  group('Paged.fromJson', () {
    test('reads rows, total and counts', () {
      final paged = Paged<String>.fromJson(
        '/staff/students',
        _page(1, 2, 5),
        (row) => row['id']! as String,
      );
      expect(paged.rows, ['row_0', 'row_1']);
      expect(paged.total, 5);
      expect(paged.counts, {'all': 5, 'overdue': 3});
    });

    test('a list without counts is fine; a wrong shape is a contract failure', () {
      expect(
        Paged<String>.fromJson('/x', {'rows': <Object?>[], 'total': 0}, (r) => '').counts,
        isEmpty,
      );
      expect(
        () => Paged<String>.fromJson('/x', {'rows': 'nope', 'total': 0}, (r) => ''),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ContractFailure>())),
      );
    });
  });

  group('PagedLoader', () {
    late List<PagedState<String>> emitted;

    PagedLoader<String> loader(
      Future<AppResult<Paged<String>>> Function(int page, int pageSize) fetch,
    ) => PagedLoader<String>(fetch, pageSize: 2);

    setUp(() => emitted = []);

    Future<AppResult<Paged<String>>> ok(int page, int pageSize) async =>
        Ok(Paged<String>.fromJson('/x', _page(page, pageSize, 5), (r) => r['id']! as String));

    test('refresh loads the first page and reports loading first', () async {
      final state = await loader(ok).refresh(const PagedState<String>(), emitted.add);

      expect(emitted.first.loading, isTrue);
      expect(state.items, ['row_0', 'row_1']);
      expect(state.total, 5);
      expect(state.counts['all'], 5);
      expect(state.hasMore, isTrue);
      expect(state.isEmpty, isFalse);
    });

    test('loadMore appends until the total is reached', () async {
      final l = loader(ok);
      var state = await l.refresh(const PagedState<String>(), emitted.add);
      state = await l.loadMore(state, emitted.add);
      expect(state.items, ['row_0', 'row_1', 'row_2', 'row_3']);
      state = await l.loadMore(state, emitted.add);
      expect(state.items, hasLength(5));
      expect(state.hasMore, isFalse);

      final requests = <int>[];
      final counting = loader((page, size) {
        requests.add(page);
        return ok(page, size);
      });
      await counting.loadMore(state, emitted.add);
      expect(requests, isEmpty, reason: 'nothing left to load');
    });

    test('an empty first page reads as empty, not as more to load', () async {
      final state = await loader(
        (page, size) async =>
            Ok(Paged<String>.fromJson('/x', {'rows': <Object?>[], 'total': 0}, (r) => '')),
      ).refresh(const PagedState<String>(), emitted.add);

      expect(state.isEmpty, isTrue);
      expect(state.hasMore, isFalse);
    });

    test('a failure keeps the items already loaded', () async {
      var failNext = false;
      final l = loader((page, size) async {
        if (failNext) return const Err(NetworkFailure(NetworkProblem.offline));
        return ok(page, size);
      });
      var state = await l.refresh(const PagedState<String>(), emitted.add);
      failNext = true;
      state = await l.loadMore(state, emitted.add);

      expect(state.items, ['row_0', 'row_1']);
      expect(state.failure, isA<NetworkFailure>());
      expect(state.loading, isFalse);
    });

    test('a second load is ignored while one is running', () async {
      var calls = 0;
      final l = loader((page, size) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return ok(page, size);
      });
      final state = await l.refresh(const PagedState<String>(), emitted.add);
      final busy = state.copyWith(loading: true);

      await l.loadMore(busy, emitted.add);
      expect(calls, 1);
    });
  });
}
