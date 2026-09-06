/// Persian digit formatting (NFR-11a).
///
/// The brief requires a Persian interface, and a Persian interface that shows
/// "50%" next to Persian text reads as half-translated. Every number the user
/// sees — percentages, ratings, counts, years, durations — goes through here.
extension PersianDigits on String {
  static const _western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  static const _persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  /// `"2024"` → `"۲۰۲۴"`
  String get toPersianDigits {
    var out = this;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(_western[i], _persian[i]);
    }
    return out;
  }

  /// `"۲۰۲۴"` → `"2024"`. Needed before parsing user input.
  String get toWesternDigits {
    var out = this;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(_persian[i], _western[i]);
    }
    return out;
  }
}

extension PersianNumberFormat on num {
  /// Persian digits with thousands separators: `12345` → `"۱۲٬۳۴۵"`.
  String get toPersian {
    final digits = toString().toPersianDigits;
    if (this is! int && truncateToDouble() != this) return digits;
    return _groupThousands(digits);
  }

  /// `0.5` → `"۵۰٪"`. Used by FR-11 and FR-13.
  String toPersianPercent({int fractionDigits = 0}) =>
      '${(this * 100).toStringAsFixed(fractionDigits).toPersianDigits}٪';

  static String _groupThousands(String persianDigits) {
    final negative = persianDigits.startsWith('-');
    final body = negative ? persianDigits.substring(1) : persianDigits;
    final buffer = StringBuffer();

    for (var i = 0; i < body.length; i++) {
      if (i > 0 && (body.length - i) % 3 == 0) buffer.write('٬');
      buffer.write(body[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }
}
