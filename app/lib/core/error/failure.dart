import '../l10n/app_strings.dart';

/// A user-presentable error.
///
/// FR-20 names exactly four conditions the application must report, and NFR-09
/// requires the messages to be clear. Modelling them as a sealed hierarchy
/// means the UI can switch exhaustively — the compiler refuses to let a new
/// failure type be added without every `switch` being updated.
///
/// [message] is always Persian and always safe to show. Raw exception text,
/// status codes, and stack traces stay in [cause]/[stackTrace] and are never
/// rendered (FR-20 acceptance criteria).
///
/// Implements [Exception] because failures are thrown across the Riverpod
/// boundary — `AsyncValue.error` carries them to the UI, where `ErrorView`
/// switches on the concrete type. Nothing else in the app throws them.
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause, this.stackTrace});

  /// Persian, user-facing.
  final String message;

  /// Developer-facing only. Never shown in the UI.
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      '$runtimeType($message)${cause == null ? '' : ' <- $cause'}';
}

/// "اتصال اینترنت برقرار نیست" — the device has no usable connection.
final class NoConnectionFailure extends Failure {
  const NoConnectionFailure({super.cause, super.stackTrace})
    : super(AppStrings.errorNoConnection);
}

/// "دریافت اطلاعات با خطا مواجه شد" — the request reached the network but
/// failed: a timeout, a malformed payload, or an unexpected status.
final class FetchFailure extends Failure {
  const FetchFailure({super.cause, super.stackTrace})
    : super(AppStrings.errorFetchFailed);
}

/// "فیلم یا سریال موردنظر پیدا نشد" — the requested resource does not exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String message = AppStrings.errorNotFound,
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// "سرویس اطلاعاتی در دسترس نیست" — the upstream service is down or is
/// rejecting us (5xx, or rate limiting).
final class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure({super.cause, super.stackTrace})
    : super(AppStrings.errorServiceUnavailable);
}

/// The action needs a signed-in user (§4.1 — guests may browse, not track).
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.cause, super.stackTrace})
    : super(AppStrings.errorUnauthorized);
}

/// A validation or domain rule was violated. Carries its own message because
/// the text is specific to the rule (e.g. "این نام کاربری قبلاً ثبت شده است").
final class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.field,
    super.cause,
    super.stackTrace,
  });

  /// The offending form field, when the failure maps to one.
  final String? field;
}

/// Local database or file-system failure.
final class StorageFailure extends Failure {
  const StorageFailure({super.cause, super.stackTrace})
    : super(AppStrings.errorFetchFailed);
}
