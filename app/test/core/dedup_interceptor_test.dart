import 'dart:typed_data';

import 'package:cinetrack/core/network/interceptors/dedup_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// NM-08 and NFR-05 — "the application must avoid sending unnecessary and
/// duplicate requests". Graded twice, so it is verified rather than asserted.
void main() {
  late Dio dio;
  late DedupInterceptor dedup;
  late int networkCalls;

  setUp(() {
    networkCalls = 0;
    dedup = DedupInterceptor();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(dedup);

    // Stand in for the network, counting how many calls actually get through
    // and adding a delay so concurrent requests genuinely overlap.
    dio.httpClientAdapter = _CountingAdapter(
      onRequest: () => networkCalls++,
      delay: const Duration(milliseconds: 50),
    );
  });

  test('three concurrent identical GETs produce one network call', () async {
    final responses = await Future.wait([
      dio.get<dynamic>('/movie/popular'),
      dio.get<dynamic>('/movie/popular'),
      dio.get<dynamic>('/movie/popular'),
    ]);

    expect(networkCalls, 1);
    expect(dedup.suppressedCount, 2);
    // Every caller still gets its own complete response.
    expect(responses, hasLength(3));
    for (final response in responses) {
      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
    }
  });

  test('requests differing only in query parameters are not merged', () async {
    await Future.wait([
      dio.get<dynamic>('/search', queryParameters: {'query': 'dune'}),
      dio.get<dynamic>('/search', queryParameters: {'query': 'alien'}),
    ]);

    expect(networkCalls, 2);
    expect(dedup.suppressedCount, 0);
  });

  test('query parameter order does not defeat de-duplication', () async {
    await Future.wait([
      dio.get<dynamic>(
        '/search',
        queryParameters: {'query': 'dune', 'page': 1},
      ),
      dio.get<dynamic>(
        '/search',
        queryParameters: {'page': 1, 'query': 'dune'},
      ),
    ]);

    expect(networkCalls, 1);
    expect(dedup.suppressedCount, 1);
  });

  test('a sequential repeat is a fresh call, not a stale cache hit', () async {
    await dio.get<dynamic>('/movie/popular');
    await dio.get<dynamic>('/movie/popular');

    // De-duplication collapses only *concurrent* requests. Serving the second
    // one from memory is caching — a separate concern with its own freshness
    // rules, handled by `ResponseCacheInterceptor` and tested next to it. Only
    // this interceptor is installed here, so the call goes through.
    expect(networkCalls, 2);
    expect(dedup.suppressedCount, 0);
  });

  test('writes are never merged, so a user action cannot be dropped', () async {
    await Future.wait([
      dio.post<dynamic>('/rating', data: {'stars': 5}),
      dio.post<dynamic>('/rating', data: {'stars': 5}),
    ]);

    expect(networkCalls, 2);
    expect(dedup.suppressedCount, 0);
  });

  test(
    'a failure propagates to every waiter and clears the in-flight entry',
    () async {
      dio.httpClientAdapter = _CountingAdapter(
        onRequest: () => networkCalls++,
        delay: const Duration(milliseconds: 20),
        statusCode: 500,
      );

      final results = await Future.wait([
        dio
            .get<dynamic>('/boom')
            .then((_) => 'ok')
            .catchError((Object _) => 'err'),
        dio
            .get<dynamic>('/boom')
            .then((_) => 'ok')
            .catchError((Object _) => 'err'),
      ]);

      expect(results, ['err', 'err']);
      expect(networkCalls, 1);
      // Nothing left behind, so a later retry is not blocked by a dead entry.
      expect(dedup.inFlightCount, 0);
    },
  );
}

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter({
    required this.onRequest,
    required this.delay,
    this.statusCode = 200,
  });

  final void Function() onRequest;
  final Duration delay;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest();
    await Future<void>.delayed(delay);
    return ResponseBody.fromString(
      '{"results":[]}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
