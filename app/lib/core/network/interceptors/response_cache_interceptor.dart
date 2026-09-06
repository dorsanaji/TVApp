import 'package:dio/dio.dart';

import 'dedup_interceptor.dart';

/// Serves a recent GET response from memory instead of asking again.
///
/// NM-08 asks the application to avoid unnecessary and repeated requests.
/// [DedupInterceptor] covers the *simultaneous* half of that — five carousels
/// asking for the same list at once become one call. This covers the
/// *sequential* half: opening a film, going back, and opening it again should
/// not re-fetch a detail that has not had time to change.
///
/// Deliberately small and short-lived. Catalogue data does change, so the
/// window is minutes rather than hours, and the entry count is bounded so a
/// long browsing session cannot grow the process without limit. Anything that
/// must survive a restart belongs in the database (NM-07), not here.
class ResponseCacheInterceptor extends Interceptor {
  ResponseCacheInterceptor({
    this.ttl = const Duration(minutes: 5),
    this.maxEntries = 128,
  });

  /// How long a cached response stays usable.
  final Duration ttl;

  /// Upper bound on retained responses; the oldest is dropped past it.
  final int maxEntries;

  /// Insertion-ordered, which is what makes the eviction below oldest-first.
  final Map<String, _Entry> _entries = {};

  int _hits = 0;

  /// Network calls avoided since launch — the counterpart to
  /// [DedupInterceptor.suppressedCount], and shown on the debug screen so the
  /// requirement is demonstrable rather than merely claimed.
  int get hitCount => _hits;

  int get entryCount => _entries.length;

  void clear() {
    _entries.clear();
    _hits = 0;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final key = DedupInterceptor.keyFor(options);
    final entry = _entries[key];

    if (entry != null) {
      if (DateTime.now().difference(entry.storedAt) < ttl) {
        _hits++;
        return handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: entry.data,
            statusCode: 200,
            // Marked so a caller — or a reviewer reading the logs — can tell a
            // served-from-memory response from a fresh one.
            extra: const {cacheHitFlag: true},
          ),
        );
      }
      _entries.remove(key);
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final isCacheable =
        options.method.toUpperCase() == 'GET' &&
        response.statusCode == 200 &&
        response.data != null &&
        response.extra[cacheHitFlag] != true;

    if (isCacheable) {
      final key = DedupInterceptor.keyFor(options);
      // Re-inserting must move the entry to the end, or a page refreshed every
      // few minutes would keep its original position and be evicted while
      // still in use.
      _entries
        ..remove(key)
        ..[key] = _Entry(response.data, DateTime.now());

      while (_entries.length > maxEntries) {
        _entries.remove(_entries.keys.first);
      }
    }

    handler.next(response);
  }

  /// Key under which a cache hit is flagged in `Response.extra`.
  static const cacheHitFlag = 'cinetrack.cacheHit';
}

class _Entry {
  const _Entry(this.data, this.storedAt);

  final dynamic data;
  final DateTime storedAt;
}
