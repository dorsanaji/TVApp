import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Certificate pinning support (NFR-14).
///
/// The brief's wording is: *"network communications must be conducted over
/// HTTPS. For this purpose provision a CA Certificate for your own server and
/// pin it on the application side."*
///
/// In the normal model there is no project-owned server — the application
/// talks to the information service directly (§3.1) — so the "own server"
/// half of the clause has no subject. What the normal model *can* and does
/// satisfy is the HTTPS half: every base URL in [Env] is `https://`, and
/// Android's network security configuration blocks cleartext traffic outright,
/// so a downgrade cannot happen even by mistake.
///
/// This helper is kept, tested, and wired so the capability is demonstrable:
/// adding a fingerprint to [allowedSha256] activates pinning immediately. It
/// is intentionally inert while the set is empty — normal CA validation then
/// applies, so the app is never *less* safe than the platform default.
///
/// See `docs/SECURITY.md` for the full argument.
abstract final class CertificatePinning {
  const CertificatePinning._();

  /// SHA-256 fingerprints of accepted certificates, lowercase hex, no
  /// separators. Obtain one with:
  ///
  /// ```
  /// openssl s_client -connect <host>:443 </dev/null 2>/dev/null \
  ///   | openssl x509 -outform DER \
  ///   | shasum -a 256
  /// ```
  ///
  /// Pinning a third-party host is a liability rather than a safeguard: the
  /// certificate rotates on its owner's schedule and every installed copy of
  /// the app breaks when it does. That is why this set is empty by default.
  static const Set<String> allowedSha256 = <String>{};

  static bool get isEnabled => allowedSha256.isNotEmpty;

  /// Applies pinning to [dio]. A no-op while [allowedSha256] is empty.
  static void apply(Dio dio) {
    if (!isEnabled) return;

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(
          context: SecurityContext(withTrustedRoots: true),
        );
        client.badCertificateCallback = (cert, host, port) => matches(cert);
        return client;
      },
      validateCertificate: (cert, host, port) => cert != null && matches(cert),
    );
  }

  @visibleForTesting
  static bool matches(X509Certificate cert) {
    final fingerprint = sha256.convert(cert.der).toString().toLowerCase();
    return allowedSha256.contains(fingerprint);
  }
}
