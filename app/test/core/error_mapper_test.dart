import 'dart:io';

import 'package:cinetrack/core/error/error_mapper.dart';
import 'package:cinetrack/core/error/failure.dart';
import 'package:cinetrack/core/l10n/app_strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-20 §5.20 — the four conditions the brief names must each reach the user
/// as their own message, and no raw exception text may ever be shown.
void main() {
  final options = RequestOptions(path: '/movie/1');

  DioException dio(DioExceptionType type, {int? status}) => DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: status),
  );

  group('FR-20 · the four named conditions', () {
    test('اتصال اینترنت برقرار نیست — no connection', () {
      final failure = ErrorMapper.fromDio(
        dio(DioExceptionType.connectionError),
      );

      expect(failure, isA<NoConnectionFailure>());
      expect(failure.message, AppStrings.errorNoConnection);
    });

    test('دریافت اطلاعات با خطا مواجه شد — timeout', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(ErrorMapper.fromDio(dio(type)), isA<FetchFailure>());
      }
    });

    test('فیلم یا سریال موردنظر پیدا نشد — 404', () {
      final failure = ErrorMapper.fromDio(
        dio(DioExceptionType.badResponse, status: 404),
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, AppStrings.errorNotFound);
    });

    test('سرویس اطلاعاتی در دسترس نیست — 5xx', () {
      for (final status in [500, 502, 503]) {
        expect(
          ErrorMapper.fromDio(
            dio(DioExceptionType.badResponse, status: status),
          ),
          isA<ServiceUnavailableFailure>(),
        );
      }
    });
  });

  group('other statuses', () {
    test('rate limiting reads as service unavailable to the user', () {
      // A 429 is not the user's fault and not actionable by them; "the service
      // is not available right now" is the message that actually helps.
      expect(
        ErrorMapper.fromDio(dio(DioExceptionType.badResponse, status: 429)),
        isA<ServiceUnavailableFailure>(),
      );
    });

    test('401 and 403 ask the user to sign in', () {
      expect(
        ErrorMapper.fromDio(dio(DioExceptionType.badResponse, status: 401)),
        isA<UnauthorizedFailure>(),
      );
      expect(
        ErrorMapper.fromDio(dio(DioExceptionType.badResponse, status: 403)),
        isA<UnauthorizedFailure>(),
      );
    });

    test(
      'an unknown error wrapping a socket failure is a connection problem',
      () {
        final failure = ErrorMapper.fromDio(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: const SocketException('no route to host'),
          ),
        );

        expect(failure, isA<NoConnectionFailure>());
      },
    );
  });

  group('non-Dio errors', () {
    test('a parsing error becomes a fetch failure', () {
      expect(
        ErrorMapper.fromUnknown(const FormatException('bad json')),
        isA<FetchFailure>(),
      );
    });

    test('an existing Failure passes through unchanged', () {
      const original = NotFoundFailure();

      expect(ErrorMapper.fromUnknown(original), same(original));
    });
  });

  test('no failure message leaks internal detail to the user', () {
    final failures = <Failure>[
      ErrorMapper.fromDio(dio(DioExceptionType.connectionError)),
      ErrorMapper.fromDio(dio(DioExceptionType.badResponse, status: 500)),
      ErrorMapper.fromUnknown(Exception('DioException [bad response]: 500')),
    ];

    for (final failure in failures) {
      expect(failure.message, isNot(contains('DioException')));
      expect(failure.message, isNot(contains('Exception')));
      expect(failure.message, isNot(contains('500')));
      // …but the detail is still available for logging.
      expect(failure.cause, isNotNull);
    }
  });
}
