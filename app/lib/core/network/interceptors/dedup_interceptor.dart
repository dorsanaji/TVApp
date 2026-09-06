import 'dart:async';

import 'package:dio/dio.dart';

/// Collapses identical in-flight GET requests into one network call.
///
/// Required twice over: NM-08 ("the application must avoid sending unnecessary
/// and duplicate requests") and NFR-05 under §8.1 Performance. It matters in
/// practice too — a home screen with five carousels plus a search field that
/// rebuilds will otherwise fire the same request several times over.
///
/// Only GET is de-duplicated. Collapsing two POSTs would silently drop a user
/// action; idempotency for writes is handled separately (NFR-22).
///
/// [suppressedCount] is exposed so the debug screen can show that the
/// interceptor is really doing something — an otherwise invisible requirement
/// becomes demonstrable on camera for the submission video.
class DedupInterceptor extends Interceptor {
  DedupInterceptor();

  final Map<String, Completer<Response<dynamic>>> _inFlight = {};

  int _suppressed = 0;

  /// Number of network calls avoided since launch.
  int get suppressedCount => _suppressed;

  /// Number of requests currently awaiting a response.
  int get inFlightCount => _inFlight.length;

  void resetStats() => _suppressed = 0;

  static String keyFor(RequestOptions options) {
    final params =
        options.queryParameters.entries
            .map((e) => '${e.key}=${e.value}')
            .toList()
          ..sort();
    return '${options.method} ${options.path}?${params.join('&')}';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final key = keyFor(options);
    final existing = _inFlight[key];

    if (existing != null) {
      _suppressed++;
      // Piggy-back on the request already in flight instead of issuing a
      // second one. The waiter gets its own Response object so that
      // per-request metadata stays correct.
      existing.future.then(
        (response) => handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: response.data,
            statusCode: response.statusCode,
            statusMessage: response.statusMessage,
            headers: response.headers,
            extra: response.extra,
          ),
        ),
        onError: (Object error, StackTrace stackTrace) => handler.reject(
          error is DioException
              ? error
              : DioException(
                  requestOptions: options,
                  error: error,
                  stackTrace: stackTrace,
                ),
        ),
      );
      return;
    }

    final completer = Completer<Response<dynamic>>();
    _inFlight[key] = completer;
    // Guard against an unhandled-error crash when nothing ever piggy-backs on
    // this completer: attach a no-op listener up front.
    unawaited(completer.future.then((_) {}, onError: (Object _) {}));

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _inFlight.remove(keyFor(response.requestOptions))?.complete(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _inFlight
        .remove(keyFor(err.requestOptions))
        ?.completeError(err, err.stackTrace);
    handler.next(err);
  }
}
