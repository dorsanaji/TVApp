import 'dart:io';

import 'package:dio/dio.dart';

import 'failure.dart';

/// Translates low-level exceptions into the four user-facing conditions of
/// FR-20. This is the single place where a raw exception is allowed to be
/// inspected; everything above this line deals only in [Failure].
abstract final class ErrorMapper {
  const ErrorMapper._();

  static Failure fromDio(DioException e) {
    final stack = e.stackTrace;

    return switch (e.type) {
      DioExceptionType.connectionError => NoConnectionFailure(
        cause: e,
        stackTrace: stack,
      ),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => FetchFailure(
        cause: e,
        stackTrace: stack,
      ),
      DioExceptionType.badCertificate => ServiceUnavailableFailure(
        cause: e,
        stackTrace: stack,
      ),
      DioExceptionType.badResponse => _fromStatus(e, stack),
      DioExceptionType.cancel => FetchFailure(cause: e, stackTrace: stack),
      DioExceptionType.unknown =>
        e.error is SocketException
            ? NoConnectionFailure(cause: e, stackTrace: stack)
            : FetchFailure(cause: e, stackTrace: stack),
    };
  }

  static Failure _fromStatus(DioException e, StackTrace? stack) {
    final status = e.response?.statusCode ?? 0;
    return switch (status) {
      401 || 403 => UnauthorizedFailure(cause: e, stackTrace: stack),
      404 => NotFoundFailure(cause: e, stackTrace: stack),
      // 429 is rate limiting: from the user's point of view the information
      // service is unavailable right now, which is the message they need.
      429 => ServiceUnavailableFailure(cause: e, stackTrace: stack),
      >= 500 && < 600 => ServiceUnavailableFailure(cause: e, stackTrace: stack),
      _ => FetchFailure(cause: e, stackTrace: stack),
    };
  }

  /// Fallback for anything that is not a [DioException] — JSON parsing,
  /// unexpected nulls, and so on.
  static Failure fromUnknown(Object error, [StackTrace? stackTrace]) {
    if (error is DioException) return fromDio(error);
    if (error is SocketException) {
      return NoConnectionFailure(cause: error, stackTrace: stackTrace);
    }
    if (error is Failure) return error;
    return FetchFailure(cause: error, stackTrace: stackTrace);
  }
}
