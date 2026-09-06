import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/env.dart';
import 'email_sender.dart';

/// FR-03 delivery via **EmailJS**.
///
/// EmailJS relays through an email account you own, so the recovery code
/// genuinely arrives in the user's inbox — which is what §5.3 asks for.
///
/// **On NFR-15.** EmailJS's public key is designed to be public: it is meant to
/// sit in browser JavaScript where anyone can read it. What protects the
/// account is the allow-list of origins and templates configured server-side,
/// not secrecy of the key. So shipping it in the app is not the same class of
/// exposure as shipping, say, an SMTP password — the worst an extracted key
/// permits is sending your own pre-defined template.
///
/// It is still passed by `--dart-define-from-file` rather than committed, so
/// the repository stays clean and the value is easy to rotate.
///
/// **Configuration** — add to `dart_defines.json`:
/// ```json
/// "EMAILJS_SERVICE_ID":  "service_xxxxxxx",
/// "EMAILJS_TEMPLATE_ID": "template_xxxxxxx",
/// "EMAILJS_PUBLIC_KEY":  "xxxxxxxxxxxxxxxx",
/// "EMAILJS_PRIVATE_KEY": "xxxxxxxxxxxxxxxx"
/// ```
///
/// **Two things are required, not one.** EmailJS rejects every non-browser
/// request with `403 API access from non-browser environments is currently
/// disabled` until "Allow EmailJS API for non-browser applications" is ticked
/// under Account → Security in the dashboard. That switch opens the door; the
/// private key sent as `accessToken` is what then authenticates the caller, so
/// opening it does not leave the endpoint callable by anyone holding the
/// public key. A native app needs both, and the setting is server-side — no
/// rebuild makes any difference to it.
///
/// The EmailJS template must reference these variables:
///   `{{to_email}}` — recipient, `{{code}}` — the six-digit code,
///   `{{app_name}}` — for the subject line.
class EmailJsSender implements EmailSender {
  EmailJsSender({Dio? client}) : _dio = client ?? Dio();

  final Dio _dio;

  static const _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  /// True when every required value is present. Checked before use so a
  /// half-configured build falls back rather than failing at send time.
  static bool get isConfigured =>
      Env.emailJsServiceId.isNotEmpty &&
      Env.emailJsTemplateId.isNotEmpty &&
      Env.emailJsPublicKey.isNotEmpty;

  @override
  Future<void> sendPasswordResetCode({
    required String email,
    required String code,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'EmailJS is not configured. Add EMAILJS_SERVICE_ID, '
        'EMAILJS_TEMPLATE_ID and EMAILJS_PUBLIC_KEY to dart_defines.json.',
      );
    }

    final response = await _dio.post<dynamic>(
      _endpoint,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        // EmailJS answers 4xx with a plain-text reason. Accepting those
        // statuses here is what lets that reason be read below — Dio would
        // otherwise raise a DioException carrying only the status code.
        validateStatus: (status) => status != null && status < 500,
      ),
      data: {
        'service_id': Env.emailJsServiceId,
        'template_id': Env.emailJsTemplateId,
        'user_id': Env.emailJsPublicKey,
        if (Env.emailJsPrivateKey.isNotEmpty)
          'accessToken': Env.emailJsPrivateKey,
        'template_params': {
          'to_email': email,
          'code': code,
          // Latin, because the recovery email itself is written in English —
          // an English sentence with a Persian name spliced into it reads as
          // a mistake. The in-app strings stay Persian.
          'app_name': 'MyTV',
        },
      },
    );

    // Accepting 4xx above means nothing else will complain about one, so the
    // check has to happen here. Without it every refusal — a wrong template
    // id, a disabled key, an empty recipient — counted as a successful send,
    // and the screen told the user to check an inbox nothing had been sent to.
    if (response.statusCode != 200) {
      throw StateError(
        'EmailJS refused the request: ${response.statusCode} — ${response.data}',
      );
    }
  }
}

/// Uses EmailJS when it is configured and the development sender otherwise.
///
/// Keeps the app runnable by anyone who clones the repository without
/// credentials — they still see the whole FR-03 flow, with the code shown on
/// screen and labelled as a development aid.
class EmailSenderWithFallback implements EmailSender {
  EmailSenderWithFallback({required this.primary, required this.fallback});

  final EmailSender primary;
  final DebugEmailSender fallback;

  @override
  Future<void> sendPasswordResetCode({
    required String email,
    required String code,
  }) async {
    // The fallback always records the code, so the recovery screen can show it
    // if delivery failed and the user would otherwise be stuck.
    await fallback.sendPasswordResetCode(email: email, code: code);

    if (!EmailJsSender.isConfigured) return;

    try {
      await primary.sendPasswordResetCode(email: email, code: code);
      _delivered = true;
    } catch (e) {
      _delivered = false;
      debugPrint('[FR-03] EmailJS delivery failed, code shown on screen: $e');
    }
  }

  bool _delivered = false;

  /// Whether the last code actually left via email. The recovery screen uses
  /// this to decide between "check your inbox" and showing the code.
  bool get lastDeliverySucceeded => _delivered;
}
