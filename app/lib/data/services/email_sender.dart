import 'package:flutter/foundation.dart';

/// Dispatches the FR-03 password-recovery code.
///
/// **The honest position, which belongs in the submission notes.** FR-03 says
/// the user must be able to recover their password *via email*. An Android app
/// with no server cannot send email on its own: doing so needs either SMTP
/// credentials shipped inside the APK — which would violate NFR-15, since
/// anyone can extract them — or a server to send on its behalf, which the
/// normal model does not have (§3.3).
///
/// So the flow is built properly and the transport is left pluggable:
///
///  * the reset code is generated, hashed, time-limited to 15 minutes, and
///    single-use;
///  * the verification and password-change steps are fully implemented;
///  * only the delivery step depends on a credential that is not present.
///
/// Supplying a real [EmailSender] — a transactional-email provider's HTTP API,
/// for instance — completes it without touching the repository. That is the
/// same seam NFR-33 asks for, applied to a second external service.
abstract interface class EmailSender {
  Future<void> sendPasswordResetCode({
    required String email,
    required String code,
  });
}

/// Development transport: surfaces the code locally instead of sending it.
///
/// Not a stub that silently does nothing — [lastCode] is what the recovery
/// screen reads to show the code on screen, so the whole FR-03 flow is
/// demonstrable end to end without a mail credential. Clearly labelled in the
/// UI as a development aid so it cannot be mistaken for delivered mail.
class DebugEmailSender implements EmailSender {
  String? _lastCode;
  String? _lastEmail;

  /// The most recently issued code, or `null` if none has been requested.
  String? get lastCode => _lastCode;

  String? get lastEmail => _lastEmail;

  @override
  Future<void> sendPasswordResetCode({
    required String email,
    required String code,
  }) async {
    _lastCode = code;
    _lastEmail = email;
    debugPrint('[FR-03] password reset code for $email: $code');
  }
}
