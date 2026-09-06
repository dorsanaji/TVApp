import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'interceptors/dedup_interceptor.dart';
import 'interceptors/response_cache_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Builds the configured HTTP client for the information service.
///
/// All network work is asynchronous (NM-03) — Dio is async by construction —
/// and the de-duplication and retry interceptors are attached here rather
/// than at each call site, so no request can accidentally skip them.
abstract final class DioClient {
  const DioClient._();

  static const _connectTimeout = Duration(seconds: 10);
  static const _receiveTimeout = Duration(seconds: 15);

  /// §3.1 / NM-02 — the application is the client and talks to the
  /// information service directly.
  ///
  /// The base URL is `https://…` (NFR-14: communications over HTTPS).
  static Dio tmdb({
    DedupInterceptor? dedup,
    ResponseCacheInterceptor? responseCache,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.tmdbBaseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: {
          'Authorization': 'Bearer ${Env.tmdbReadToken}',
          'Accept': 'application/json',
        },
        // See `Env.apiLanguage` for why this is English rather than Persian.
        queryParameters: {'language': Env.apiLanguage},
      ),
    );

    // Order matters. The cache runs first so a repeat request never reaches
    // the network at all; de-duplication then collapses whatever is left into
    // one call per distinct URL; retry sits innermost, next to the socket.
    dio.interceptors.add(responseCache ?? ResponseCacheInterceptor());
    dio.interceptors.add(dedup ?? DedupInterceptor());
    dio.interceptors.add(RetryInterceptor(dio: dio));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          // Never log headers — they carry the bearer token.
          requestHeader: false,
          responseHeader: false,
          logPrint: (Object o) => debugPrint('[http] $o'),
        ),
      );
    }

    return dio;
  }
}
