/// Invitation codes for private shared lists.
///
/// A private list is invisible — it is absent from both owners' public
/// profiles and from any browse screen — so there has to be some way to hand
/// someone a way in. The code *is* the list id, encoded: the numeric tail of
/// `list_<micros>` in base 36, plus a check character.
///
/// Encoding the id rather than storing a separate secret is what lets this
/// work against the existing schema. `custom_lists` has no column to keep an
/// invite token in, and the app talks to Postgres through PostgREST, which
/// cannot add one. A reversible code needs no storage at all: entering it
/// yields the list id directly, with no lookup table and no scan.
///
/// The check character catches typos, and makes a randomly-typed string
/// overwhelmingly likely to be rejected rather than resolving to somebody
/// else's list. It is **not** a secret: anyone who has the code can join, and
/// a code cannot be revoked without deleting the list. That is the same
/// bargain as any "anyone with the link" share, and it is worth stating
/// plainly rather than implying the code is a password.
abstract final class ListInviteCode {
  const ListInviteCode._();

  static const _prefix = 'list_';
  static const _alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// The code for [listId], or null when the id is not one this app minted.
  static String? forList(String listId) {
    final digits = _digitsOf(listId);
    if (digits == null) return null;

    final body = _toBase36(digits);
    return _group('$body${_checkChar(body)}');
  }

  /// The list id [code] refers to, or null when it is malformed.
  static String? toListId(String code) {
    final cleaned = code
        .toUpperCase()
        .replaceAll(RegExp('[^0-9A-Z]'), '');
    if (cleaned.length < 2) return null;

    final body = cleaned.substring(0, cleaned.length - 1);
    final check = cleaned.substring(cleaned.length - 1);
    if (_checkChar(body) != check) return null;

    final digits = _fromBase36(body);
    if (digits == null) return null;

    return '$_prefix$digits';
  }

  /// Whether [code] is well-formed. Says nothing about the list existing.
  static bool isValid(String code) => toListId(code) != null;

  static BigInt? _digitsOf(String listId) {
    if (!listId.startsWith(_prefix)) return null;
    return BigInt.tryParse(listId.substring(_prefix.length));
  }

  static String _toBase36(BigInt value) {
    if (value == BigInt.zero) return '0';
    final radix = BigInt.from(36);
    final buffer = StringBuffer();
    var remaining = value;
    while (remaining > BigInt.zero) {
      buffer.write(_alphabet[(remaining % radix).toInt()]);
      remaining = remaining ~/ radix;
    }
    return buffer.toString().split('').reversed.join();
  }

  static BigInt? _fromBase36(String body) {
    if (body.isEmpty) return null;
    final radix = BigInt.from(36);
    var value = BigInt.zero;
    for (final char in body.split('')) {
      final digit = _alphabet.indexOf(char);
      if (digit < 0) return null;
      value = value * radix + BigInt.from(digit);
    }
    return value;
  }

  /// A weighted checksum over [body], rendered in the same alphabet.
  static String _checkChar(String body) {
    var sum = 0;
    for (var i = 0; i < body.length; i++) {
      sum += (_alphabet.indexOf(body[i]) + 1) * (i + 1);
    }
    return _alphabet[sum % _alphabet.length];
  }

  /// Groups of four, which is what makes a code readable out loud.
  static String _group(String raw) {
    final parts = <String>[];
    for (var i = 0; i < raw.length; i += 4) {
      parts.add(raw.substring(i, (i + 4).clamp(0, raw.length)));
    }
    return parts.join('-');
  }
}
