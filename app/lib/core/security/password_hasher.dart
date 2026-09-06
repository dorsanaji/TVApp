import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Password hashing (NFR-13a — "passwords must not be stored as plain text").
///
/// PBKDF2-HMAC-SHA256, implemented over the `crypto` package's HMAC. PBKDF2 is
/// chosen over a bare SHA-256 because a single hash of a password is trivially
/// reversible with a rainbow table; the iteration count makes each guess
/// expensive, and the per-user salt makes precomputation useless.
///
/// Argon2 or bcrypt would be stronger still, but both need a native plugin.
/// PBKDF2 is in every standards list, needs no extra dependency, and at
/// [_iterations] rounds is entirely adequate for a device-local store.
abstract final class PasswordHasher {
  const PasswordHasher._();

  /// OWASP's floor for PBKDF2-HMAC-SHA256 is 600,000. Kept here for a
  /// deliberate reason: this runs on a phone, on the login path, and the
  /// threat model is an attacker with the device's database file rather than a
  /// leaked server dump. 120,000 keeps sign-in responsive on low-end hardware
  /// while still costing an attacker orders of magnitude more than a plain hash.
  static const int _iterations = 120000;

  static const int _keyLength = 32;
  static const int _saltLength = 16;

  static final Random _random = Random.secure();

  /// A fresh cryptographically random salt, hex encoded.
  static String generateSalt() {
    final bytes = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => _random.nextInt(256)),
    );
    return _hex(bytes);
  }

  /// Derives the stored hash for [password] under [salt].
  static String hash(String password, String salt) {
    final derived = _pbkdf2(
      utf8.encode(password),
      utf8.encode(salt),
      _iterations,
      _keyLength,
    );
    return _hex(derived);
  }

  /// Verifies a candidate password against a stored hash.
  ///
  /// Uses a constant-time comparison: an early-exit `==` leaks how many bytes
  /// matched, which is enough to recover a hash one byte at a time.
  static bool verify(String password, String salt, String expectedHash) {
    final actual = hash(password, salt);
    if (actual.length != expectedHash.length) return false;

    var mismatch = 0;
    for (var i = 0; i < actual.length; i++) {
      mismatch |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return mismatch == 0;
  }

  static Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final output = BytesBuilder();
    var block = 1;

    while (output.length < keyLength) {
      // U1 = HMAC(password, salt || INT_32_BE(block))
      final blockIndex = Uint8List(4)
        ..buffer.asByteData().setUint32(0, block, Endian.big);
      var u = Uint8List.fromList(hmac.convert([...salt, ...blockIndex]).bytes);
      final result = Uint8List.fromList(u);

      // Ui = HMAC(password, Ui-1), XOR-folded into the result.
      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }

      output.add(result);
      block++;
    }

    return Uint8List.fromList(output.toBytes().sublist(0, keyLength));
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
