import 'package:shamsi_date/shamsi_date.dart';

import '../l10n/persian_numbers.dart';

/// Presentation formatting helpers.
///
/// Runtime and date formatting appear on nearly every screen (FR-06 runtime,
/// FR-08 air date and runtime, FR-19 total watch time), so they live in one
/// place and are unit-tested rather than being re-derived per widget.
abstract final class Formatters {
  const Formatters._();

  /// `137` → `"۲ ساعت و ۱۷ دقیقه"`. Used for film runtime (FR-06).
  static String runtime(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) return '${mins.toPersian} دقیقه';
    if (mins == 0) return '${hours.toPersian} ساعت';
    return '${hours.toPersian} ساعت و ${mins.toPersian} دقیقه';
  }

  /// Total watch time for FR-19 statistic 4. Large totals read better in days.
  static String totalWatchTime(int totalMinutes) {
    if (totalMinutes <= 0) return '۰ دقیقه';

    final days = totalMinutes ~/ (60 * 24);
    final hours = (totalMinutes % (60 * 24)) ~/ 60;
    final mins = totalMinutes % 60;

    final parts = <String>[
      if (days > 0) '${days.toPersian} روز',
      if (hours > 0) '${hours.toPersian} ساعت',
      if (days == 0 && mins > 0) '${mins.toPersian} دقیقه',
    ];

    return parts.isEmpty ? '۰ دقیقه' : parts.join(' و ');
  }

  /// Gregorian ISO date → Jalali, e.g. `"2008-01-20"` → `"۳۰ دی ۱۳۸۶"`.
  /// Persian readers expect Jalali dates; falls back to the raw value if the
  /// upstream string is not parseable.
  static String jalaliDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';

    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;

    final jalali = Jalali.fromDateTime(parsed);
    // A year is an identifier, not a quantity: `۱۳۸۶`, never `۱٬۳۸۶`. Hence
    // plain digit conversion here rather than `toPersian`, which groups
    // thousands.
    final year = jalali.year.toString().toPersianDigits;
    return '${jalali.day.toPersian} ${_months[jalali.month - 1]} $year';
  }

  /// Just the Gregorian year, in Persian digits — used where the brief asks
  /// for "release year" as a bare number (FR-06, FR-07).
  static String year(String? isoDate) {
    if (isoDate == null || isoDate.length < 4) return '—';
    return isoDate.substring(0, 4).toPersianDigits;
  }

  /// TMDB `vote_average` (0–10) → `"۸٫۵"`.
  static String rating(double? value) {
    if (value == null || value <= 0) return '—';
    return value.toStringAsFixed(1).replaceAll('.', '٫').toPersianDigits;
  }

  /// Formats a DateTime directly into a full Jalali string, e.g. "۱۵ شهریور ۱۴۰۵".
  static String formatJalaliDate(DateTime? date) {
    if (date == null) return '—';
    final jalali = Jalali.fromDateTime(date);
    final year = jalali.year.toString().toPersianDigits;
    return '${jalali.day.toPersian} ${_months[jalali.month - 1]} $year';
  }

  /// Relative elapsed time in Persian, e.g. "همین الان", "۲ ساعت پیش", "۳ روز پیش".
  static String relativeTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'همین الان';
    if (diff.inMinutes < 60) return '${diff.inMinutes.toPersian} دقیقه پیش';
    if (diff.inHours < 24) return '${diff.inHours.toPersian} ساعت پیش';
    if (diff.inDays < 30) return '${diff.inDays.toPersian} روز پیش';
    if (diff.inDays < 365) return '${(diff.inDays ~/ 30).toPersian} ماه پیش';
    return '${(diff.inDays ~/ 365).toPersian} سال پیش';
  }

  static const _months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];
}
