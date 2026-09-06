import 'dart:typed_data';

import 'package:cinetrack/core/network/interceptors/dedup_interceptor.dart';
import 'package:cinetrack/core/network/interceptors/response_cache_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// NM-08 — "the application must avoid sending unnecessary and duplicate
/// requests" — has two halves. [DedupInterceptor] covers the concurrent one;
/// this covers the sequential one: opening a title, going back, and opening it
/// again inside the freshness window must not hit the network twice.
void main() {
  late Dio dio;
  late ResponseCacheInterceptor cache;
  late int networkCalls;

  Dio buildDio(ResponseCacheInterceptor interceptor) {
    final client = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(interceptor)
      ..httpClientAdapter = _CountingAdapter(onRequest: () => networkCalls++);
    return client;
  }

  setUp(() {
    networkCalls = 0;
    cache = ResponseCacheInterceptor();
    dio = buildDio(cache);
  });

  test('a repeated GET is served from memory', () async {
    await dio.get<dynamic>('/movie/414906');
    final second = await dio.get<dynamic>('/movie/414906');

    expect(networkCalls, 1);
    expect(cache.hitCount, 1);
    expect(second.data, isNotNull);
    expect(second.extra[ResponseCacheInterceptor.cacheHitFlag], isTrue);
  });

  test('different URLs are cached separately', () async {
    await dio.get<dynamic>('/movie/1');
    await dio.get<dynamic>('/movie/2');
    await dio.get<dynamic>('/movie/1');

    expect(networkCalls, 2);
    expect(cache.hitCount, 1);
  });

  test('query parameters are part of the identity', () async {
    await dio.get<dynamic>('/search', queryParameters: {'query': 'dune'});
    await dio.get<dynamic>('/search', queryParameters: {'query': 'alien'});

    expect(networkCalls, 2);
    expect(cache.hitCount, 0);
  });

  test('an entry past its time to live is refetched', () async {
    final expiring = ResponseCacheInterceptor(ttl: Duration.zero);
    final client = buildDio(expiring);

    await client.get<dynamic>('/movie/popular');
    await client.get<dynamic>('/movie/popular');

    expect(
      networkCalls,
      2,
      reason: 'catalogue data changes; the cache must not go stale silently',
    );
    expect(expiring.hitCount, 0);
  });

  test('writes are never served from the cache', () async {
    await dio.post<dynamic>('/rating', data: {'stars': 5});
    await dio.post<dynamic>('/rating', data: {'stars': 5});

    expect(networkCalls, 2);
    expect(cache.hitCount, 0);
  });

  test('a failed response is not cached', () async {
    final failing = ResponseCacheInterceptor();
    final client = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(failing)
      ..httpClientAdapter = _CountingAdapter(
        onRequest: () => networkCalls++,
        statusCode: 500,
      );

    await client
        .get<dynamic>('/boom')
        .then<void>((_) {})
        .catchError((Object _) {});
    await client
        .get<dynamic>('/boom')
        .then<void>((_) {})
        .catchError((Object _) {});

    expect(networkCalls, 2);
    expect(failing.entryCount, 0);
  });

  test('the store stays bounded, dropping the oldest entry first', () async {
    final small = ResponseCacheInterceptor(maxEntries: 2);
    final client = buildDio(small);

    await client.get<dynamic>('/a');
    await client.get<dynamic>('/b');
    await client.get<dynamic>('/c'); // evicts /a
    expect(small.entryCount, 2);

    networkCalls = 0;
    await client.get<dynamic>('/a'); // gone — refetched
    await client.get<dynamic>('/c'); // still held

    expect(networkCalls, 1);
    expect(small.hitCount, 1);
  });

  test('a re-served entry is not promoted past a newer one', () async {
    // Reading an entry must not extend its life; only storing it does. This
    // keeps eviction predictable — oldest *written* wins — and stops a hot key
    // from pinning the store.
    final small = ResponseCacheInterceptor(maxEntries: 2);
    final client = buildDio(small);

    await client.get<dynamic>('/a');
    await client.get<dynamic>('/b');
    await client.get<dynamic>('/a'); // a cache hit, not a re-store
    await client.get<dynamic>('/c'); // evicts /a, the oldest write

    expect(small.entryCount, 2);
    networkCalls = 0;
    await client.get<dynamic>('/a');
    expect(networkCalls, 1);
  });
}

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter({required this.onRequest, this.statusCode = 200});

  final void Function() onRequest;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest();
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
