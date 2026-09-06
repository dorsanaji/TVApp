import 'dart:async';

import 'package:dio/dio.dart';

/// Retries transient failures with exponential backoff.
///
/// Supports NFR-20 ("user activity information must not be lost due to
/// ordinary errors") and NFR-23. Deliberately conservative:
///
///  * only idempotent methods (GET/HEAD) are retried, so a retry can never
///    duplicate a rating, review, or watch-status write (NFR-22);
///  * 4xx responses are never retried — they will not succeed on a second
///    attempt and retrying wastes the user's data allowance (NFR-40).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio dio;
  final int maxAttempts;
  final Duration baseDelay;

  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxAttempts - 1) {
      return handler.next(err);
    }

    // 400ms, 800ms, 1600ms …
    await Future<void>.delayed(baseDelay * (1 << attempt));

    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;

    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return false;

    return switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.badResponse => (err.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }
}
